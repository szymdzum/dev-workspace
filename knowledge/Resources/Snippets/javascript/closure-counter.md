---
type: resource
category: snippet
language: javascript
created: 2025-01-23
modified: 2025-01-23
tags: [javascript, closures, private-variables, state-management]
source: "javascript-closures"
difficulty: beginner
use-cases: [data-hiding, state-management, private-variables]
---

# Closure Counter Pattern

## Description

Creates a counter function with private state using closures. This pattern provides data encapsulation without using classes or objects, keeping the counter variable private and inaccessible from outside.

## Code

```javascript
// Counter with private state using closures
function createCounter() {
  let counter = 0;  // Private variable
  return function() {
    return ++counter;
  };
}

const counter1 = createCounter();
const counter2 = createCounter();

console.log(counter1()); // 1
console.log(counter1()); // 2
console.log(counter2()); // 1 (separate state)
```

## Usage Example

```javascript
// Enhanced counter with multiple operations
function createAdvancedCounter(initialValue = 0) {
  let count = initialValue;
  
  return {
    increment: () => ++count,
    decrement: () => --count,
    reset: () => { count = initialValue; return count; },
    value: () => count
  };
}

const counter = createAdvancedCounter(10);
console.log(counter.increment()); // 11
console.log(counter.decrement()); // 10
console.log(counter.value()); // 10
console.log(counter.reset()); // 10
```

## Explanation

### Key Concepts
- **Data Hiding**: Counter variable is not accessible from outside
- **Private State**: Each counter instance maintains separate state
- **Encapsulation**: Internal state is protected from external modification

### Parameters
- `initialValue` (optional): Starting value for the counter

### Return Value
Returns a function (or object with methods) that can manipulate the private counter variable.

## Variations

### Simple Toggle
```javascript
function createToggle(initialState = false) {
  let state = initialState;
  return () => state = !state;
}

const toggle = createToggle();
console.log(toggle()); // true
console.log(toggle()); // false
```

### ID Generator
```javascript
function createIdGenerator(prefix = 'id') {
  let id = 0;
  return () => `${prefix}-${++id}`;
}

const userId = createIdGenerator('user');
const productId = createIdGenerator('product');

console.log(userId()); // "user-1"
console.log(productId()); // "product-1"
console.log(userId()); // "user-2"
```

### Rate Limiter
```javascript
function createRateLimiter(maxCalls, timeWindow) {
  let calls = [];
  
  return function() {
    const now = Date.now();
    calls = calls.filter(time => now - time < timeWindow);
    
    if (calls.length >= maxCalls) {
      return false; // Rate limit exceeded
    }
    
    calls.push(now);
    return true; // Call allowed
  };
}

const limiter = createRateLimiter(5, 1000); // 5 calls per second
```

## Gotchas & Notes

- **Memory**: Each closure maintains its own copy of variables
- **No Direct Access**: Private variables cannot be accessed directly
- **Separate Instances**: Each function call to the factory creates a new closure
- **Alternative to Classes**: Provides data privacy without OOP syntax

## Related Snippets

- [[closure-function-factory]] - Function factory pattern
- [[closure-data-collector]] - Data collection with closures
- [[module-pattern]] - Module pattern using IIFE and closures

## External Resources

- [MDN: Closures](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Closures)
- [JavaScript Private Variables](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_class_fields)

---

**Tags**: javascript, closures, private-variables, state-management
**Difficulty**: beginner  
**Last Updated**: 2025-01-23