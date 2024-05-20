{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "location": {
            "type": "string"
        },
        "loadBalancerName": {
            "type": "string"
        },
        "subnetId": {
            "type": "string"
        }
    },
    "resources": [
        {
            "type": "Microsoft.Network/loadBalancers",
            "apiVersion": "2019-11-01",
            "location": "[parameters('location')]",
            "name": "[parameters('loadBalancerName')]",
            "properties": {
                "frontendIPConfigurations": [
                    {
                        "name": "PublicIPAddress",
                        "properties": {
                            "publicIPAddress": {
                                "id": "[variables('publicIPAddressId')]"
                            }
                        }
                    }
                ],
                "backendAddressPools": [
                    {
                        "name": "BackendPool"
                    }
                ]
            }
        },
        {
            "type": "Microsoft.Network/publicIPAddresses",
            "apiVersion": "2019-11-01",
            "location": "[parameters('location')]",
            "name": "[concat(parameters('loadBalancerName'), '-ip')]",
            "properties": {
                "publicIPAllocationMethod": "Dynamic"
            }
        },
        {
            "type": "Microsoft.Network/loadBalancers/backendAddressPools",
            "apiVersion": "2019-11-01",
            "dependsOn": [
                "[resourceId('Microsoft.Network/loadBalancers', parameters('loadBalancerName'))]"
            ],
            "name": "[concat(parameters('loadBalancerName'), '/BackendPool')]",
            "properties": {
                "backendAddresses": []
            }
        },
        {
            "type": "Microsoft.Network/loadBalancers/inboundNatRules",
            "apiVersion": "2019-11-01",
            "dependsOn": [
                "[resourceId('Microsoft.Network/loadBalancers', parameters('loadBalancerName'))]"
            ],
            "name": "[concat(parameters('loadBalancerName'), '/NatRuleSSH')]",
            "properties": {
                "frontendIPConfiguration": {
                    "id": "[variables('frontEndIPConfigId')]"
                },
                "protocol": "Tcp",
                "frontendPort": 22,
                "backendPort": 22,
                "enableFloatingIP": false,
                "idleTimeoutInMinutes": 15
            }
        }
    ],
    "variables": {
        "publicIPAddressId": "[resourceId('Microsoft.Network/publicIPAddresses', concat(parameters('loadBalancerName'), '-ip'))]",
        "frontEndIPConfigId": "[resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', parameters('loadBalancerName'), 'PublicIPAddress')]"
    }
}
