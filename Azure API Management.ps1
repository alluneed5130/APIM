
# Login to Azure 
Connect-AzAccount


# Create resource group
$resGroupName = "APIM-rg" # resource group name
$location = "EastUS"           # Azure region
New-AzResourceGroup -Name $resGroupName -Location $location

# Create NSGs 
$apimRule1 = New-AzNetworkSecurityRuleConfig -Name apim-in -Description "APIM inbound" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
    ApiManagement -SourcePortRange * -DestinationAddressPrefix VirtualNetwork -DestinationPortRange 3443
$apimNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resGroupName -Location $location -Name `
    "NSG-APIM" -SecurityRules $apimRule1



# Create subnet config for API-M
$apimsubnet = New-AzVirtualNetworkSubnetConfig -Name "apim-subnet" -NetworkSecurityGroup $apimNsg -AddressPrefix "10.0.20.0/24"

# Create VNET and assign subnets
$vnet = New-AzVirtualNetwork -Name "APTTEST-VNET" -ResourceGroupName $resGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $apimsubnet

# Assign subnet variables
$apimsubnetdata = $vnet.Subnets[0]


$apimVirtualNetwork = New-AzApiManagementVirtualNetwork -SubnetResourceId $apimSubnetData.Id

# Create an API-M service inside the VNET
$apimServiceName = "Give a name to your Gateway"                
$apimOrganization = "Your Company Name"          
$apimAdminEmail = "me@gmail.com" 
$apimService = New-AzApiManagement -ResourceGroupName $resGroupName -Location $location -Name $apimServiceName -Organization $apimOrganization -AdminEmail $apimAdminEmail -VirtualNetwork $apimVirtualNetwork -VpnType "Internal" -Sku "Developer"


# Specify cert configuration
$gatewayHostname = "Tec.domain.com"                            
$portalHostname = "developer.domain.com"                         
$managementHostname = "management.domain.com"                  
$gatewayCertPfxPath = "PFX SSL Certificate Path"             
$portalCertPfxPath = "PFX SSL Certificate Path"           
$managementCertPfxPath = "PFX SSL Certificate Path"  
$gatewayCertPfxPassword = "SSL Certificate Password"       
$portalCertPfxPassword = "SSL Certificate Password"       
$managementCertPfxPassword = "SSL Certificate Password"
    
$certGatewayPwd = ConvertTo-SecureString -String $gatewayCertPfxPassword -AsPlainText -Force
$certPortalPwd = ConvertTo-SecureString -String $portalCertPfxPassword -AsPlainText -Force
$certManagementPwd = ConvertTo-SecureString -String $managementCertPfxPassword -AsPlainText -Force

# Create and set the hostname configuration objects for the proxy and portal

$gatewayHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $gatewayHostname `
  -HostnameType Proxy -PfxPath $gatewayCertPfxPath -PfxPassword $certGatewayPwd

$portalHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $portalHostname `
  -HostnameType DeveloperPortal -PfxPath $portalCertPfxPath -PfxPassword $certPortalPwd

$managementHostnameConfig = New-AzApiManagementCustomHostnameConfiguration -Hostname $managementHostname `
 -HostnameType Management -PfxPath $managementCertPfxPath -PfxPassword $certManagementPwd

$apim = Get-AzApiManagement
$apim.ProxyCustomHostnameConfiguration = $gatewayHostnameConfig
$apim.PortalCustomHostnameConfiguration = $portalHostnameConfig
$apim.ManagementCustomHostnameConfiguration = $managementHostnameConfig

Set-AzApiManagement -InputObject $apim






