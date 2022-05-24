# apim-traffic-mgr

```shell
$dirToExclude=@('bin', 'obj', '.vscode')
Get-ChildItem -Path . -Exclude $dirToExclude | Compress-Archive -DestinationPath ../application.zip -Update
```

```shell
az deployment group create -g rg-apimTrafficMgr-ussc-dev --template-file ./infra/main.bicep --parameters ./infra/env/dev.parameters.json --parameters apiManagementServicePublisherName=jordanbean apiManagementServicePublisherEmail=jordanbean@microsoft.com
```
