#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { 
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool
} from '@modelcontextprotocol/sdk/types.js';
import fs from 'fs/promises';
import path from 'path';
import os from 'os';

// Agent role definitions based on token economics
enum AgentTier {
  LAYER_0 = 'layer_0',  // Haiku: $0.0001 - Information retrieval
  LAYER_2 = 'layer_2',  // Sonnet: $0.003 - Analysis and implementation  
  LAYER_5 = 'layer_5',  // Opus: $0.015 - Architectural decisions
}

interface AgentCapabilities {
  mcp_servers: string[];
  tools: string[];
  max_token_budget: number;
  timeout_minutes: number | null;
  cost_per_token: number;
  special_permissions: string[];
}

const ROLE_DEFINITIONS: Record<AgentTier, AgentCapabilities> = {
  [AgentTier.LAYER_0]: {
    mcp_servers: ['filesystem', 'web-search', 'project-knowledge'],
    tools: ['read', 'grep', 'web-fetch'],
    max_token_budget: 5000,
    timeout_minutes: 30,
    cost_per_token: 0.0001,
    special_permissions: []
  },
  [AgentTier.LAYER_2]: {
    mcp_servers: ['filesystem', 'git', 'project-knowledge', 'github'],
    tools: ['read', 'write', 'edit', 'bash', 'multi-edit'],
    max_token_budget: 20000,
    timeout_minutes: 60,
    cost_per_token: 0.003,
    special_permissions: ['code-generation', 'testing']
  },
  [AgentTier.LAYER_5]: {
    mcp_servers: ['*'],
    tools: ['*'],
    max_token_budget: 50000,
    timeout_minutes: 15, // Power corrupts quickly
    cost_per_token: 0.015,
    special_permissions: ['architecture', 'system-design', 'task-delegation']
  }
};

// Auto-promotion patterns
const AUTO_PROMOTION_PATTERNS: Record<string, { tier: AgentTier; duration: number }> = {
  'implement|build|create|write code': { tier: AgentTier.LAYER_2, duration: 60 },
  'design|architect|plan system': { tier: AgentTier.LAYER_5, duration: 120 },
  'find|search|docs|documentation': { tier: AgentTier.LAYER_0, duration: 30 },
  'debug|fix|troubleshoot': { tier: AgentTier.LAYER_2, duration: 45 },
  'review|analyze|evaluate': { tier: AgentTier.LAYER_2, duration: 30 }
};

interface ThreadState {
  current_tier: AgentTier;
  assigned_at: number;
  expires_at: number;
  reason: string;
  token_usage: number;
  operations_count: number;
}

class AgentRoleServer {
  private stateFile: string;
  private auditDir: string;

  constructor() {
    const homeDir = os.homedir();
    this.stateFile = path.join(homeDir, '.claude', 'roles-state.json');
    this.auditDir = path.join(homeDir, '.claude', 'audit');
  }

  async ensureDirectories(): Promise<void> {
    await fs.mkdir(path.dirname(this.stateFile), { recursive: true });
    await fs.mkdir(this.auditDir, { recursive: true });
  }

  async loadThreadState(threadId: string = 'default'): Promise<ThreadState> {
    try {
      const data = await fs.readFile(this.stateFile, 'utf8');
      const allStates = JSON.parse(data);
      
      const state = allStates[threadId];
      if (state && state.expires_at > Date.now()) {
        return state;
      }
    } catch (error) {
      // File doesn't exist or is invalid
    }

    // Default to Layer 0
    return {
      current_tier: AgentTier.LAYER_0,
      assigned_at: Date.now(),
      expires_at: Date.now() + (30 * 60 * 1000), // 30 minutes
      reason: 'default_assignment',
      token_usage: 0,
      operations_count: 0
    };
  }

  async saveThreadState(threadId: string, state: ThreadState): Promise<void> {
    let allStates: Record<string, ThreadState> = {};
    try {
      const data = await fs.readFile(this.stateFile, 'utf8');
      allStates = JSON.parse(data);
    } catch (error) {
      // File doesn't exist, start fresh
    }

    allStates[threadId] = state;
    await fs.writeFile(this.stateFile, JSON.stringify(allStates, null, 2));
  }

