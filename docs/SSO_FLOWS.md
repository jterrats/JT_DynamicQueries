# SSO Flows with Salesforce and Azure

This document explains the two main SSO (Single Sign-On) flows with Salesforce Experience Cloud and Azure.

## 1. Salesforce as Identity Provider (IdP)

In this scenario, Salesforce acts as the identity provider that authenticates users for external applications (such as Azure).

```mermaid
sequenceDiagram
    participant User
    participant Azure as Azure (Service Provider)
    participant Salesforce as Salesforce Experience Cloud (IdP)

    Note over User,Salesforce: User attempts to access Azure

    User->>Azure: 1. Requests access to resource
    Azure->>User: 2. Redirects to Salesforce (SAML Request)

    Note over User,Salesforce: Authentication in Salesforce

    User->>Salesforce: 3. Accesses Experience Cloud login

    alt User not authenticated
        Salesforce->>User: 4a. Shows login screen
        User->>Salesforce: 4b. Enters credentials
        Salesforce->>Salesforce: 4c. Validates credentials
    else User already authenticated
        Note over Salesforce: Active session detected
    end

    Salesforce->>Salesforce: 5. Generates SAML Assertion
    Note right of Salesforce: Includes:<br/>- NameID<br/>- User attributes<br/>- Digital signature<br/>- Time validity

    Salesforce->>User: 6. Returns SAML Response (POST)
    User->>Azure: 7. Sends SAML Response

    Azure->>Azure: 8. Validates SAML Assertion
    Note right of Azure: Verifies:<br/>- Digital signature<br/>- Certificate<br/>- Time validity<br/>- Audience restriction

    alt Valid SAML
        Azure->>Azure: 9a. Creates session
        Azure->>User: 9b. Grants access to resource
        Note over User,Azure: ✓ User authenticated
    else Invalid SAML
        Azure->>User: 9c. Denies access
        Note over User,Azure: ✗ Authentication failed
    end
```

### Required Configuration in Salesforce (IdP):

1. **Connected App in Salesforce:**
   - Enable SAML
   - Configure Azure ACS URL
   - Define Entity ID
   - Configure SAML attributes to send

2. **Experience Cloud:**
   - Configure users and profiles
   - Enable SSO for external users
   - Define session policies

3. **Certificates:**
   - Generate self-signed certificate in Salesforce
   - Share public certificate with Azure

### Required Configuration in Azure (SP):

1. **Enterprise Application:**
   - Register Salesforce as IdP
   - Configure Single Sign-On with SAML
   - Import Salesforce public certificate
   - Map user attributes

---

## 2. Salesforce Experience Cloud as Service Provider (SP)

In this scenario, Salesforce Experience Cloud trusts Azure AD as the identity provider to authenticate users.

```mermaid
sequenceDiagram
    participant User
    participant ExperienceCloud as Salesforce Experience Cloud (SP)
    participant Azure as Azure AD (Identity Provider)

    Note over User,Azure: User attempts to access Experience Cloud

    User->>ExperienceCloud: 1. Requests access to community
    ExperienceCloud->>ExperienceCloud: 2. Detects SSO requirement

    Note over ExperienceCloud: Checks Authentication<br/>Configuration settings

    ExperienceCloud->>User: 3. Redirects to Azure AD (SAML Request)
    Note right of ExperienceCloud: SAML Request includes:<br/>- Issuer (Salesforce Entity ID)<br/>- ACS URL<br/>- Request ID<br/>- Timestamp

    User->>Azure: 4. Accesses Azure AD login

    alt User not authenticated in Azure
        Azure->>User: 5a. Shows Azure login screen
        User->>Azure: 5b. Enters credentials (Azure AD)
        Azure->>Azure: 5c. Validates against Azure Active Directory

        alt MFA enabled
            Azure->>User: 5d. Requests second factor
            User->>Azure: 5e. Completes MFA
        end
    else User already authenticated
        Note over Azure: Active Azure session detected
    end

    Azure->>Azure: 6. Generates SAML Assertion
    Note right of Azure: Includes:<br/>- NameID (email or username)<br/>- User attributes<br/>- Roles/Groups<br/>- Digital signature<br/>- Time validity

    Azure->>User: 7. Returns SAML Response (POST)
    User->>ExperienceCloud: 8. Sends SAML Response to ACS URL

    ExperienceCloud->>ExperienceCloud: 9. Validates SAML Assertion
    Note right of ExperienceCloud: Verifies:<br/>- Signature with Azure cert<br/>- Time validity<br/>- Audience = Salesforce Entity ID<br/>- InResponseTo = Request ID

    alt Valid SAML
        ExperienceCloud->>ExperienceCloud: 10a. Finds/creates user
        Note right of ExperienceCloud: Just-in-Time (JIT)<br/>Provisioning if<br/>enabled

        ExperienceCloud->>ExperienceCloud: 10b. Verifies permissions and profile

        alt User authorized
            ExperienceCloud->>ExperienceCloud: 11a. Creates Salesforce session
            ExperienceCloud->>User: 11b. Redirects to home page
            Note over User,ExperienceCloud: ✓ User authenticated in Experience Cloud
        else User not authorized
            ExperienceCloud->>User: 11c. Shows authorization error
            Note over User,ExperienceCloud: ✗ User without access
        end
    else Invalid SAML
        ExperienceCloud->>User: 10c. Shows authentication error
        Note over User,ExperienceCloud: ✗ Invalid or expired SAML
    end
```

