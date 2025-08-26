# Python MCP Service: Agent Role Manager
*Simple, fast, no-compile MCP server for dynamic AI agent roles*

## Why Python for MCP

- **No compilation** - instant changes, immediate testing
- **Simple deployment** - single file, zero build steps
- **Fast iteration** - change roles, test instantly
- **JSON everywhere** - perfect for MCP protocol
- **Library ecosystem** - massive AI/ML tooling

## Core Service Architecture

```python
# mcp-service/main.py
from typing import Dict, List, Optional, Any
import json
import asyncio
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
from enum import Enum

class AgentRole(Enum):
    DRONE = "drone"           # $0.25/1M - fetch docs only
    SCOUT = "scout"           # $0.25/1M - search + basic analysis  
    DEVELOPER = "developer"   # $3/1M - code implementation
    ARCHITECT = "architect"   # $15/1M - high-level design
    ADMIN = "admin"          # $15/1M - system management

@dataclass
class AgentCapabilities:
    mcp_servers: List[str]
    tools: List[str] 
    max_token_budget: int
    timeout_minutes: Optional[int]
    special_permissions: List[str] = None

ROLE_DEFINITIONS = {
    AgentRole.DRONE: AgentCapabilities(
        mcp_servers=[],
        tools=["basic-chat"],
        max_token_budget=1000,
        timeout_minutes=None
    ),
    AgentRole.SCOUT: AgentCapabilities(
        mcp_servers=["web-search", "project-knowledge"],
        tools=["basic-chat", "read", "grep", "web-fetch"],
        max_token_budget=5000,
        timeout_minutes=30
    ),
    AgentRole.DEVELOPER: AgentCapabilities(
        mcp_servers=["filesystem", "git", "project-knowledge"],
        tools=["read", "write", "edit", "bash", "multi-edit"],
        max_token_budget=20000,
        timeout_minutes=60
    ),
    AgentRole.ARCHITECT: AgentCapabilities(
        mcp_servers=["*"],  # All available
        tools=["*"],        # All tools
        max_token_budget=50000,
        timeout_minutes=120,
        special_permissions=["task-delegation", "system-design"]
    )
}
```

## MCP Protocol Implementation

```python
# Simple MCP server that responds to agent role requests
import json
import sys
from typing import Dict, Any

class AgentRoleMCP:
    def __init__(self):
        self.current_roles = {}  # session_id -> role
        self.role_history = {}   # session_id -> list of role changes
        
    async def handle_request(self, request: Dict[str, Any]) -> Dict[str, Any]:
        method = request.get("method")
        params = request.get("params", {})
        
        if method == "get_agent_role":
            return await self.get_current_role(params)
        elif method == "set_agent_role": 
            return await self.set_agent_role(params)
        elif method == "check_permission":
            return await self.check_permission(params)
        elif method == "auto_promote":
            return await self.auto_promote(params)
        elif method == "get_role_status":
            return await self.get_role_status(params)
        else:
            return {"error": f"Unknown method: {method}"}
    
    async def get_current_role(self, params: Dict[str, Any]) -> Dict[str, Any]:
        session_id = params.get("session_id", "default")
        current_role = self.current_roles.get(session_id, AgentRole.DRONE)
        capabilities = ROLE_DEFINITIONS[current_role]
        
        return {
            "role": current_role.value,
            "capabilities": asdict(capabilities),
            "expires_at": self._get_expiration_time(session_id),
            "can_promote": self._can_auto_promote(session_id)
        }
    
    async def set_agent_role(self, params: Dict[str, Any]) -> Dict[str, Any]:
        session_id = params.get("session_id", "default")
        new_role = AgentRole(params.get("role"))
        reason = params.get("reason", "manual")
        duration_minutes = params.get("duration_minutes")
        
        # Security check
        if not self._can_assume_role(session_id, new_role, reason):
            return {"error": "Permission denied", "reason": "Insufficient privileges"}
        
        # Set the role
        self.current_roles[session_id] = new_role
        
        # Log the change
        if session_id not in self.role_history:
            self.role_history[session_id] = []
            
        self.role_history[session_id].append({
            "role": new_role.value,
            "reason": reason,
            "timestamp": datetime.now().isoformat(),
            "duration_minutes": duration_minutes
        })
        
        return {
            "success": True,
            "role": new_role.value,
            "expires_at": self._calculate_expiration(duration_minutes)
        }

    async def check_permission(self, params: Dict[str, Any]) -> Dict[str, Any]:
        session_id = params.get("session_id", "default")
        requested_action = params.get("action")
        resource = params.get("resource", "")
        
        current_role = self.current_roles.get(session_id, AgentRole.DRONE)
        capabilities = ROLE_DEFINITIONS[current_role]
        
        # Check MCP server access
        if resource.startswith("mcp_"):
            server_name = resource.replace("mcp_", "")
            allowed = (
                "*" in capabilities.mcp_servers or 
                server_name in capabilities.mcp_servers
            )
        # Check tool access  
        elif resource.startswith("tool_"):
            tool_name = resource.replace("tool_", "")
            allowed = (
                "*" in capabilities.tools or
                tool_name in capabilities.tools
            )
        else:
            allowed = False
            
        return {
            "allowed": allowed,
            "role": current_role.value,
            "reason": f"Role {current_role.value} {'allows' if allowed else 'denies'} access to {resource}"
        }

# Auto-promotion logic based on user input patterns
AUTO_PROMOTION_PATTERNS = {
    r"implement|build|create|write code": (AgentRole.DEVELOPER, 60),
    r"design|architect|plan system": (AgentRole.ARCHITECT, 120), 
    r"find|search|docs|documentation": (AgentRole.SCOUT, 30),
    r"deploy|production|admin": (AgentRole.ADMIN, 15),
}

def should_auto_promote(user_input: str) -> Optional[tuple[AgentRole, int]]:
    import re
    
    for pattern, (role, duration) in AUTO_PROMOTION_PATTERNS.items():
        if re.search(pattern, user_input, re.IGNORECASE):
            return (role, duration)
    
    return None
```

