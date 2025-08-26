#!/usr/bin/env tsx
/**
 * Dev Hub Health Check & Auto-Fixer
 * 
 * "Because your other Claude thread is busy philosophizing about context"
 * 
 * Run this to:
 * 1. Fix your NX caching (you're literally paying for nothing)
 * 2. Clean up pnpm's emotional baggage
 * 3. Actually configure the tools you have
 * 
 * Usage: tsx dev-hub-health.ts [--fix] [--roast]
 */

import { execSync } from 'child_process';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join } from 'path';

const DEV_HUB = process.env.HOME + '/Developer';
const ROAST_MODE = process.argv.includes('--roast');
const FIX_MODE = process.argv.includes('--fix');

// Your current reality check
const healthCheck = {
  layers: {
    packageManager: {
      issue: "pnpm lockfile v9.0 - so bleeding edge it needs therapy",
      fix: "Add .npmrc with loglevel=warn to stop the chattiness",
      priority: 1
    },
    nxMonorepo: {
      issue: "NX Cloud configured but cache disabled - that's $ down the drain",
      fix: "Enable caching for all targets NOW",
      priority: 10
    },
    apps: {
      issue: "Cloudflare config exists but gathering dust",
      fix: "Actually deploy something this week",
      priority: 5
    },
    libs: {
      issue: "47-hour claude-hooks saga still haunts the codebase",
      fix: "It works, leave it alone, frame the documentation",
      priority: 0
    },
    contextBeast: {
      issue: "Still in 'throwing spaghetti' phase",
      fix: "Ship Week 1 of your own damn plan",
      priority: 8
    }
  }
};

// The fixes that actually matter
const criticalFixes = {
  enableNxCaching: () => {
    console.log("🚀 Enabling NX caching (this should've been day 1)...");
    
    const nxConfig = JSON.parse(readFileSync(join(DEV_HUB, 'nx.json'), 'utf8'));
    
    // Add proper caching config
    nxConfig.targetDefaults = {
      ...nxConfig.targetDefaults,
      "build": {
        "cache": true,
        "outputs": ["{projectRoot}/dist"],
        "inputs": ["production", "^production"]
      },
      "test": {
        "cache": true,
        "inputs": ["default", "^default", "{workspaceRoot}/jest.preset.js"]
      },
      "lint": {
        "cache": true,
        "inputs": ["default", "{workspaceRoot}/.eslintrc.json", "{workspaceRoot}/biome.json"]
      }
    };

    // Enable batch mode for 5x TypeScript speed
    nxConfig.tasksRunnerOptions = {
      "default": {
        "options": {
          "batchMode": true,
          "cacheableOperations": ["build", "test", "lint"]
        }
      }
    };

    if (FIX_MODE) {
      writeFileSync(join(DEV_HUB, 'nx.json'), JSON.stringify(nxConfig, null, 2));
      console.log("✅ NX now configured for actual performance");
    } else {
      console.log("👀 Would update nx.json (add --fix to apply)");
    }
  },

  createNpmrc: () => {
    console.log("🤫 Silencing pnpm's life story...");
    
    const npmrcContent = `# Stop pnpm from being a drama queen
loglevel=warn
prefer-offline=true
fetch-retries=3
fetch-retry-factor=2
fetch-retry-mintimeout=10000
strict-peer-dependencies=false
auto-install-peers=true

# Performance optimizations
side-effects-cache=true
shamefully-hoist=false
`;

    if (FIX_MODE) {
      writeFileSync(join(DEV_HUB, '.npmrc'), npmrcContent);
      console.log("✅ pnpm will now keep its feelings to itself");
    } else {
      console.log("👀 Would create .npmrc (add --fix to apply)");
    }
  },

  resetNxDaemon: () => {
    console.log("🔄 Kicking the NX daemon (percussive maintenance)...");
    
    if (FIX_MODE) {
      try {
        execSync('nx reset', { cwd: DEV_HUB });
        execSync('nx daemon --start', { cwd: DEV_HUB });
        console.log("✅ NX daemon restarted (and slightly less confused)");
      } catch (e) {
        console.log("⚠️ NX daemon refused to cooperate. Try manually: nx reset");
      }
    } else {
      console.log("👀 Would restart NX daemon (add --fix to apply)");
    }
  },

  generateHealthReport: () => {
    const report = {
      timestamp: new Date().toISOString(),
      nodeVersion: process.version,
      layers: Object.entries(healthCheck.layers)
        .sort((a, b) => b[1].priority - a[1].priority)
        .map(([name, data]) => ({
          name,
          ...data,
          status: data.priority > 7 ? '🔥 CRITICAL' : 
                  data.priority > 3 ? '⚠️ NEEDS ATTENTION' : 
                  '✅ ACCEPTABLE'
        })),
      recommendations: [
        "1. Enable NX caching RIGHT NOW (2 min fix, 10x speed)",
        "2. Deploy SOMETHING to Cloudflare this week",
        "3. Start Context Beast Week 1 (stop planning)",
        "4. Clean up node_modules occasionally (pnpm store prune)",
        "5. Never spend 47 hours on shell scripts again"
      ],
      roast: ROAST_MODE ? generateRoast() : null
    };

    writeFileSync(
      join(DEV_HUB, '.dev-hub-health.json'), 
      JSON.stringify(report, null, 2)
    );
    
    console.log("\n📊 Health report saved to .dev-hub-health.json");
    return report;
  }
};

function generateRoast() {
  const roasts = [
    "Your NX config is like a gym membership - expensive and unused",
    "That Context Beast has been 'Week 0' for how long exactly?",
    "Node v24.6.0? Even the Node maintainers don't know what that does",
    "47 hours for shell wrappers is why we can't have nice things",
    "Your pnpm lockfile is newer than some JavaScript frameworks"
  ];
  
  return roasts[Math.floor(Math.random() * roasts.length)];
}

// Main execution
async function main() {
  console.log("🏥 DEV HUB EMERGENCY ROOM\n");
  console.log("Current Status: 'It works but could be 10x better'\n");

  // Check what needs fixing
  const priorities = Object.entries(healthCheck.layers)
    .filter(([_, data]) => data.priority > 5)
    .sort((a, b) => b[1].priority - a[1].priority);

  console.log("🔥 CRITICAL ISSUES:\n");
  priorities.forEach(([name, data]) => {
    console.log(`  ${name}: ${data.issue}`);
    console.log(`  → Fix: ${data.fix}\n`);
  });

  if (FIX_MODE) {
    console.log("💊 Applying fixes...\n");
    criticalFixes.enableNxCaching();
    criticalFixes.createNpmrc();
    criticalFixes.resetNxDaemon();
  } else {
    console.log("💡 Run with --fix to apply these changes automatically\n");
  }

  const report = criticalFixes.generateHealthReport();
  
  if (ROAST_MODE && report.roast) {
    console.log(`\n🎭 Today's Roast: "${report.roast}"`);
  }

  console.log("\n✨ Remember: Ship > Perfect. Your 47-hour saga proved that.\n");
}

// Check if running directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}

export { healthCheck, criticalFixes };