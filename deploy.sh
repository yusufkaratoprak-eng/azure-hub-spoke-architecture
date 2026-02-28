#!/bin/bash

az deployment group create \
  --resource-group my-rg \
  --template-file infra/main.bicep \
  --parameters location=westeurope