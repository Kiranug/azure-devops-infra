param (
    [string]$resourceGroupName,
    [string]$location,
    [string]$SubscriptionId,
    [string]$environment,
    [string]$templateDirPath = "E:\new_azure_infra\Template",
    [string]$parameterBaseDirPath = "E:\new_azure_infra\parameters",
    [string]$outputFilePath = "subnet-ids.json",
    [string]$loadBalancerName,
    [string]$backendPoolName,
    [string]$vmName,
    [string]$networkInterfaceName

)

# Function to log messages
function Log-Message {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )

    Write-Host "[$(Get-Date)] [$Type] $Message"
}

# Function to deploy ARM template
function Deploy-ARMTemplate {
    param(
        [string]$TemplateFilePath,
        [string]$ParameterFilePath,
        [string]$ResourceGroupName,
        [string]$Environment
    )

    try {
        $Deployment = New-AzResourceGroupDeployment `
            -ResourceGroupName "$ResourceGroupName-$Environment" `
            -TemplateFile $TemplateFilePath `
            -TemplateParameterFile $ParameterFilePath `
            -Mode Incremental `
            -ErrorAction Stop

        if ($Deployment.ProvisioningState -ne 'Succeeded') {
            throw "Failed to deploy ARM template: $($Deployment.Error.Message)"
        }

        Log-Message "ARM template deployed successfully."
    }
    catch {
        throw "Failed to deploy ARM template: $_"
    }
}

# Authenticate to Azure
Connect-AzAccount
Set-AzContext -Subscription $SubscriptionId

# Create the resource group if it doesn't exist
$ResourceGroupFullName = "$resourceGroupName-$environment"
if (-not (Get-AzResourceGroup -Name $ResourceGroupFullName -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $ResourceGroupFullName -Location $location
    Log-Message "Resource group '$ResourceGroupFullName' created successfully in location '$location'."
} else {
    Log-Message "Resource group '$resourceGroupName' already exists."
}

# Deploy the VNet
$vnetTemplateFilePath = Join-Path -Path $templateDirPath -ChildPath "vnet.json"
$vnetParametersFilePath = Join-Path -Path $parameterBaseDirPath -ChildPath "vnet-parameters-$environment.json"
Deploy-ARMTemplate -TemplateFilePath $vnetTemplateFilePath -ParameterFilePath $vnetParametersFilePath -ResourceGroupName $resourceGroupName -Environment $environment

# Deploy the Load Balancer
$lbTemplateFilePath = Join-Path -Path $templateDirPath -ChildPath "lb.json"
$lbParametersFilePath = Join-Path -Path $parameterBaseDirPath -ChildPath "lb-parameters-$environment.json"
Deploy-ARMTemplate -TemplateFilePath $lbTemplateFilePath -ParameterFilePath $lbParametersFilePath -ResourceGroupName $resourceGroupName -Environment $environment

# Deploy the NSG
$nsgTemplateFilePath = Join-Path -Path $templateDirPath -ChildPath "nsg.json"
$nsgParametersFilePath = Join-Path -Path $parameterBaseDirPath -ChildPath "nsg-parameters-$environment.json"
Deploy-ARMTemplate -TemplateFilePath $nsgTemplateFilePath -ParameterFilePath $nsgParametersFilePath -ResourceGroupName $resourceGroupName -Environment $environment


# Deploy the Virtual Machine
$vmTemplateFilePath = Join-Path -Path $templateDirPath -ChildPath "vm.json"
$vmParametersFilePath = Join-Path -Path $parameterBaseDirPath -ChildPath "vm-parameters-$environment.json"
Deploy-ARMTemplate -TemplateFilePath $vmTemplateFilePath -ParameterFilePath $vmParametersFilePath -ResourceGroupName $ResourceGroupFullName -Environment $environment


# Get the Load Balancer
$loadBalancer = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupFullName -Name $loadBalancerName

# Get the backend pool
$backendPool = $loadBalancer.BackendAddressPools | Where-Object { $_.Name -eq $backendPoolName }

# Get the VM network interface
$nic = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupFullName -Name $networkInterfaceName

# Ensure the backend pool is of the correct type
$backendPoolRef = [Microsoft.Azure.Commands.Network.Models.PSBackendAddressPool]$backendPool

# Update the NIC to include the backend pool
$nic.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($backendPoolRef)

# Set the NIC configuration
Set-AzNetworkInterface -NetworkInterface $nic

Write-Host "VM $vmName has been added to the backend pool $backendPoolName of the Load Balancer $loadBalancerName."