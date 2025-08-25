---
type: resource
category: reference
language: javascript
series: javascript-array-methods
series-order: 7
created: 2025-01-23
modified: 2025-01-23
tags: [javascript, pipeline-operator, functional-programming, experimental, reference]
---

# JavaScript Pipeline Operator: A Beginner-Friendly Tutorial

## Introduction

If you enjoy using method chaining in JavaScript (like `array.filter().map().reduce()`), you'll love the pipeline operator! This tutorial explores the proposed `|>` pipeline operator that could make your code more readable and flexible.

Currently, this is a Stage 2 TC39 proposal, which means it isn't part of standard JavaScript yet, but you can try it using Babel.

## What You'll Learn
- What method chaining is and how it works behind the scenes
- How to use the pipeline operator with two different syntax proposals
- How to set up your environment to try the pipeline operator today
- Practical examples comparing traditional chaining to the pipeline approach

## Understanding Method Chaining

Before diving into the pipeline operator, let's understand method chaining, which is a common pattern in JavaScript.

### Method Chaining Example

```javascript
const numbers = [5, 10, 15, 20, 25, 30];

// Using method chaining
const result = numbers
  .filter(n => n >= 10)     // Keep numbers 10 or higher
  .map(n => n * 2)          // Double each number
  .reduce((sum, n) => sum + n, 0);  // Sum all numbers

console.log(result); // 300 (10+15+20+25+30 = 100, then doubled = 200, then summed = 300)
```

### How Method Chaining Works Behind the Scenes

When you chain methods, JavaScript creates temporary arrays at each step:

```javascript
const numbers = [5, 10, 15, 20, 25, 30];

// Step 1: Filter creates a temporary array
const temp1 = numbers.filter(n => n >= 10);
// temp1 = [10, 15, 20, 25, 30]

// Step 2: Map creates another temporary array
const temp2 = temp1.map(n => n * 2);
// temp2 = [20, 30, 40, 50, 60]

// Step 3: Reduce combines the values
const result = temp2.reduce((sum, n) => sum + n, 0);
// result = 200

console.log(result); // 200
```

Understanding these temporary arrays is key to understanding how the pipeline operator works.

## The Pipeline Operator: Two Proposals

There are two competing syntax proposals for the pipeline operator: F# style and Hack style.

### 1. F# Style Pipeline Operator

The F# style uses unary functions (functions that take exactly one argument) at each step.

```javascript
const numbers = [5, 10, 15, 20, 25, 30];

const result = numbers
  |> (x => x.filter(n => n >= 10))
  |> (x => x.map(n => n * 2))
  |> (x => x.reduce((sum, n) => sum + n, 0));

console.log(result); // 200
```

In this approach, each step is a function that:
- Takes the output from the previous step
- Processes it
- Returns a result for the next step

#### Adding Debugging with F# Style

One advantage of the pipeline operator is easily adding debugging:

```javascript
const numbers = [5, 10, 15, 20, 25, 30];

// Define a debug function
const printIt = x => {
  console.log(x);
  return x;  // Important: return the input to continue the pipeline
};

const result = numbers
  |> (x => x.filter(n => n >= 10))
  |> printIt  // Log the filtered array
  |> (x => x.map(n => n * 2))
  |> printIt  // Log the mapped array
  |> (x => x.reduce((sum, n) => sum + n, 0));

console.log(result); // 200
```

### 2. Hack Style Pipeline Operator

The Hack style uses a special "topic" marker (commonly `%`) to represent the input at each step.

```javascript
const numbers = [5, 10, 15, 20, 25, 30];

const result = numbers
  |> %.filter(n => n >= 10)
  |> %.map(n => n * 2)
  |> %.reduce((sum, n) => sum + n, 0);

console.log(result); // 200
```

In this approach:
- `%` represents the value coming through the pipeline at each step
- You use it directly in expressions without creating wrapper functions

#### Adding Debugging with Hack Style

Debugging with the Hack style requires a comma expression trick:

```javascript
const numbers = [5, 10, 15, 20, 25, 30];

const result = numbers
  |> %.filter(n => n >= 10)
  |> (console.log(%), %)  // Log then return % to continue the pipeline
  |> %.map(n => n * 2)
  |> (console.log(%), %)  // Log then return % again
  |> %.reduce((sum, n) => sum + n, 0);

console.log(result); // 200
```

The comma expression `(console.log(%), %)` does two things:
1. Logs the current value
2. Returns the value itself as the result of the expression

## Setting Up Your Environment to Try Pipeline Operators

You can experiment with the pipeline operator using Babel. Here's how to set it up:

### Step 1: Install Required Packages

