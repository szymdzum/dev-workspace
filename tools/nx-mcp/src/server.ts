#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js'
import { exec } from 'child_process'
import { promisify } from 'util'
import * as path from 'path'
import * as fs from 'fs/promises'

const execAsync = promisify(exec)

interface NxProjectInfo {
  name: string
  type: string
  root: string
  sourceRoot?: string
  targets?: Record<string, unknown>
}

class NxWorkspaceServer {
  private workspaceRoot: string

  constructor() {
    this.workspaceRoot = '/Users/szymondzumak/Developer'
  }

  async runCommand(command: string): Promise<{ stdout: string; stderr: string }> {
    try {
      return await execAsync(command, {
        cwd: this.workspaceRoot,
        env: { ...process.env, PATH: process.env.PATH },
      })
    } catch (error: unknown) {
      const err = error as { stdout?: string; stderr?: string; message?: string }
      return {
        stdout: err.stdout || '',
        stderr: err.stderr || err.message || 'Command failed',
      }
    }
  }

  async getProjects(): Promise<NxProjectInfo[]> {
    try {
      const { stdout } = await this.runCommand('pnpm nx show projects --json')
      const projectNames = JSON.parse(stdout)

      const projects: NxProjectInfo[] = []
      for (const name of projectNames) {
        try {
          const { stdout: configStr } = await this.runCommand(`pnpm nx show project ${name} --json`)
          const config = JSON.parse(configStr)
          projects.push({
            name: config.name || name,
            type: config.projectType || 'unknown',
            root: config.root || '',
            sourceRoot: config.sourceRoot,
            targets: config.targets,
          })
        } catch (_error) {
          // Skip projects that can't be loaded
          projects.push({
            name,
            type: 'unknown',
            root: '',
          })
        }
      }
      return projects
    } catch (_error) {
      return []
    }
  }

  async getWorkspaceGraph(): Promise<unknown> {
    try {
      await this.runCommand('pnpm nx graph --file=/tmp/nx-graph.json')
      const graphData = await fs.readFile('/tmp/nx-graph.json', 'utf-8')
      return JSON.parse(graphData)
    } catch (_error) {
      return null
    }
  }

  async getAffectedProjects(): Promise<string[]> {
    try {
      const { stdout } = await this.runCommand('pnpm nx affected:projects')
      return stdout
        .trim()
        .split('\n')
        .filter(line => line.trim())
    } catch (_error) {
      return []
    }
  }

  async runTarget(
    project: string,
    target: string,
    options: string = ''
  ): Promise<{ stdout: string; stderr: string; success: boolean }> {
    const command = `pnpm nx run ${project}:${target} ${options}`
    const result = await this.runCommand(command)
    return {
      ...result,
      success: !result.stderr.includes('error') && !result.stderr.includes('failed'),
    }
  }

  async getRunningTasks(): Promise<unknown[]> {
    try {
      // Check for running nx processes
      const { stdout } = await this.runCommand('ps aux | grep "nx run" | grep -v grep')
      const lines = stdout
        .trim()
        .split('\n')
        .filter(line => line.trim())

      return lines.map(line => {
        const parts = line.split(/\s+/)
        return {
          pid: parts[1],
          command: parts.slice(10).join(' '),
          cpu: parts[2],
          memory: parts[3],
        }
      })
    } catch (_error) {
      return []
    }
  }
}

const server = new Server(
  {
    name: 'nx-workspace',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
)

const nxWorkspace = new NxWorkspaceServer()

server.setRequestHandler(ListToolsRequestSchema, async () => {
  const tools = [
    {
      name: 'nx_show_projects',
      description: 'List all projects in the Nx workspace',
      inputSchema: {
        type: 'object',
        properties: {},
      },
    },
    {
      name: 'nx_show_project',
      description: 'Show detailed information about a specific project',
      inputSchema: {
        type: 'object',
        properties: {
          project: { type: 'string', description: 'Project name' },
        },
        required: ['project'],
      },
    },
    {
      name: 'nx_graph',
      description: 'Get the workspace dependency graph',
      inputSchema: {
        type: 'object',
        properties: {},
      },
    },
    {
      name: 'nx_affected',
      description: 'Get projects affected by current changes',
      inputSchema: {
        type: 'object',
        properties: {},
      },
    },
    {
      name: 'nx_run_target',
      description: 'Run a target for a specific project',
      inputSchema: {
        type: 'object',
        properties: {
          project: { type: 'string', description: 'Project name' },
          target: { type: 'string', description: 'Target to run (build, test, lint, etc.)' },
          options: { type: 'string', description: 'Additional options' },
        },
        required: ['project', 'target'],
      },
    },
    {
      name: 'nx_running_tasks',
      description: 'Get currently running Nx tasks',
      inputSchema: {
        type: 'object',
        properties: {},
      },
    },
    {
      name: 'nx_workspace_command',
      description: 'Run arbitrary pnpm nx command in workspace',
      inputSchema: {
        type: 'object',
        properties: {
          command: {
            type: 'string',
            description: 'The nx command to run (without pnpm nx prefix)',
          },
        },
        required: ['command'],
      },
    },
  ]

  return { tools }
})

server.setRequestHandler(CallToolRequestSchema, async request => {
  const { name, arguments: args } = request.params

  try {
    switch (name) {
      case 'nx_show_projects': {
        const projects = await nxWorkspace.getProjects()
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(projects, null, 2),
            },
          ],
        }
      }

      case 'nx_show_project': {
        const { project } = args as { project: string }
        const result = await nxWorkspace.runCommand(`pnpm nx show project ${project} --json`)

        if (result.stderr && !result.stdout) {
          return {
            content: [
              {
                type: 'text',
                text: `Error: ${result.stderr}`,
              },
            ],
            isError: true,
          }
        }

        return {
          content: [
            {
              type: 'text',
              text: result.stdout,
            },
          ],
        }
      }

      case 'nx_graph': {
        const graph = await nxWorkspace.getWorkspaceGraph()
        return {
          content: [
            {
              type: 'text',
              text: graph ? JSON.stringify(graph, null, 2) : 'Could not generate workspace graph',
            },
          ],
        }
      }

      case 'nx_affected': {
        const affected = await nxWorkspace.getAffectedProjects()
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify({ affected_projects: affected }, null, 2),
            },
          ],
        }
      }

      case 'nx_run_target': {
        const {
          project,
          target,
          options = '',
        } = args as { project: string; target: string; options?: string }
        const result = await nxWorkspace.runTarget(project, target, options)

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(
                {
                  success: result.success,
                  stdout: result.stdout,
                  stderr: result.stderr,
                },
                null,
                2
              ),
            },
          ],
        }
      }

      case 'nx_running_tasks': {
        const tasks = await nxWorkspace.getRunningTasks()
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify({ running_tasks: tasks }, null, 2),
            },
          ],
        }
      }

      case 'nx_workspace_command': {
        const { command } = args as { command: string }
        const result = await nxWorkspace.runCommand(`pnpm nx ${command}`)

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(
                {
                  command: `pnpm nx ${command}`,
                  stdout: result.stdout,
                  stderr: result.stderr,
                },
                null,
                2
              ),
            },
          ],
        }
      }

      default:
        return {
          content: [
            {
              type: 'text',
              text: `Unknown tool: ${name}`,
            },
          ],
          isError: true,
        }
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${errorMessage}`,
        },
      ],
      isError: true,
    }
  }
})

async function main() {
  const transport = new StdioServerTransport()
  await server.connect(transport)
}

main().catch(console.error)
