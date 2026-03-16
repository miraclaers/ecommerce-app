const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'your-region_xxxxxxxxx',      // e.g., ap-south-1_xxxxxxxxx
      userPoolClientId: 'your-client-id',    // e.g., 1a2b3c4d5e6f7g8h9i0j1k2l3m
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: 'https://your-api-id.execute-api.your-region.amazonaws.com'
  }
};

export default awsConfig;
