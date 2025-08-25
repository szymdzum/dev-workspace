#!/usr/bin/env tsx

import fs from 'fs';
import path from 'path';

interface SessionEntry {
  type: string;
  summary?: string;
  message?: {
    role: string;
    content: string | any[];
  };
  timestamp?: string;
  uuid?: string;
}

interface TodoItem {
  content: string;
  status: 'completed' | 'in_progress' | 'pending';
  activeForm: string;
}

interface SessionAnalysis {
  totalSessions: number;
  totalMessages: number;
  completedTasks: number;
  commonTopics: string[];
  productivity: {
    tasksPerSession: number;
    completionRate: number;
  };
  timeRange: {
    first: Date;
    last: Date;
  };
}

class SessionAnalyzer {
  private runtimeDir: string;

  constructor() {
    this.runtimeDir = path.join(__dirname, '../runtime');
  }

  async analyze(): Promise<SessionAnalysis> {
    console.log('🔍 Analyzing Claude sessions...\n');

    const projectsDir = path.join(this.runtimeDir, 'projects');
    const todosDir = path.join(this.runtimeDir, 'todos');

    // Analyze session transcripts
    const sessionStats = await this.analyzeProjects(projectsDir);
    
    // Analyze completed tasks
    const taskStats = await this.analyzeTodos(todosDir);

    const analysis: SessionAnalysis = {
      totalSessions: sessionStats.sessions,
      totalMessages: sessionStats.messages,
      completedTasks: taskStats.completed,
      commonTopics: sessionStats.topics,
      productivity: {
        tasksPerSession: taskStats.completed / sessionStats.sessions,
        completionRate: taskStats.completionRate
      },
      timeRange: sessionStats.timeRange
    };

    this.printAnalysis(analysis);
    return analysis;
  }

  private async analyzeProjects(projectsDir: string) {
    const projects = fs.readdirSync(projectsDir);
    let totalSessions = 0;
    let totalMessages = 0;
    const topics = new Map<string, number>();
    let earliestDate = new Date();
    let latestDate = new Date(0);

    for (const project of projects) {
      const projectPath = path.join(projectsDir, project);
      const sessions = fs.readdirSync(projectPath).filter(f => f.endsWith('.jsonl'));
      
      for (const session of sessions) {
        totalSessions++;
        const sessionPath = path.join(projectPath, session);
        const lines = fs.readFileSync(sessionPath, 'utf-8').split('\n').filter(Boolean);
        
        for (const line of lines) {
          try {
            const entry: SessionEntry = JSON.parse(line);
            
            if (entry.timestamp) {
              const date = new Date(entry.timestamp);
              if (date < earliestDate) earliestDate = date;
              if (date > latestDate) latestDate = date;
            }

            if (entry.message) {
              totalMessages++;
              
              // Extract topics from summaries and messages
              if (entry.summary) {
                this.extractTopics(entry.summary, topics);
              }
              
              if (typeof entry.message.content === 'string') {
                this.extractTopics(entry.message.content, topics);
              }
            }
          } catch (e) {
            // Skip malformed lines
          }
        }
      }
    }

    const sortedTopics = Array.from(topics.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([topic]) => topic);

    return {
      sessions: totalSessions,
      messages: totalMessages,
      topics: sortedTopics,
      timeRange: { first: earliestDate, last: latestDate }
    };
  }

  private async analyzeTodos(todosDir: string) {
    const todoFiles = fs.readdirSync(todosDir).filter(f => f.endsWith('.json'));
    let totalTasks = 0;
    let completedTasks = 0;

    for (const file of todoFiles) {
      try {
        const todos: TodoItem[] = JSON.parse(
          fs.readFileSync(path.join(todosDir, file), 'utf-8')
        );
        
        totalTasks += todos.length;
        completedTasks += todos.filter(t => t.status === 'completed').length;
      } catch (e) {
        // Skip malformed files
      }
    }

    return {
      total: totalTasks,
      completed: completedTasks,
      completionRate: totalTasks > 0 ? completedTasks / totalTasks : 0
    };
  }

  private extractTopics(text: string, topics: Map<string, number>) {
    // Simple keyword extraction for development topics
    const keywords = [
      'typescript', 'javascript', 'react', 'node', 'nx', 'hooks', 'claude',
      'build', 'test', 'deploy', 'api', 'database', 'auth', 'component',
      'library', 'framework', 'config', 'setup', 'migration', 'refactor',
      'optimization', 'bug', 'feature', 'documentation', 'git'
    ];

    const lowercaseText = text.toLowerCase();
    
    for (const keyword of keywords) {
      if (lowercaseText.includes(keyword)) {
        topics.set(keyword, (topics.get(keyword) || 0) + 1);
      }
    }
  }

  private printAnalysis(analysis: SessionAnalysis) {
    console.log('📊 Session Analysis Results');
    console.log('=' * 50);
    console.log(`📅 Time Range: ${analysis.timeRange.first.toLocaleDateString()} - ${analysis.timeRange.last.toLocaleDateString()}`);
    console.log(`💬 Total Sessions: ${analysis.totalSessions}`);
    console.log(`📝 Total Messages: ${analysis.totalMessages}`);
    console.log(`✅ Completed Tasks: ${analysis.completedTasks}`);
    console.log(`📈 Productivity: ${analysis.productivity.tasksPerSession.toFixed(1)} tasks/session`);
    console.log(`🎯 Task Completion Rate: ${(analysis.productivity.completionRate * 100).toFixed(1)}%`);
    console.log('\n🔥 Top Topics:');
    
    analysis.commonTopics.forEach((topic, index) => {
      console.log(`  ${index + 1}. ${topic}`);
    });
  }
}

// CLI interface
if (require.main === module) {
  const analyzer = new SessionAnalyzer();
  analyzer.analyze().catch(console.error);
}

export { SessionAnalyzer };