```bash
npm install --save-dev @babel/core @babel/cli @babel/preset-env
npm install --save-dev @babel/plugin-proposal-pipeline-operator
```

### Step 2: Configure Babel for F# Style

Create a `.babelrc` file:

```json
{
  "plugins": [
    ["@babel/plugin-proposal-pipeline-operator", { "proposal": "fsharp" }]
  ]
}
```

### Step 3: Configure Babel for Hack Style

For the Hack style, modify your `.babelrc` file:

```json
{
  "plugins": [
    ["@babel/plugin-proposal-pipeline-operator", { "proposal": "hack", "topicToken": "%" }]
  ]
}
```

### Step 4: Use with Quokka (Optional)

If you're using the Quokka.js VS Code extension for interactive JavaScript evaluation:

1. Open Quokka settings
2. Set the transpiler to "Babel"
3. Quokka will use your Babel configuration

## Practical Examples

### Example 1: Data Processing Pipeline

```javascript
// Sample data
const users = [
  { name: "Alice", age: 25, active: true },
  { name: "Bob", age: 17, active: false },
  { name: "Charlie", age: 32, active: true },
  { name: "David", age: 15, active: true },
  { name: "Eve", age: 28, active: false }
];

// Traditional method chaining
const activeAdultNames = users
  .filter(user => user.active)
  .filter(user => user.age >= 18)
  .map(user => user.name)
  .join(", ");

console.log(activeAdultNames); // "Alice, Charlie"

// Using F# style pipeline
const activeAdultNamesF = users
  |> (x => x.filter(user => user.active))
  |> (x => x.filter(user => user.age >= 18))
  |> (x => x.map(user => user.name))
  |> (x => x.join(", "));

console.log(activeAdultNamesF); // "Alice, Charlie"

// Using Hack style pipeline
const activeAdultNamesHack = users
  |> %.filter(user => user.active)
  |> %.filter(user => user.age >= 18)
  |> %.map(user => user.name)
  |> %.join(", ");

console.log(activeAdultNamesHack); // "Alice, Charlie"
```

### Example 2: Using with Custom Functions

The pipeline operator really shines when mixing array methods with custom functions:

```javascript
// Custom functions
const removeInactive = users => users.filter(user => user.active);
const filterMinors = users => users.filter(user => user.age >= 18);
const extractNames = users => users.map(user => user.name);
const formatList = names => names.join(", ");

// Traditional approach (nested calls - read from inside out)
const result = formatList(extractNames(filterMinors(removeInactive(users))));
console.log(result); // "Alice, Charlie"

// Using F# style pipeline (more readable left-to-right)
const resultF = users
  |> removeInactive
  |> filterMinors
  |> extractNames
  |> formatList;

console.log(resultF); // "Alice, Charlie"

// Using Hack style pipeline
const resultHack = users
  |> removeInactive(%)
  |> filterMinors(%)
  |> extractNames(%)
  |> formatList(%);

console.log(resultHack); // "Alice, Charlie"
```

## Comparison of Approaches

| Approach | Pros | Cons |
|----------|------|------|
| Method Chaining | - Built into JavaScript<br>- Familiar to most developers | - Limited to methods on the object<br>- Difficult to debug intermediate steps |
| F# Style Pipeline | - Works with any unary function<br>- Easy to add debugging steps | - More verbose for simple method calls<br>- Requires wrapper functions |
| Hack Style Pipeline | - More concise<br>- Clearer with the topic token | - Topic token syntax might be confusing<br>- Requires comma expressions for debugging |

## Current Status and Future

As of the time of this tutorial, the pipeline operator is a Stage 2 TC39 proposal, meaning:

- It's not part of standard JavaScript yet
- The final syntax might change
- The Hack style proposal seems to be gaining more support

Keep an eye on the [TC39 proposals repository](https://github.com/tc39/proposals) for updates on its status.

## Conclusion

The pipeline operator provides a more flexible and potentially more readable alternative to traditional method chaining. While it's not standard JavaScript yet, you can start experimenting with it today using Babel.

Whether you prefer the F# style or Hack style largely comes down to personal preference, but both offer powerful ways to make your data processing code more linear and easier to follow.

## Resources

- [TC39 Pipeline Operator Proposal](https://github.com/tc39/proposal-pipeline-operator)
- [Babel Plugin Documentation](https://babeljs.io/docs/en/babel-plugin-proposal-pipeline-operator)
- [F# Pipeline Operator Documentation](https://docs.microsoft.com/en-us/dotnet/fsharp/language-reference/symbol-and-operator-reference/index)
- [Hack Pipe Proposal Repository](https://github.com/js-choi/proposal-hack-pipes)
