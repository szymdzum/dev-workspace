console.log('This should trigger our security handler!')

const apiKey = 'sk-test-123' // This should be flagged by security handler
const password = 'mypassword' // This should also be flagged

function testFunction() {
  return 'hello world'
}
