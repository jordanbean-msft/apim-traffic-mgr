# apim-traffic-mgr

```shell
dotnet publish --configuration Release --output ./app/publish ./app
Compress-Archive -DestinationPath ./app.zip -Update ./app/publish/*
```

```shell
az functionapp deployment source config-zip -g rg-apimTrafficMgr-ussc-dev -n func-apimTrafficMgr-ussc-dev --src ./app.zip
```

```shell
 az deployment group create -g rg-apimTrafficMgr-ussc-dev --template-file ./infra/main.bicep --parameters ./infra/env/dev.parameters.json --parameters apiManagementServicePublisherName=jordanbean apiManagementServicePublisherEmail=jordanbean@microsoft.com
```
