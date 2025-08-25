# Problem-Solving Methodology for Claude Code Development

**Context**: Systematic approach discovered during Claude Code hook system implementation  
**Date**: August 25, 2025  
**Status**: Battle-tested and refined  

---

## 🎯 The Core Algorithm

### **Phase 1: Understand The Execution Environment FIRST**

```
BEFORE writing any code:
1. Understand HOW the system executes your solution
2. Understand WHEN the system loads/applies changes  
3. Understand WHERE the system looks for dependencies
4. Understand WHAT format the system expects

❌ NEVER assume standard Node.js/TypeScript patterns apply
✅ ALWAYS verify the actual execution model
```

**Our Example**:
- **Assumption**: Claude Code imports TypeScript modules
- **Reality**: Claude Code executes shell commands with JSON stdin/stdout
- **Cost**: Hours of debugging "perfect" code that never ran

### **Phase 2: Get To The Minimal Viable Test**

```
Create the simplest possible test that proves the core concept:
1. Strip away all complexity 
2. Test the fundamental interaction
3. Verify the execution path works
4. THEN add complexity incrementally

Priority: Working simple version > Perfect complex version that doesn't work
```

**Our Example**:
```bash
# Minimal test that worked:
echo '{"content":"secret-key"}' | simple-check.sh
# Output: {"continue":false}

# vs. Complex TypeScript that failed at runtime
```

### **Phase 3: Follow The Error Messages To The Root**

```
When debugging:
1. Read the EXACT error message
2. Identify the SYSTEM making the complaint  
3. Understand the EXPECTATION vs REALITY gap
4. Fix the ROOT CAUSE, not the symptom

Error messages are breadcrumbs - follow them to understanding
```

**Our Error Journey**:
1. `Cannot find module '@claude-dev/hooks'` → Module resolution issue
2. `Path argument must be of type string` → Vite configuration issue  
3. `PreToolUse:Write is not valid` → Claude Code schema issue

### **Phase 4: Test At The Boundary**

```
Always test at the integration boundary:
1. Mock the external system's interface
2. Verify your code works in isolation
3. Verify the external system can call your code
4. Test the round-trip: input → processing → output

The boundary is where assumptions break down
```

**Our Boundary Tests**:
- Manual JSON stdin testing
- Shell script execution verification  
- Claude Code settings validation
- End-to-end hook execution

---

## 🔍 Systematic Debugging Framework

### **The DREAM Method**

**D** - **Document the symptom** exactly as it appears  
**R** - **Reproduce** the issue in isolation  
**E** - **Examine** the execution path step by step  
**A** - **Analyze** assumptions vs reality  
**M** - **Modify** the smallest possible change to test hypothesis  

### **Example Application**:

**D**: "Hooks aren't executing when I write files"
**R**: Test hook manually with echo/pipe → Works
**E**: Check Claude Code settings → Hook registered → Settings format correct
**A**: Assumption: Changes apply immediately | Reality: Requires restart/review
**M**: Use `/hooks` command to apply changes

---

## 🏗️ Architecture Discovery Process

### **1. Start With The Interface**

```
Define the contract FIRST:
- Input format and validation
- Output format and success/error states  
- Error handling and edge cases
- Performance and timeout requirements

The interface is your north star
```

### **2. Work Backwards From The Requirement**

```
Question sequence:
1. What does success look like? (Output format)
2. What inputs are needed? (Input validation)  
3. What can go wrong? (Error handling)
4. What are the constraints? (Performance, security, compatibility)

This prevents over-engineering and scope creep
```

### **3. Build In Layers**

```
Layer 1: Core logic (pure functions, no dependencies)
Layer 2: Input/output handling (parsing, validation, formatting)  
Layer 3: Integration layer (file system, network, external APIs)
Layer 4: Execution wrapper (shell scripts, error handling, logging)

Test each layer independently
```

---

## 🧪 Testing Strategy Framework

