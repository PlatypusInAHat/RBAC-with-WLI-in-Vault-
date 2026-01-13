#!/bin/bash
# Vault setup script for K8s demo
# This script configures Vault with policies and roles for workload identity

set -e

echo "🔐 Setting up Vault for K8s Workload Identity..."

# Vault address
VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"

export VAULT_ADDR
export VAULT_TOKEN

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Enabling KV secrets engine...${NC}"
vault secrets enable -path=secret kv-v2 || echo "KV engine already enabled"

echo -e "${BLUE}Step 2: Creating demo secrets...${NC}"

# Backend secrets
vault kv put secret/bloodbank/backend \
  jwt_secret="demo-jwt-secret-key-2024" \
  api_key="11102004"

# Frontend secrets  
vault kv put secret/bloodbank/frontend \
  api_key="11102004" \
  next_public_api_url="http://backend-internal.bloodbank.svc.cluster.local:3000"

# Database secrets
vault kv put secret/bloodbank/database \
  username="postgres" \
  password="bloodbank2024secure" \
  host="postgres.bloodbank.svc.cluster.local" \
  port="5432" \
  database="blood_bank"

# Shared secrets (accessible by both backend and frontend)
vault kv put secret/bloodbank/shared \
  encryption_key="shared-encryption-key-demo-2024" \
  session_secret="shared-session-secret-demo-2024"

echo -e "${GREEN}✓ Secrets created${NC}"

echo -e "${BLUE}Step 3: Enabling Kubernetes auth...${NC}"
vault auth enable kubernetes || echo "Kubernetes auth already enabled"

echo -e "${BLUE}Step 4: Configuring Kubernetes auth...${NC}"

# Get the Kubernetes host
K8S_HOST="https://kubernetes.default.svc"

# Configure Kubernetes auth (this assumes running inside K8s)
vault write auth/kubernetes/config \
  kubernetes_host="$K8S_HOST"

echo -e "${BLUE}Step 5: Creating Vault policies...${NC}"

# Backend policy
vault policy write bloodbank-backend - <<EOF
# Read backend secrets
path "secret/data/bloodbank/backend" {
  capabilities = ["read"]
}

# Read database secrets
path "secret/data/bloodbank/database" {
  capabilities = ["read"]
}

# Read shared secrets
path "secret/data/bloodbank/shared" {
  capabilities = ["read"]
}
EOF

# Frontend policy
vault policy write bloodbank-frontend - <<EOF
# Read frontend secrets
path "secret/data/bloodbank/frontend" {
  capabilities = ["read"]
}

# Read shared secrets (same as backend!)
path "secret/data/bloodbank/shared" {
  capabilities = ["read"]
}
EOF

# PostgreSQL policy
vault policy write bloodbank-postgres - <<EOF
# Read database secrets
path "secret/data/bloodbank/database" {
  capabilities = ["read"]
}
EOF

echo -e "${GREEN}✓ Policies created${NC}"

echo -e "${BLUE}Step 6: Creating Kubernetes auth roles...${NC}"

# Backend role
vault write auth/kubernetes/role/bloodbank-backend \
  bound_service_account_names=bloodbank-backend-sa \
  bound_service_account_namespaces=bloodbank \
  policies=bloodbank-backend \
  ttl=24h

# Frontend role
vault write auth/kubernetes/role/bloodbank-frontend \
  bound_service_account_names=bloodbank-frontend-sa \
  bound_service_account_namespaces=bloodbank \
  policies=bloodbank-frontend \
  ttl=24h

# PostgreSQL role
vault write auth/kubernetes/role/bloodbank-postgres \
  bound_service_account_names=bloodbank-postgres-sa \
  bound_service_account_namespaces=bloodbank \
  policies=bloodbank-postgres \
  ttl=24h

echo -e "${GREEN}✓ Roles created${NC}"

echo ""
echo -e "${GREEN}🎉 Vault setup complete!${NC}"
echo ""
echo -e "${YELLOW}Verify setup:${NC}"
echo "  vault kv get secret/bloodbank/backend"
echo "  vault kv get secret/bloodbank/shared"
echo "  vault read auth/kubernetes/role/bloodbank-backend"
