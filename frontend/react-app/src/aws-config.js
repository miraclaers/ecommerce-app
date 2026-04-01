const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'us-west-2_k8LW01rVS', // e.g., ap-south-1_xxxxxxxxx
      userPoolClientId: '36s9l952auhtit45h6rcgb7seg', // e.g., 1a2b3c4d5e6f7g8h9i0j1k2l3m
      loginWith: {
        email: true,
      },
    }
  },
  API: {
    baseUrl: 'https://q3sy15kjs8.execute-api.us-west-2.amazonaws.com' // e.g., https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com
  }
};

export default awsConfig;
