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
     - ✅ **ALLOW_USER_PASSWORD_AUTH**
     - ✅ **ALLOW_USER_SRP_AUTH** 
     - ✅ **ALLOW_REFRESH_TOKEN_AUTH**
   - Click **Save changes**

This automatically creates both the User Pool and App Client. Note down:
- **User Pool ID** (e.g., `ap-south-1_xxxxxxxxx`)
- **App Client ID** (e.g., `1a2b3c4d5e6f7g8h9i0j1k2l3m`)
- **Cognito Domain** (if you set up a custom domain)
     - OpenID Connect scopes: **OpenID, Email, Profile**
     - Authentication flows: Enable the following:
       - ✅ **ALLOW_USER_PASSWORD_AUTH**
       - ✅ **ALLOW_USER_SRP_AUTH**
       - ✅ **ALLOW_REFRESH_TOKEN_AUTH**
   - Click **Next**

7. **Review and create:**
   - Review all settings
   - Click **Create user pool**

---

## 3.2 Note Configuration Values

After creating the user pool, collect these values:

### User Pool Information
1. Go to **User pool overview**
2. **User Pool ID:** Copy the value (format: `<region>_xxxxxxxxx`)
3. **User Pool ARN:** Copy the ARN (format: `arn:aws:cognito-idp:<region>:<account>:userpool/<pool-id>`)

### App Client Information  
1. Go to **App integration** tab → **App client list**
2. Click on `ecommerce-web-client`
3. **App Client ID:** Copy the Client ID

### Cognito Domain
1. Go to **App integration** tab → **Domain**
2. **Cognito domain:** Note your domain (format: `https://<your-prefix>.auth.<region>.amazoncognito.com`)

### Save These Values
You'll need these for:
- **Module 4:** Configuring microservices
- **Module 6:** Frontend deployment and configuration

---

## 3.3 Update Callback URLs (After Frontend Deployment)

After deploying your frontend in Module 6, you'll need to update the callback URLs:

1. Go to **App integration** tab → **App client list**
2. Click on `ecommerce-web-client`
3. Click **Edit**
4. Update:
   - **Allowed callback URLs:** Add your CloudFront URL (e.g., `https://d1234567890.cloudfront.net/`)
   - **Allowed sign-out URLs:** Add your CloudFront URL
5. **Save changes**

---

## Next Steps
Proceed to **[Module 4: Container Deployment](./module4-container-deployment.md)** to deploy the microservices to ECS.
