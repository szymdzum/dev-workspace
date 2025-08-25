---
type: resource
category: snippet
language: typescript
framework: react
created: 2025-01-23
modified: 2025-01-23
tags: [react, hooks, forms, validation, typescript, accessibility, custom-hooks]
difficulty: advanced
use-cases: [form-management, input-validation, accessibility, state-management]
source: "personal library"
---

# useInput - Advanced React Hook for Input Management

## Description

A comprehensive custom React hook that handles all aspects of input field management including state, validation, event handling, and accessibility. Features TypeScript generics for type safety and built-in ARIA support.

## Code

```typescript
/**
 * useInput.ts
 * A custom React hook for managing input state, validation, and event handling.
 */

import { type ChangeEvent, FocusEvent, useCallback, useState } from "react";

// Type for validator function
type Validator<T> = (value: T) => string | null;

// Type for hook return value
interface UseInputReturn<T> {
	value: T;
	setValue: (value: T) => void;
	error: string | null;
	isDirty: boolean;
	isTouched: boolean;
	isValid: boolean;
	reset: () => void;
	forceValidate: () => string | null;
	handleChange: (event: ChangeEvent<HTMLInputElement> | T) => void;
	handleBlur: () => void;
	inputProps: {
		value: T;
		onChange: (event: ChangeEvent<HTMLInputElement> | T) => void;
		onBlur: () => void;
		"aria-invalid": boolean;
		"aria-describedby"?: string;
	};
}

/**
 * Custom hook for input field state management and validation
 *
 * @param validator - Function that receives value and returns error message or null
 * @param initialValue - Initial value for the input
 * @returns Input state and event handlers
 */
function useInput<T>(
	validator?: Validator<T>,
	initialValue?: T,
): UseInputReturn<T> {
	// Core state
	const [value, setValue] = useState<T>(initialValue as T);
	const [isDirty, setIsDirty] = useState<boolean>(false);
	const [isTouched, setIsTouched] = useState<boolean>(false);
	const [error, setError] = useState<string | null>(null);

	/**
	 * Validate the input value
	 *
	 * @param valueToValidate - Value to validate
	 * @returns Error message or null if valid
	 */
	const validate = useCallback(
		(valueToValidate: T): string | null => {
			if (!validator) return null;

			try {
				return validator(valueToValidate);
			} catch (err) {
				console.error("Validation error:", err);
				return "Validation failed";
			}
		},
		[validator],
	);

	/**
	 * Run validation and update error state
	 *
	 * @param valueToValidate - Value to validate
	 * @returns Error message or null if valid
	 */
	const runValidation = useCallback(
		(valueToValidate: T): string | null => {
			const validationError = validate(valueToValidate);
			setError(validationError);
			return validationError;
		},
		[validate],
	);

	/**
	 * Handle input change event
	 *
	 * @param event - Input change event or direct value
	 */
	const handleChange = useCallback(
		(event: ChangeEvent<HTMLInputElement> | T) => {
			// Handle both event objects and direct values
			const newValue =
				event && typeof event === "object" && "target" in event
					? ((event.target as HTMLInputElement).value as unknown as T)
					: event;

			setValue(newValue);
			setIsDirty(true);

			// Only validate if the field has been touched
			if (isTouched) {
				runValidation(newValue);
			}
		},
		[isTouched, runValidation],
	);

	/**
	 * Handle input blur event
	 */
	const handleBlur = useCallback(() => {
		setIsTouched(true);
		runValidation(value);
	}, [value, runValidation]);

	/**
	 * Reset the input to initial state
	 */
	const reset = useCallback(() => {
		setValue(initialValue as T);
		setIsDirty(false);
		setIsTouched(false);
		setError(null);
	}, [initialValue]);

	/**
	 * Force validation regardless of touched state
	 *
	 * @returns Error message or null if valid
	 */
	const forceValidate = useCallback((): string | null => {
		setIsTouched(true);
		return runValidation(value);
	}, [value, runValidation]);

	return {
		// State
		value,
		setValue,
		error,
		isDirty,
		isTouched,
		isValid: isTouched && !error,

		// Methods
		reset,
		forceValidate,
		handleChange,
		handleBlur,

		// Props for input elements
		inputProps: {
			value,
			onChange: handleChange as (event: ChangeEvent<HTMLInputElement>) => void,
			onBlur: handleBlur,
			"aria-invalid": !!error,
			"aria-describedby": error ? `input-error` : undefined,
		},
	};
}

export default useInput;
```

