# Define your parameters
$resourceGroupName = "mynewrg"
$location = "eastus"
$SubscriptionId = "6b06bb66-681d-44da-8a5c-75d27eba8d1d"
$environment = "dev"
$loadBalancerName = "myLoadBalancer-dev"
$backendPoolName = "BackendPool"
$vmName = "myVM"
$networkInterfaceName = "myVM-nic"
# Run the script with parameters
& "E:\new_azure_infra\Scripts\deploy-vnet.ps1" -resourceGroupName $resourceGroupName -location $location -SubscriptionId $SubscriptionId -environment $environment -loadBalancerName $loadBalancerName -backendPoolName $backendPoolName -vmName $vmName -networkInterfaceName $networkInterfaceName
