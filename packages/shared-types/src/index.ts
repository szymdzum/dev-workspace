// Agent role system types
export enum AgentTier {
  LAYER_0 = 'layer_0', // Haiku: $0.0001 - Information retrieval
  LAYER_2 = 'layer_2', // Sonnet: $0.003 - Analysis and implementation
  LAYER_5 = 'layer_5', // Opus: $0.015 - Architectural decisions
}

export interface AgentCapabilities {
  mcp_servers: string[]
  tools: string[]
  max_token_budget: number
  timeout_minutes: number | null
  cost_per_token: number
  special_permissions: string[]
}

export interface ThreadState {
  current_tier: AgentTier
  assigned_at: number
  expires_at: number
  reason: string
  token_usage: number
  operations_count: number
}

// Telemetry types
export interface TelemetryEvent {
  id: string
  timestamp: number
  type: string
  data: Record<string, any>
  thread_id?: string
  agent_tier?: AgentTier
  cost?: number
}

export interface PerformanceMetric {
  name: string
  value: number
  unit: string
  timestamp: number
  labels?: Record<string, string>
}

// Audit types
export interface AuditLogEntry {
  timestamp: string
  thread_id: string
  operation: string
  agent_tier: AgentTier
  success: boolean
  details: Record<string, any>
  cost_estimate?: number
}

// Context routing types
export interface TaskComplexity {
  score: number
  factors: string[]
  recommended_tier: AgentTier
  confidence: number
}

export interface ContextPackage {
  query: string
  complexity: TaskComplexity
  sources: DocumentSource[]
  total_tokens: number
  harvested_at: number
}

export interface DocumentSource {
  type: 'file' | 'web' | 'memory'
  path: string
  content: string
  relevance: number
  tokens: number
}
