#!/bin/bash

# Initializing vault
init_output=$(kubectl exec vault-0 --kubeconfig="../kubeconfig" -- vault operator init -key-shares=1 -key-threshold=1 -format=json)
echo "Initialized"
echo "---"

unseal_key=$(echo $init_output | jq -r '.unseal_keys_b64[0]')
root_token=$(echo $init_output | jq -r '.root_token')
echo "unseal key: $unseal_key"
echo "root token: $root_token"
echo "---"

#Unseal the vault
kubectl exec vault-0 --kubeconfig="../kubeconfig" -- vault operator unseal $unseal_key
echo "---"

#Print status
kubectl exec vault-0  --kubeconfig="../kubeconfig" -- vault status
echo "---"

# Login vault
kubectl exec vault-0  --kubeconfig="../kubeconfig" -- vault login $root_token
kubectl exec vault-0  --kubeconfig="../kubeconfig" -- vault operator raft list-peers
echo "---"

# Joining nodes
kubectl exec vault-1  --kubeconfig="../kubeconfig" -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec vault-1  --kubeconfig="../kubeconfig" -- vault operator unseal $unseal_key

echo "---"
kubectl exec vault-2  --kubeconfig="../kubeconfig" -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec vault-2  --kubeconfig="../kubeconfig" -- vault operator unseal $unseal_key
echo "---"

kubectl exec vault-0  --kubeconfig="../kubeconfig" -- vault operator raft list-peers

# Enable kv secrets engine
kubectl exec vault-0  --kubeconfig="../kubeconfig" -- vault secrets enable -version=2 kv

# Enabling k8s auth method
kubectl exec vault-0  --kubeconfig="../kubeconfig" -- vault auth enable kubernetes
kubectl exec vault-0  --kubeconfig="../kubeconfig" -- vault write auth/kubernetes/config kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

echo "---"
echo "unseal key: $unseal_key"
echo "root token: $root_token"