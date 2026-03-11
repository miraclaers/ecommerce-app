# Module 3: Authentication with Cognito

## Overview
Set up AWS Cognito User Pool for user authentication and authorization in the ecommerce application.

---

## 3.1 Create User Pool

### Step-by-Step Configuration

1. Go to **AWS Cognito Console** → **User pools** → **Create user pool**

2. **Configure sign-in experience:**
   - Cognito user pool sign-in options: **Email**
   - User name requirements: Keep defaults
   - Click **Next**

3. **Configure security requirements:**
   - Password policy: **Cognito defaults**
   - Multi-factor authentication: **No MFA** (for development)
   - User account recovery: **Enable self-service account recovery - Recommended**
   - Delivery method for user account recovery messages: **Email only**
   - Click **Next**

4. **Configure sign-up experience:**
   - Self-registration: **Enable self-registration**
   - Attribute verification and user account confirmation: **Allow Cognito to automatically send messages to verify and confirm - Recommended**
   - Attributes to verify: **Send email message, verify email address**
   - Required attributes: Select **name** and **email**
   - Click **Next**

5. **Configure message delivery:**
   - Email provider: **Send email with Cognito** (for development)
   - FROM email address: **no-reply@verificationemail.com** (default)
   - Click **Next**

6. **Integrate your app:**
   - User pool name: `ecommerce-user-pool`
   - Hosted authentication pages: **Use the Cognito Hosted UI**
   - Cognito domain: Choose **Use a Cognito domain**
   - Cognito domain: Enter a unique domain prefix (e.g., `ecommerce-app-yourname`)
   - Initial app client:
     - App type: **Public client**
     - App client name: `ecommerce-web-client`
     - Client secret: **Don't generate a client secret**
   - Allowed callback URLs: `https://yourdomain.com/` (update this later with your CloudFront URL)
   - Allowed sign-out URLs: `https://yourdomain.com/` (update this later with your CloudFront URL)
   - Advanced app client settings:
     - OAuth 2.0 grant types: **Authorization code grant**
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
