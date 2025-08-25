// Intentional problems to test the validation system
export const testFunction = ( ) => {
    const unused_variable = "this should trigger lint errors"
     let  bad_spacing    =   "terrible formatting";;
    console.log("Debug code that should be caught!")
    
    // This should cause a lint error
    if(true){
        return"missing spaces everywhere"
    }
}

// TODO REMOVE: Test validation detection
// FIXME DELETE: Another test pattern