$rgName = 'app-svc-kv-ref-test'
$location = 'australiaeast'
$prefix = 'belstarr'
$myIp = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
$secret = '1234567890'
$adminUserObjectId = '57963f10-818b-406d-a2f6-6e758d86e259'
$linuxContainerName = 'belstarr/go-web-kv-env-linux:0.2.0'
$windowsContainerName = 'belstarr/go-web-kv-env-windows:0.2.0'

az group create --resource-group $rgName --location $location

az deployment group create `
    --resource-group $rgName `
    --name 'infra-deployment' `
    --template-file ./infra/deploy.bicep `
    --parameters allowedRemoteIpAddress=$myIp `
    --parameters secretValue=$secret `
    --parameters adminUserObjectId=$adminUserObjectId `
    --parameters prefix=$prefix `
    --parameters linuxContainerName=$linuxContainerName `
    --parameters windowsContainerName=$windowsContainerName