### **The Testing Pyramid for Claude Code**

```
              /\
             /  \  Manual Integration Testing
            /____\  (Claude Code execution)
           /      \
          /        \ Unit Testing  
         /  Shell   \ (TypeScript logic)
        /   Script   \
       /   Testing    \ System Testing
      /   (stdin/out)  \ (Shell execution)
     /_________________\
```

### **Testing Phases**

#### **Phase 1: Logic Testing**
```typescript
// Test business logic in isolation
describe('SecurityValidator', () => {
  it('detects OpenAI API keys', () => {
    const result = validator.scanForSecrets('const key = "sk-123..."');
    expect(result.violations).toHaveLength(1);
  });
});
```

#### **Phase 2: Interface Testing**  
```bash
# Test shell script interface
echo '{"content":"sk-123"}' | ./check-secrets.sh
# Expected: {"continue":false,"reason":"API key detected"}
```

#### **Phase 3: Integration Testing**
```bash
# Test within Claude Code environment
# Use /hooks command to verify registration
# Use claude --debug to see execution
```

---

## 🔧 Problem Classification System

### **Type 1: Environment Problems**
- **Symptoms**: "Cannot find module", "Command not found", "Permission denied"
- **Approach**: Understand the execution environment first
- **Tools**: Process inspection, path analysis, permission checking

### **Type 2: Configuration Problems**  
- **Symptoms**: "Invalid format", "Schema validation failed", "Settings not applied"
- **Approach**: Study the configuration schema and validation rules
- **Tools**: Schema validators, documentation, example configurations

### **Type 3: Integration Problems**
- **Symptoms**: Code works in isolation but fails when integrated
- **Approach**: Test at the boundary, mock external dependencies
- **Tools**: Boundary testing, mock frameworks, isolation techniques

### **Type 4: Timing Problems**
- **Symptoms**: Intermittent failures, race conditions, "works sometimes"  
- **Approach**: Understand the lifecycle and timing constraints
- **Tools**: Logging, timing analysis, sequence diagrams

---

## 📋 Decision Framework

### **The DECIDE Process**

**D** - **Define** the problem clearly  
**E** - **Establish** criteria for success  
**C** - **Consider** alternatives  
**I** - **Identify** the best alternative  
**D** - **Develop** action plan  
**E** - **Evaluate** and monitor  

### **Example: Module Resolution Problem**

**Define**: TypeScript hooks can't find workspace packages at runtime  
**Establish**: Must work in Claude Code's shell execution environment  
**Consider**: 
- Bundle with Vite → Path configuration issues
- Relative imports → Complex path management  
- Shell wrappers → Simple, compatible
**Identify**: Shell wrapper approach  
**Develop**: Create .sh scripts that call TypeScript via node/ts-node  
**Evaluate**: Test manually, then integrate with Claude Code

---

## 🎮 Tactical Approaches

### **When Stuck: The RESET Protocol**

**R** - **Read** the error message completely  
**E** - **Examine** assumptions about how the system works  
**S** - **Simplify** to the most basic case that should work  
**E** - **Execute** the simple case and observe results  
**T** - **Trace** the execution path step by step  

### **When Building: The BUILD Protocol**

**B** - **Begin** with the interface contract  
**U** - **Understand** the execution environment  
**I** - **Implement** core logic first  
**L** - **Layer** on integration components  
**D** - **Debug** at each integration boundary  

### **When Debugging: The TRACE Protocol**

**T** - **Test** the hypothesis with minimal reproduction  
**R** - **Read** system logs and error messages carefully  
**A** - **Analyze** the gap between expected and actual behavior  
**C** - **Change** one variable at a time  
**E** - **Evaluate** the results before making the next change  

---

## 📈 Success Patterns

### **Pattern 1: Progressive Disclosure**
Start simple, add complexity incrementally:
```
Simple shell script → TypeScript logic → Full plugin system
Working example → Production features → Enterprise extensions
```

