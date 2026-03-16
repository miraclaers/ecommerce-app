const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: '<COGNITO_USER_POOL_ID>', // e.g., ap-south-1_xxxxxxxxx
      userPoolClientId: '<COGNITO_CLIENT_ID>', // e.g., 1a2b3c4d5e6f7g8h9i0j1k2l3m
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: '<API_GATEWAY_URL>' // e.g., https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com
  }
};

export default awsConfig;
