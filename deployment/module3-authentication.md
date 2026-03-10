# Module 3: Authentication with Cognito

## Overview
Set up AWS Cognito User Pool for user authentication and authorization in the ecommerce application.

---

## 3.1 Create User Pool

### Basic Configuration

1. **Cognito Console → User Pools → Create user pool**

**Configure sign-in experience:**
2. **Cognito user pool sign-in options:** Email
3. **User name requirements:** Keep defaults
4. **Next**

**Configure security requirements:**
5. **Password policy:** Cognito defaults
6. **MFA:** No MFA (for development)
7. **User account recovery:** Enable self-service account recovery - Email only
8. **Next**

**Configure message delivery:**
9. **Email provider:** Send email with Cognito (for development)
10. **FROM email address:** no-reply@verificationemail.com (default)
11. **Next**

**Integrate your app:**
12. **User pool name:** `ecommerce-users`
13. **Use the Cognito Hosted UI:** No (we'll use custom authentication)
14. **Next**

**Review and create:**
15. **Review all settings**
16. **Create user pool**

---

## 3.2 Create App Client

### App Client Configuration

1. **Go to your user pool → App integration tab**
2. **Create app client**

**App client information:**
3. **App type:** Public client
4. **App client name:** `ecommerce-web-client`
5. **Client secret:** Don't generate a client secret

**Authentication flows:**
6. **ALLOW_USER_PASSWORD_AUTH** ✅
7. **ALLOW_REFRESH_TOKEN_AUTH** ✅
8. **ALLOW_USER_SRP_AUTH** ✅

9. **Create app client**

---

## 3.3 Note Configuration Values

From your User Pool, collect these values for later use:

### User Pool Information
- **User Pool ID:** `<region>_xxxxxxxxx` (from General settings)
- **User Pool ARN:** `arn:aws:cognito-idp:<region>:<account>:userpool/<pool-id>`

### App Client Information  
- **App Client ID:** `xxxxxxxxxxxxxxxxxxxxxxxxxx` (from App integration tab)

These values will be used in Module 4 when configuring the microservices and in Module 6 for frontend integration.

## Next Steps
Proceed to **[Module 4: Container Deployment](./module4-container-deployment.md)** to deploy the microservices to ECS.
