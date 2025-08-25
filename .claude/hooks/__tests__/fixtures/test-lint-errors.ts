// Test file with intentional ESLint violations
export function badFunction(   ) {
var unused_variable = "this should cause lint errors";
  console.log('missing semicolon')
  
  
  let x=1+2+3 // no spaces around operators
  
  if(true){
return x // wrong indentation and missing semicolon
  }
}

// More lint violations
export const arrow_function_with_bad_naming = () => {
 const another_bad_name="test"
    return another_bad_name;
}