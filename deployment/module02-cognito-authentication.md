# Module 2: Authentication with Cognito

## Overview
Set up AWS Cognito User Pool and App Client for user authentication and authorization.

## In this module
- Create Cognito User Pool
- Configure Cognito User Pool App Client

## 2.1 Create User Pool

1. Go to **AWS Cognito Console** → **User pools** → **Create user pool**

2. **Define your application**: Select **Single-page application (SPA)**

3. **Name your application**: Enter `ecommerce-app` (or your preferred name)

4. **Configure options**:
   - **Options for sign-in identifiers**: Select **Email**
   - **Self-registration**: Enable
   - **Required attributes for sign-up**: Select **email** and **name**

5. **Add a return URL**: `https://yourdomain.com` (If you have your domain name, add it here otherwise leave it blank)

6. Click **Create user directory**

## 2.2 Configure Cognito User Pool App Client
- Go to your newly created User Pool → **App integration** tab → **App clients**
- Click on your app client name and Edit
- Under **Authentication flows**, enable:
  - **ALLOW_USER_PASSWORD_AUTH**
  - **ALLOW_USER_SRP_AUTH** 
  - **ALLOW_REFRESH_TOKEN_AUTH**
- Click **Save changes**

## Save These Values
Copy and save following values somewhere in notepad
- **User Pool ID** (e.g., `ap-south-1_xxxxxxxxx`)
- **App Client ID** (e.g., `1a2b3c4d5e6f7g8h9i0j1k2l3m`)
- **Cognito Domain** (User Pool -> Branding -> Domain)

You'll need these for:
- **Module 3:** Frontend deployment


## Next Steps
Proceed to **[Module 3: Frontend Deployment](./module03-frontend-deployment.md)**
