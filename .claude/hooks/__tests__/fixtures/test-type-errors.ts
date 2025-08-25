// Test file with intentional TypeScript errors
export interface BadInterface {
  name: string;
  age: number;
}

export function typeErrorFunction(user: BadInterface): string {
  // Type error: accessing property that doesn't exist
  return user.email; // Property 'email' does not exist on type 'BadInterface'
}

export function anotherTypeError(): number {
  // Type error: returning string when number expected
  return "this is a string"; // Type 'string' is not assignable to type 'number'
}

export class BadClass {
  private name: string;
  
  constructor(name: string) {
    // Type error: assigning number to string property
    this.name = 123; // Type 'number' is not assignable to type 'string'
  }
  
  public getName(): string {
    // Type error: this.name is private but we're accessing it incorrectly
    return this.nonExistentProperty; // Property 'nonExistentProperty' does not exist
  }
}