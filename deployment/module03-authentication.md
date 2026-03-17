# Module 3: Authentication with Cognito

## Overview
Set up AWS Cognito User Pool for user authentication and authorization in the ecommerce application.

---

## 3.1 Create User Pool

### Step-by-Step Configuration

1. Go to **AWS Cognito Console** → **User pools** → **Create user pool**

2. **Define your application**: Select **Single-page application (SPA)**

3. **Name your application**: Enter `ecommerce-app` (or your preferred name)

4. **Configure options**:
   - **Options for sign-in identifiers**: Select **Email**
   - **Self-registration**: Enable
   - **Required attributes for sign-up**: Select **email** and **name**

5. **Add a return URL**: `https://yourdomain.com` (update this later with your CloudFront URL)

6. Click **Create user directory**

7. **Configure App Client Authentication**:
   - Go to your newly created User Pool → **App integration** tab → **App clients**
   - Click on your app client name
   - Under **Authentication flows**, enable:
     - **ALLOW_USER_PASSWORD_AUTH**
     - **ALLOW_USER_SRP_AUTH** 
     - **ALLOW_REFRESH_TOKEN_AUTH**
   - Click **Save changes**

### Save These Values
- **User Pool ID** (e.g., `ap-south-1_xxxxxxxxx`)
- **App Client ID** (e.g., `1a2b3c4d5e6f7g8h9i0j1k2l3m`)
- **Cognito Domain** (if you set up a custom domain)

You'll need these for:
- **Module 4:** Configuring microservices
- **Module 6:** Frontend deployment and configuration

---

## Next Steps
Proceed to **[Module 4: Container Deployment](./module04-backend-deployment.md)** to deploy the microservices to ECS.
