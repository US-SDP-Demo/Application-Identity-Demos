#!/bin/bash
TENANTID=$(az account show --query tenantId -o tsv)
RESOURCEGROUP=""
CLUSTERNAME=""
KEYVAULT=""
SECRETNAME="arbitrarySecret"

MICLIENTID=$(az identity create -g $RESOURCEGROUP -n demo-workload-identity --query clientId -o tsv)

sleep 30

KEYVAULT_ID=$(az keyvault show --name $KEYVAULT --query id -o tsv)
az role assignment create --assignee $MICLIENTID --role "Key Vault Secrets User" --scope $KEYVAULT_ID

export AKS_OIDC_ISSUER="$(az aks show -n "${CLUSTERNAME}" -g "${RESOURCEGROUP}" --query "oidcIssuerProfile.issuerUrl" -o tsv)"

az identity federated-credential create --name demoFederatedIdentity --identity-name demo-workload-identity --resource-group "${RESOURCEGROUP}" --issuer "${AKS_OIDC_ISSUER}" --subject system:serviceaccount:wiapps:wiapp-workloadidapp --audience api://AzureADTokenExchange

helm upgrade --install wiapp charts/workloadIdApp2 --set nameOverride=workloadidapp,azureWorkloadIdentity.tenantId=$TENANTID,azureWorkloadIdentity.clientId=$MICLIENTID,keyvaultName=$KEYVAULT,secretName=$SECRETNAME -n wiapps --create-namespace
