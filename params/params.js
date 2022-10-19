// when your source code changes, the computed etag and source_code_hash values will change as well. Terraform will update your S3 bucket object and Lambda function.
module.exports.handler = async (event) => {
  let responseMessage = 'no params have been sent';

  if (event.queryStringParameters && event.queryStringParameters['Name']) {
    responseMessage = 'Hi: ' + event.queryStringParameters['Name'];
  }

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: responseMessage,
    }),
  }
}