  async auditLog(operation: string, details: any): Promise<void> {
    const timestamp = new Date().toISOString();
    const logEntry = `## ${timestamp} - ${operation}\n\n\`\`\`json\n${JSON.stringify(details, null, 2)}\n\`\`\`\n\n`;
    
    const logFile = path.join(this.auditDir, `${new Date().toISOString().split('T')[0]}.md`);
    await fs.appendFile(logFile, logEntry);
  }

  isFridayAfternoon(): boolean {
    const now = new Date();
    return now.getDay() === 5 && now.getHours() >= 15;
  }

  async checkAutoPromotion(input: string): Promise<{ tier: AgentTier; duration: number } | null> {
    for (const [pattern, promotion] of Object.entries(AUTO_PROMOTION_PATTERNS)) {
      const regex = new RegExp(pattern, 'i');
      if (regex.test(input)) {
        return promotion;
      }
    }
    return null;
  }
}

// Create server instance
const server = new Server(
  {
    name: 'agent-role-manager',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

const roleManager = new AgentRoleServer();

// Initialize directories - wrapped in main function for proper module loading
async function initializeServer() {
  await roleManager.ensureDirectories();
}

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  const tools: Tool[] = [
    {
      name: 'get_current_role',
      description: 'Get current agent tier and capabilities',
      inputSchema: {
        type: 'object',
        properties: {
          thread_id: { type: 'string', description: 'Thread identifier (optional)' }
        }
      }
    },
    {
      name: 'check_permission',
      description: 'Check if current role has permission for an operation',
      inputSchema: {
        type: 'object',
        properties: {
          action: { type: 'string', description: 'Action to check permission for' },
          resource: { type: 'string', description: 'Resource being accessed' },
          thread_id: { type: 'string', description: 'Thread identifier (optional)' }
        },
        required: ['action']
      }
    },
    {
      name: 'auto_promote',
      description: 'Check for auto-promotion based on user input',
      inputSchema: {
        type: 'object',
        properties: {
          user_input: { type: 'string', description: 'User input to analyze for promotion patterns' },
          thread_id: { type: 'string', description: 'Thread identifier (optional)' }
        },
        required: ['user_input']
      }
    },
    {
      name: 'set_role',
      description: 'Manually set agent role (admin function)',
      inputSchema: {
        type: 'object',
        properties: {
          tier: { 
            type: 'string', 
            enum: ['layer_0', 'layer_2', 'layer_5'],
            description: 'Target agent tier'
          },
          duration_minutes: { type: 'number', description: 'Duration in minutes' },
          reason: { type: 'string', description: 'Reason for role change' },
          thread_id: { type: 'string', description: 'Thread identifier (optional)' }
        },
        required: ['tier', 'reason']
      }
    },
    {
      name: 'get_cost_analysis',
      description: 'Get cost analysis and optimization recommendations',
      inputSchema: {
        type: 'object',
        properties: {
          thread_id: { type: 'string', description: 'Thread identifier (optional)' }
        }
      }
    }
  ];

  return { tools };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const threadId = (args as any)?.thread_id || 'default';

  try {
    switch (name) {
      case 'get_current_role': {
        const state = await roleManager.loadThreadState(threadId as string);
        const capabilities = ROLE_DEFINITIONS[state.current_tier];
        
        await roleManager.auditLog('get_current_role', { threadId, state, capabilities });
        
        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              current_tier: state.current_tier,
              capabilities,
              time_remaining: Math.max(0, state.expires_at - Date.now()),
              token_usage: state.token_usage,
              operations_count: state.operations_count,
              cost_estimate: (state.token_usage * capabilities.cost_per_token).toFixed(4)
            }, null, 2)
          }]
        };
      }

      case 'check_permission': {
        const state = await roleManager.loadThreadState(threadId as string);
        const capabilities = ROLE_DEFINITIONS[state.current_tier];
        const { action, resource } = args as any;
        
        // Friday afternoon restrictions
        if (roleManager.isFridayAfternoon() && (action as string)?.includes('deploy')) {
          await roleManager.auditLog('permission_denied', { 
            threadId, action, resource, reason: 'friday_afternoon_restriction' 
          });
          
          return {
            content: [{
              type: 'text',
              text: JSON.stringify({
                allowed: false,
                reason: 'Friday afternoon deployments are restricted',
                current_tier: state.current_tier
              }, null, 2)
            }]
          };
        }

        // Check MCP server access
        let allowed = false;
        if ((resource as string)?.startsWith?.('mcp_')) {
          const serverName = (resource as string).replace('mcp_', '');
          allowed = capabilities.mcp_servers.includes('*') || capabilities.mcp_servers.includes(serverName);
        }
        // Check tool access
        else if ((resource as string)?.startsWith?.('tool_')) {
          const toolName = (resource as string).replace('tool_', '');
          allowed = capabilities.tools.includes('*') || capabilities.tools.includes(toolName);
        }
        // Check special permissions
        else if ((action as string) && capabilities.special_permissions.includes(action as string)) {
          allowed = true;
        }

        await roleManager.auditLog('permission_check', { 
          threadId, action, resource, allowed, current_tier: state.current_tier 
        });

        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              allowed,
              current_tier: state.current_tier,
              reason: allowed ? 'permission_granted' : 'insufficient_privileges'
            }, null, 2)
          }]
        };
      }

      case 'auto_promote': {
        const { user_input } = args as any;
        const promotion = await roleManager.checkAutoPromotion(user_input);
        
        if (promotion) {
          const state = await roleManager.loadThreadState(threadId as string);
          const newState: ThreadState = {
            current_tier: promotion.tier,
            assigned_at: Date.now(),
            expires_at: Date.now() + (promotion.duration * 60 * 1000),
            reason: 'auto_promotion',
            token_usage: state.token_usage,
            operations_count: state.operations_count
          };
          
          await roleManager.saveThreadState(threadId as string, newState);
          await roleManager.auditLog('auto_promotion', { 
            threadId, from: state.current_tier, to: promotion.tier, user_input 
          });

          return {
            content: [{
              type: 'text',
              text: JSON.stringify({
                promoted: true,
                previous_tier: state.current_tier,
                new_tier: promotion.tier,
                duration_minutes: promotion.duration,
                reason: 'Pattern matched auto-promotion rules'
              }, null, 2)
            }]
          };
        }

        return {
          content: [{
            type: 'text',
            text: JSON.stringify({ promoted: false, reason: 'No promotion patterns matched' }, null, 2)
          }]
        };
      }

      case 'set_role': {
        const { tier, duration_minutes = 60, reason } = args as any;
        const state = await roleManager.loadThreadState(threadId as string);
        
        const newState: ThreadState = {
          current_tier: tier as AgentTier,
          assigned_at: Date.now(),
          expires_at: Date.now() + ((duration_minutes as number) * 60 * 1000),
          reason: reason as string,
          token_usage: state.token_usage,
          operations_count: state.operations_count
        };
        
        await roleManager.saveThreadState(threadId as string, newState);
        await roleManager.auditLog('manual_role_change', { 
          threadId, from: state.current_tier, to: tier, reason, duration_minutes 
        });

        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              success: true,
              previous_tier: state.current_tier,
              new_tier: tier,
              expires_in_minutes: duration_minutes
            }, null, 2)
          }]
        };
      }

      case 'get_cost_analysis': {
        const state = await roleManager.loadThreadState(threadId as string);
        const capabilities = ROLE_DEFINITIONS[state.current_tier];
        const estimatedCost = state.token_usage * capabilities.cost_per_token;
        
        // Calculate optimization recommendations
        const recommendations = [];
        if (state.current_tier === AgentTier.LAYER_5 && state.operations_count < 3) {
          recommendations.push('Consider downgrading to Layer 2 for simple tasks');
        }
        if (state.token_usage > capabilities.max_token_budget * 0.8) {
          recommendations.push('Approaching token budget limit - consider task splitting');
        }

        return {
          content: [{
            type: 'text',
            text: JSON.stringify({
              current_tier: state.current_tier,
              token_usage: state.token_usage,
              estimated_cost: `$${estimatedCost.toFixed(4)}`,
              budget_utilization: `${((state.token_usage / capabilities.max_token_budget) * 100).toFixed(1)}%`,
              cost_per_operation: state.operations_count > 0 ? `$${(estimatedCost / state.operations_count).toFixed(4)}` : '$0.0000',
              recommendations
            }, null, 2)
          }]
        };
      }

      default:
        return {
          content: [{
            type: 'text',
            text: `Unknown tool: ${name}`
          }],
          isError: true
        };
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    await roleManager.auditLog('error', { threadId, tool: name, error: errorMessage });
    
    return {
      content: [{
        type: 'text',
        text: `Error: ${errorMessage}`
      }],
      isError: true
    };
  }
});

// Start server
async function main() {
  await initializeServer();
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);