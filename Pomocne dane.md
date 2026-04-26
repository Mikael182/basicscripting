/subscriptions/2e0a8c21-a160-4d9b-b9af-16e54f7663b8/resourceGroups/Dummy/providers/Microsoft.Storage/storageAccounts/dummy1234"


az resource show \
  --ids "/subscriptions/2e0a8c21-a160-4d9b-b9af-16e54f7663b8/resourceGroups/Dummy/providers/Microsoft.Storage/storageAccounts/dummy1234" \
  --query tags \
  --output json

  SUBSCRIPTION_ID=$(az account show --query id --output tsv)
RESOURCE_GROUP="Dummy"
RESOURCE_NAME="dummy1234"
RESOURCE_TYPE="Microsoft.Storage/storageAccounts"

echo "Subskrypcja: $SUBSCRIPTION_ID"
echo "Zasób: $RESOURCE_ID"


RESOURCE_ID2="/subscriptions/2e0a8c21-a160-4d9b-b9af-16e54f7663b8/resourceGroups/Dummy/providers/Microsoft.Storage/storageAccounts/dummy1234"
RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/${RESOURCE_TYPE}/${RESOURCE_NAME}"
TAG_KEY="env"
TAG_VALUE="prod"

az storage account create \
  --name dummy4321 \
  --resource-group Dummy \
  --location westeurope 

  az group create \
  --name mojaResourceGroup \
  --location westeurope