### Required Configuration in Azure AD (IdP):

1. **Enterprise Application:**
   - Create new enterprise application
   - Configure SAML-based Sign-On
   - Configure Salesforce URLs:
     - Entity ID (Audience)
     - ACS URL (Reply URL)
   - Define attributes and claims to send
   - Assign users and groups

2. **Certificates:**
   - Generate certificate in Azure
   - Download public certificate (Base64)
   - Configure SAML signing

3. **Conditional Access (optional):**
   - Configure access policies
   - MFA requirements
   - Location-based access

### Required Configuration in Salesforce Experience Cloud (SP):

1. **Single Sign-On Settings:**
   - Create new SAML configuration
   - Import Azure metadata XML or configure manually:
     - Azure Entity ID
     - Azure Login URL
     - Azure Logout URL
   - Upload Azure public certificate
   - Configure User ID Location (NameID)
   - Select User ID Type (email, username, etc.)

2. **Authentication Configuration:**
   - Create new authentication configuration
   - Associate SSO Settings
   - Define as default authentication method

3. **Experience Cloud Configuration:**
   - In Experience Workspaces > Administration
   - Login & Registration > Authentication Configuration
   - Select created configuration
   - Enable Self-Registration (optional for JIT)

4. **Just-in-Time (JIT) Provisioning (optional):**
   - Configure SAML JIT Handler (Apex)
   - Define SAML attribute mapping to Salesforce fields
   - Configure default profile
   - Configure Account assignment

5. **Domain Configuration:**
   - My Domain must be enabled
   - Configure Authentication Configuration on domain

---

## Flow Comparison

| Aspect                     | Salesforce as IdP                      | Salesforce as SP                       |
| -------------------------- | -------------------------------------- | -------------------------------------- |
| **Identity provider**      | Salesforce                             | Azure AD                               |
| **User management**        | In Salesforce                          | In Azure AD                            |
| **Credentials**            | Salesforce database                    | Active Directory                       |
| **MFA**                    | Salesforce MFA                         | Azure MFA                              |
| **Provisioning**           | Manual or API                          | JIT or SCIM                            |
| **Use case**               | Employees access Azure from Salesforce | External users access Experience Cloud |
| **Certificate complexity** | Salesforce generates, Azure imports    | Azure generates, Salesforce imports    |

---

## Best Practices

### Security:

- ✓ Use certificates with minimum 2048 bits
- ✓ Rotate certificates regularly (every 1-2 years)
- ✓ Enable MFA in both scenarios
- ✓ Configure appropriate session policies
- ✓ Monitor failed login attempts
- ✓ Use HTTPS for all URLs

### SAML Attributes:

- ✓ Send only necessary attributes
- ✓ Use persistent NameID when possible
- ✓ Map roles/groups for authorization
- ✓ Include email as additional attribute

### Testing:

- ✓ Test with users of different profiles
- ✓ Validate error flow (incorrect credentials)
- ✓ Verify session timeouts
- ✓ Test logout (SLO - Single Logout)
- ✓ Validate in different browsers

### Troubleshooting:

- Debug logs in Salesforce (Setup > Security > Security Health Check)
- SAML Assertion Validator tools
- Network traces (browser developer tools)
- Azure AD Sign-in logs
- Salesforce Login History

---

## References

- [Salesforce SSO Implementation Guide](https://help.salesforce.com/s/articleView?id=sf.sso_about.htm)
- [Azure AD SAML SSO](https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/what-is-single-sign-on)
- [Experience Cloud External Identity](https://help.salesforce.com/s/articleView?id=sf.networks_external_identity.htm)
