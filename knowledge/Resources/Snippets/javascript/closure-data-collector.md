---
type: resource
category: snippet
language: javascript
created: 2025-01-23
modified: 2025-01-23
tags: [javascript, closures, data-collection, callbacks, async]
source: "javascript-closures"
difficulty: intermediate
use-cases: [data-aggregation, async-callbacks, api-responses, state-accumulation]
---

# Closure Data Collector Pattern

## Description

Creates a data collector function that accumulates data from multiple asynchronous operations using closures. Useful when you need to gather data from multiple API calls or callback functions into a single object.

## Code

```javascript
// Create a collector using closures
function createCollector() {
  let store = {};  // Private data store
  return function(data) {
    if (!data) return store;  // Return current data if no argument
    store = { ...store, ...data }; // Merge new data
    return store;
  };
}

// Usage with simulated API calls
function fetchFirstName(callback) {
  setTimeout(() => callback({ firstName: "Jane" }), 100);
}

function fetchLastName(callback) {
  setTimeout(() => callback({ lastName: "Doe" }), 150);
}

function fetchEmail(callback) {
  setTimeout(() => callback({ email: "jane.doe@example.com" }), 200);
}

const myCollector = createCollector();
fetchFirstName(myCollector);
fetchLastName(myCollector);
fetchEmail(myCollector);

// Check collected data after all calls complete
setTimeout(() => {
  console.log(myCollector()); 
  // { firstName: "Jane", lastName: "Doe", email: "jane.doe@example.com" }
}, 300);
```

## Usage Example

```javascript
// Enhanced collector with validation and events
function createAdvancedCollector(requiredFields = []) {
  let store = {};
  let listeners = [];
  
  const collector = function(data) {
    if (!data) return store;
    
    // Merge data
    store = { ...store, ...data };
    
    // Notify listeners
    listeners.forEach(listener => listener(store));
    
    // Check if all required fields are present
    if (requiredFields.every(field => store[field])) {
      collector.onComplete?.(store);
    }
    
    return store;
  };
  
  collector.onUpdate = (listener) => listeners.push(listener);
  collector.isComplete = () => requiredFields.every(field => store[field]);
  collector.reset = () => { store = {}; return collector; };
  
  return collector;
}

// Usage
const userCollector = createAdvancedCollector(['id', 'name', 'email']);

userCollector.onComplete = (data) => {
  console.log('User data complete:', data);
};

userCollector.onUpdate((data) => {
  console.log('Data updated:', Object.keys(data));
});
```

## Explanation

### Key Concepts
- **Data Accumulation**: Gradually builds up an object from multiple sources
- **Closure State**: Maintains private store that persists across calls
- **Callback Pattern**: Works seamlessly with callback-based APIs
- **Flexible Interface**: Can return data or accept new data based on arguments

### Parameters
- `data` (optional): New data to merge into the store
- No parameter: Returns current accumulated data

### Return Value
Returns the updated data store after merging, or current store if no data provided.

## Variations

### Array Collector
```javascript
function createArrayCollector() {
  let items = [];
  
  return function(item) {
    if (item === undefined) return items;
    if (Array.isArray(item)) {
      items.push(...item);
    } else {
      items.push(item);
    }
    return items;
  };
}

const listCollector = createArrayCollector();
listCollector([1, 2, 3]);
listCollector(4);
console.log(listCollector()); // [1, 2, 3, 4]
```

### Promise-Based Collector
```javascript
function createPromiseCollector(promises) {
  let results = {};
  let completed = 0;
  
  return new Promise((resolve) => {
    promises.forEach((promise, index) => {
      promise.then(data => {
        results[index] = data;
        completed++;
        if (completed === promises.length) {
          resolve(results);
        }
      });
    });
  });
}

// Usage
const promises = [
  fetch('/api/user').then(r => r.json()),
  fetch('/api/settings').then(r => r.json()),
  fetch('/api/preferences').then(r => r.json())
];

createPromiseCollector(promises).then(allData => {
  console.log('All data collected:', allData);
});
```

### Statistics Collector
```javascript
function createStatsCollector() {
  let values = [];
  
  return function(value) {
    if (value === undefined) {
      return {
        values: [...values],
        count: values.length,
        sum: values.reduce((a, b) => a + b, 0),
        average: values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0,
        min: Math.min(...values),
        max: Math.max(...values)
      };
    }
    values.push(value);
    return values.length;
  };
}

const stats = createStatsCollector();
stats(10);
stats(20);
stats(30);
console.log(stats()); // { values: [10,20,30], count: 3, sum: 60, average: 20, min: 10, max: 30 }
```

## Gotchas & Notes

- **Memory**: Collector holds references to all collected data
- **Mutation**: Uses spread operator to avoid mutating original objects
- **Async Timing**: No built-in synchronization - caller must handle timing
- **Type Safety**: Consider validating data types before merging

## Related Snippets

- [[closure-function-factory]] - Function factory pattern
- [[closure-counter]] - Private state management
- [[promise-all-settled]] - Modern Promise-based data collection

## External Resources

- [MDN: Object Spread Syntax](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/Spread_syntax)
- [JavaScript Callback Patterns](https://nodejs.org/api/util.html#util_util_callbackify_original)

---

**Tags**: javascript, closures, data-collection, callbacks, async
**Difficulty**: intermediate
**Last Updated**: 2025-01-23