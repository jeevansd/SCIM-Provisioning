# Testing SCIM Provisioning in your test tenant steps

Because this application is published for only testing purposes in Production and the Provisioning is not enabled in UserInterface, we are providing the steps to Configure SCIM provisioning using MS Graph APIs. Once your testing is complete and then we publish the application for all our customers then customers can see the User Provisioning Option in the App Gallery for this app.

The following are the steps to create the job using the Graph API and configure provisioning for ZIdentity endpoint.

You can only use the test tenants which you have provided to us and we have whitelisted only those tenants for testing. Perfor the following steps in the test tenant for testing the provisioning application.

## 1. Create a Entra ID App Gallery Application

- Navigate to Azure Portal > Entra ID > Enterprise Applications.
- Click on create New Application
- This will take you to the App Gallery, search for your application here
- Create a gallery application
- This will create a new application in your tenant and will take you to Overview page in Enterprise Application
- Capture the Object ID (ServicePrincipal) from Overview page.

## 2. Configuration Methods

There are two ways to configure the synchronization job for your connector:

- **Method 1: PowerShell** - This method uses the Microsoft.Graph PowerShell module for a streamlined experience.
- **Method 2: Graph Explorer** - This method uses the web-based Graph Explorer for direct API calls.

## Method 1: PowerShell Configuration

1. Install PowerShell 7.X on your machine and then make sure that you have a Cloud Application Administrator role in your Entra ID tenant so that you can add the SCIM Provisioning for your application.

2. Create a synchronization job using Microsoft.Graph PowerShell module. Use the script given below.

> [!Note] 
> Template ID will be provided by Microsoft team for your application and you have to use that template id here in the script.

```powershell
Install-Module -Name Microsoft.Graph
Connect-MgGraph -TenantId "<YourTenantId>" -Scopes "Synchronization.ReadWrite.All"
$templateId = "<TemplateID_Provided_by_Microsoft>"
$servicePrincipalId = "<objectId>" # You can get it from Overview page
$params = @{  templateId = $templateId }
New-MgServicePrincipalSynchronizationJob -ServicePrincipalId $servicePrincipalId -BodyParameter $params
```

Configure Synchronization Secrets (Optional): 
Note: This step is only required if the gallery application doesn't provide fields for 
OAuth2 client credentials in the provisioning configuration UI. Most gallery applications 
include these fields, but if they're not available, use the Graph API approach below.

### Add OAuth2 Client Credentials using PowerShell

```PowerShell
$servicePrincipalId = "<objectId>" # Same as above 
$params = @{ 
    value = @( 
        @{ 
            key = "BaseAddress" 
            value = "<Base_Address_URL_for_SCIM>" 
        } 
        @{ 
            key = "AuthenticationType" 
            value = "OAuth2ClientCredentialsGrant" 
        } 
        @{ 
            key = "Oauth2TokenExchangeUri" 
            value = "<Your_Application_SCIM_OAuth2_Token_URL>" 
        } 
        @{ 
            key = "Oauth2ClientId" 
            value = "<Your-client-id>"  # Replace with actual client ID 
        } 
        @{ 
            key = "Oauth2ClientSecret" 
            value = "<Your-client-secret>"  # Replace with actual client secret 
        } 
       @{ 
            key = "SyncNotificationSettings" 
            value = '{"Enabled":false,"DeleteThresholdEnabled":false}' 
} 
@{ 
key = "SyncAll" 
value = "false" 
} 
) 
} 
Set-MgServicePrincipalSynchronizationSecret -ServicePrincipalId $servicePrincipalId 
BodyParameter $params 
```
## Method 2: Graph Explorer Configuration

1. Navigate to Graph Explorer using link https:/aka.ms/GE 
2. Sign in with an account that has appropriate permissions in your tenant
3. Use the following POST request to create a synchronization job:

```JSON
HTTP Method: POST

URL:https://graph.microsoft.com/v1.0/servicePrincipals/{servicePrincipalId}/synchr
onization/jobs

Request Headers: Content-Type: application/json 
Request Body:
{ 
"templateId": "<Template_ID_Provided_by_Microsoft>" 
} 
```

4. Configure Synchronization Secrets (Optional): 
Note: This step is only required for the gallery applications which still doesn't 
provide fields for OAuth2 client credentials in the provisioning configuration UI. Then you have to use the Graph API approach below.

```JSON
HTTP Method: PUT

URL: 
https://graph.microsoft.com/v1.0/servicePrincipals/{servicePrincipalId}/synchroniz
ation/secrets

Request Headers: Content-Type: application/json 

Request Body: 
{ 
    "value": [ 
        { 
            "key": "BaseAddress", 
            "value": "<Your_Base_Address_URL>" // Replace with actual Base address URL of your application
        }, 
        { 
            "key": "AuthenticationType", 
            "value": "OAuth2ClientCredentialsGrant" 
        }, 
        { 
            "key": "Oauth2TokenExchangeUri", 
            "value": "<Your_application_token_endpoint_URL>" // Replace with actual token URL
        }, 
        { 
            "key": "Oauth2ClientId", 
            "value": "<Your-client-id>"  // Replace with actual client ID 
        }, 
        { 
            "key": "Oauth2ClientSecret", 
            "value": "your-client-secret"  // Replace with actual client secret 
        }, 
        { 
            "key": "SyncNotificationSettings", 
             "value": "{\"Enabled\":false,\"DeleteThresholdEnabled\":false}" 
        }, 
        { 
            "key": "SyncAll", 
            "value": "false" 
        } 
    ] 
} 
```

## References:  
- Create synchronizationJob - Microsoft Graph v1.0 | Microsoft Learn 
- Graph Explorer | Try Microsoft Graph APIs - Microsoft Graph 
- Add synchronization secrets - Microsoft Graph v1.0 | Microsoft Learn

## Setting AppRoles for your application (Optional)

Some of the applications do not have AppRoles vs some of them do have AppRoles and so you need to assign AppRoles to the application created.

1. Go to App Registrations -> All Applications. Filter the gallery application you created and enabled for provisioning.
2. Go to App Roles -> Create AppRole -> Add User App Role.
3. Select Allowed Member Type as User and Group
4. Provide the name for the AppRole and assign a value and provide description
5. Return to the Enterprise application > Provisioning -> StartProvisioning.
6. Verify Provisioning Mode = Automatic and the TestConnection is success.
7. Add Users / Groups to provision.

> [!Note] 
> To assign Groups to the application, Entra ID P1 license is required for the test tenant.

Once successful validation is confirmed, please communicate back to Microsoft and contact and then they will proceed to enable provisioning across all tenants and release updates to the frontend. That way UI option will be available for all our customers to enable user provisioning.