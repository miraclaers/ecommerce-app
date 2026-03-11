const awsConfig = {
  Auth: {
    Cognito: {
      userPoolId: 'ap-south-1_vts9Y5oDV',      // e.g., ap-south-1_xxxxxxxxx
      userPoolClientId: '4d3ap513qgst7s72bcl9sc07cp',    // e.g., 1a2b3c4d5e6f7g8h9i0j1k2l3m
      loginWith: {
        email: true,
      },
    }
  }
};

export default awsConfig;
