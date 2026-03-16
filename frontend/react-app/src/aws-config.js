const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: '<COGNITO_USER_POOL_ID>',
      userPoolClientId: '<COGNITO_CLIENT_ID>',
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: '<API_GATEWAY_URL>'
  }
};

export default awsConfig;