## Service Configuration

```python
# mcp-service/config.py
from dataclasses import dataclass
from typing import Dict, List

@dataclass
class MCPServiceConfig:
    # Server settings
    host: str = "localhost"
    port: int = 3001
    
    # Security settings
    max_role_duration_minutes: int = 240  # 4 hours max
    auto_demotion_enabled: bool = True
    security_logging: bool = True
    
    # Available MCP servers 
    available_mcp_servers: List[str] = None
    available_tools: List[str] = None
    
    # Cost limits (per role)
    token_budgets: Dict[str, int] = None
    
    def __post_init__(self):
        if self.available_mcp_servers is None:
            self.available_mcp_servers = [
                "web-search",
                "project-knowledge", 
                "filesystem",
                "git",
                "github",
                "google-drive",
                "slack",
                "kubernetes",
                "production-db"
            ]
            
        if self.available_tools is None:
            self.available_tools = [
                "basic-chat",
                "read", "write", "edit", "multi-edit",
                "bash", "grep", "glob",
                "web-fetch", "task-delegation"
            ]
            
        if self.token_budgets is None:
            self.token_budgets = {
                "drone": 1000,
                "scout": 5000, 
                "developer": 20000,
                "architect": 50000,
                "admin": 100000
            }

# Load config from environment or file
import os
import json

def load_config() -> MCPServiceConfig:
    config_file = os.getenv("MCP_CONFIG_FILE", "config.json")
    
    if os.path.exists(config_file):
        with open(config_file) as f:
            config_data = json.load(f)
            return MCPServiceConfig(**config_data)
    
    return MCPServiceConfig()
```

## Simple Deployment

```python
# mcp-service/server.py
import asyncio
import json
import sys
from agent_role_mcp import AgentRoleMCP
from config import load_config

async def main():
    config = load_config()
    service = AgentRoleMCP()
    
    print(f"Starting MCP Agent Role Service on {config.host}:{config.port}")
    
    # Simple stdio-based MCP server
    while True:
        try:
            # Read JSON-RPC request from stdin
            line = await asyncio.get_event_loop().run_in_executor(None, sys.stdin.readline)
            if not line:
                break
                
            request = json.loads(line.strip())
            response = await service.handle_request(request)
            
            # Write response to stdout
            print(json.dumps(response), flush=True)
            
        except json.JSONDecodeError:
            print(json.dumps({"error": "Invalid JSON"}), flush=True)
        except Exception as e:
            print(json.dumps({"error": str(e)}), flush=True)

if __name__ == "__main__":
    asyncio.run(main())
```

## Usage Integration

```bash
# Start the MCP service
cd mcp-service
python server.py

# Claude Code can now call:
# mcp__agent-role__get_current_role
# mcp__agent-role__set_agent_role  
# mcp__agent-role__check_permission
```

## Key Benefits

1. **Zero compilation** - instant changes during development
2. **Simple protocol** - JSON in, JSON out
3. **Lightweight** - single file, minimal dependencies  
4. **Fast iteration** - change roles, test immediately
5. **Easy deployment** - works anywhere Python runs
6. **Configurable** - JSON config for different environments

This gives you the **MCP infrastructure** for your experimental AI agent system with **maximum flexibility** and **minimum complexity**.