### **Pattern 2: Boundary Testing**
Test at every integration point:
```
JSON parsing → Business logic → Shell execution → Claude Code integration
```

### **Pattern 3: Assumption Validation**
Question every assumption:
```
"This should work like Node.js" → Verify execution model
"Configuration updates immediately" → Check documentation  
"Standard paths apply" → Test actual path resolution
```

### **Pattern 4: Error-Driven Development**
Use errors as guides:
```
Error message → Research phase → Understanding → Implementation → Test
```

---

## 🚫 Anti-Patterns to Avoid

### **The "It Should Work" Trap**
```
❌ "This TypeScript compiles fine, so it should work in Claude Code"
✅ "Let me test this in Claude Code's actual execution environment"
```

### **The "Perfect First Try" Trap**
```
❌ Building the complete system before testing any part
✅ Building the minimal viable test first, then expanding
```

### **The "Assumption Stack" Trap**
```
❌ Building on multiple unverified assumptions
✅ Validating each assumption before building on it
```

### **The "Debug By Addition" Trap**
```
❌ Adding more code/configuration when something doesn't work  
✅ Simplifying to understand the root cause first
```

---

## 🎯 Environment-Specific Guidelines

### **For Claude Code Development**

1. **Always test shell scripts manually before registering**
2. **Use the `/hooks` command to verify registration** 
3. **Remember configuration changes require restart or review**
4. **JSON format must be exact** - test with `echo | jq` first
5. **Permissions matter** - ensure scripts are executable
6. **Path resolution is different** - use `$CLAUDE_PROJECT_DIR`

### **For TypeScript/Node.js Integration**

1. **Workspace packages don't exist at runtime**
2. **Use relative imports or bundling for dependencies**
3. **Shell wrappers bridge the TypeScript/Claude Code gap**
4. **ts-node works for development, compilation for production**
5. **Environment variables need explicit setup**

### **For Shell Script Development**

1. **Always use `set -euo pipefail` for safety**
2. **Quote all variables: `"$VAR"` not `$VAR`**  
3. **Test JSON parsing with `jq` first**
4. **Use `command -v` to check for dependencies**
5. **Provide meaningful exit codes and error messages**

---

## 📚 Learning Methodology

### **The LEARN Cycle**

**L** - **Listen** to error messages and system feedback  
**E** - **Experiment** with minimal test cases  
**A** - **Analyze** the gap between expectation and reality  
**R** - **Research** documentation and examples  
**N** - **Note** insights for future reference  

### **Documentation Strategy**

1. **Document your assumptions** before you start
2. **Document what you learn** as you discover it  
3. **Document the decision rationale** for future reference
4. **Document the testing approach** for repeatability
5. **Document the failure modes** for debugging

---

## 🎉 Success Metrics

### **Process Success**
- ✅ Problems identified and resolved systematically
- ✅ Root causes found, not just symptoms treated  
- ✅ Learning captured for future application
- ✅ Testing strategy prevents regression

### **Outcome Success**
- ✅ Solution works in the target environment
- ✅ Architecture is maintainable and extensible  
- ✅ Performance meets requirements
- ✅ Security and reliability standards met

---

## 💡 Key Insights

### **1. The Environment Is The Truth**
Your code's elegance doesn't matter if it can't run in the target environment. Always understand the execution model first.

### **2. Assumptions Are Expensive**
Every unverified assumption adds risk. Validate assumptions as early as possible in the development process.

### **3. Simple Working Beats Complex Broken**
A simple solution that works is infinitely more valuable than a perfect solution that doesn't work.

### **4. Errors Are Teachers**
Error messages contain the information you need to succeed. Learn to read them as guidance, not obstacles.

### **5. Testing Is Discovery**
Testing isn't just validation - it's how you discover how the system actually works.

---

**This methodology is a living document - update it as you discover new patterns and insights in Claude Code development.**