## Usage Examples

### Basic Input with Validation
```typescript
import useInput from './useInput';

// Email validator
const validateEmail = (email: string): string | null => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email) return "Email is required";
  if (!emailRegex.test(email)) return "Invalid email format";
  return null;
};

function ContactForm() {
  const email = useInput(validateEmail, "");
  
  return (
    <div>
      <input 
        type="email"
        placeholder="Enter email"
        {...email.inputProps}
      />
      {email.error && (
        <span id="input-error" role="alert">
          {email.error}
        </span>
      )}
      <p>Valid: {email.isValid ? '✅' : '❌'}</p>
    </div>
  );
}
```

### Form with Multiple Inputs
```typescript
function UserForm() {
  const name = useInput(
    (value: string) => !value ? "Name is required" : null,
    ""
  );
  
  const age = useInput(
    (value: number) => value < 18 ? "Must be 18 or older" : null,
    0
  );

  const handleSubmit = () => {
    // Force validation on all fields
    const nameError = name.forceValidate();
    const ageError = age.forceValidate();
    
    if (!nameError && !ageError) {
      console.log({ name: name.value, age: age.value });
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input {...name.inputProps} placeholder="Name" />
      {name.error && <span>{name.error}</span>}
      
      <input 
        {...age.inputProps} 
        type="number" 
        placeholder="Age"
        onChange={(e) => age.handleChange(Number(e.target.value))}
      />
      {age.error && <span>{age.error}</span>}
      
      <button type="submit">Submit</button>
    </form>
  );
}
```

## Key Features

### 🎯 **State Management**
- `value` - Current input value
- `isDirty` - Has value changed from initial?  
- `isTouched` - Has user interacted with input?
- `isValid` - Is current value valid?
- `error` - Current validation error message

### 🔧 **Methods**
- `setValue(value)` - Programmatically set value
- `reset()` - Reset to initial state
- `forceValidate()` - Validate regardless of touched state
- `handleChange(event)` - Handle input change events
- `handleBlur()` - Handle input blur events

### ♿ **Accessibility**
- `aria-invalid` - Indicates validation state
- `aria-describedby` - Links to error message
- Screen reader compatible error handling

### 🎨 **Advanced Patterns**

#### Debounced Validation
```typescript
const debouncedValidator = useMemo(() => 
  debounce((value: string) => validateAsync(value), 300),
  []
);

const input = useInput(debouncedValidator, "");
```

#### Conditional Validation
```typescript
const conditionalValidator = (value: string, isRequired: boolean) => {
  if (isRequired && !value) return "Field is required";
  if (value && value.length < 3) return "Minimum 3 characters";
  return null;
};

const input = useInput(
  (value) => conditionalValidator(value, true),
  ""
);
```

## TypeScript Support

Fully typed with generics for any input value type:
```typescript
const stringInput = useInput<string>(validator, "");
const numberInput = useInput<number>(validator, 0);
const booleanInput = useInput<boolean>(validator, false);
```

## Performance Optimizations

- `useCallback` for all event handlers
- Validation only runs when needed (touched state)
- Minimal re-renders through proper state management

## Gotchas & Notes

- **Validation timing**: Only validates after field is touched (on blur)
- **Generic support**: Use TypeScript generics for type safety
- **Event handling**: Supports both React events and direct values
- **Error recovery**: Try/catch around validation prevents crashes
- **Accessibility**: Built-in ARIA support for screen readers

## Related Patterns

- [[react-form-patterns]] - Form management strategies
- [[react-validation-patterns]] - Validation approaches
- [[react-accessibility-patterns]] - A11y best practices

## External Resources

- [React Hook Patterns](https://reactpatterns.com/)
- [Web Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [TypeScript React Patterns](https://react-typescript-cheatsheet.netlify.app/)

---

**Assessment**: ⭐⭐⭐⭐⭐ Production-ready, comprehensive input management  
**Last Updated**: 2025-01-23
