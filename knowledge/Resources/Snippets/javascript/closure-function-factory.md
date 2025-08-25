---
type: resource
category: snippet
language: javascript
created: 2025-01-23
modified: 2025-01-23
tags: [javascript, closures, function-factory, higher-order-functions]
source: "javascript-closures"
difficulty: beginner
use-cases: [specialized-functions, data-hiding, reusable-logic]
---

# Closure Function Factory Pattern

## Description

A function factory that creates specialized functions using closures. Each created function maintains its own private state and behavior based on the parameters passed to the factory.

## Code

```javascript
// Function factory creating a closure
function createAdder(amount) {
  return function(val) {
    return val + amount;
  };
}

// Creating specialized adder functions
const addOne = createAdder(1);
const addTen = createAdder(10);

console.log(addOne(5)); // 6
console.log(addTen(5)); // 15
```

## Usage Example

```javascript
// Use with array methods
const numbers = [1, 2, 3, 4, 5];
const addedTen = numbers.map(addTen);
console.log(addedTen); // [11, 12, 13, 14, 15]

// Create multiple specialized functions
const multiplyBy = (factor) => (value) => value * factor;
const double = multiplyBy(2);
const triple = multiplyBy(3);

console.log(double(4)); // 8
console.log(triple(4)); // 12
```

## Explanation

### Key Concepts
- **Closure**: The inner function "closes over" the `amount` parameter
- **Lexical Scope**: Inner function has access to outer function's variables
- **Factory Pattern**: Creates multiple specialized functions from one template

### Parameters
- `amount`: The value to add (captured in closure)
- `val`: The value to add to (passed when calling returned function)

### Return Value
Returns a new function that adds the captured `amount` to any value passed to it.

## Variations

### Generic Mathematical Operations
```javascript
const createOperator = (operation) => (a, b) => operation(a, b);

const add = createOperator((a, b) => a + b);
const multiply = createOperator((a, b) => a * b);
const power = createOperator((a, b) => Math.pow(a, b));

console.log(add(3, 4)); // 7
console.log(multiply(3, 4)); // 12  
console.log(power(3, 4)); // 81
```

### Configuration-Based Factory
```javascript
function createValidator(config) {
  return function(value) {
    if (config.required && !value) {
      return { valid: false, message: 'Value is required' };
    }
    if (config.minLength && value.length < config.minLength) {
      return { valid: false, message: `Minimum length is ${config.minLength}` };
    }
    return { valid: true };
  };
}

const emailValidator = createValidator({ required: true, minLength: 5 });
const passwordValidator = createValidator({ required: true, minLength: 8 });
```

## Gotchas & Notes

- Each function created by the factory has its own separate closure
- The factory parameter is captured by value, not by reference
- Memory efficient: the factory function can be garbage collected after use
- Perfect for creating specialized functions in functional programming

## Related Snippets

- [[closure-counter]] - Counter with private state
- [[closure-data-collector]] - Data collection pattern
- [[higher-order-functions]] - Functions that return functions

## External Resources

- [MDN: Closures](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Closures)
- [You Don't Know JS: Scope & Closures](https://github.com/getify/You-Dont-Know-JS)

---

**Tags**: javascript, closures, function-factory, higher-order-functions
**Difficulty**: beginner
**Last Updated**: 2025-01-23