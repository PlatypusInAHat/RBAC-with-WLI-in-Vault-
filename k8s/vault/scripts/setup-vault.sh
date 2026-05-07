#!/bin/bash
# Setup HashiCorp Vault for Blood Bank Application
# This script configures Vault with Kubernetes auth and secret sharing

set -e

echo "🔐 Setting up Vault for Blood Bank..."

# Vault address
export VAULT_ADDR=http://vault.vault.svc.cluster.local:8200

# Check if Vault is sealed
if vault status | grep -q "Sealed.*true"; then
  echo "❌ Vault is sealed. Please unseal first:"
  echo "kubectl exec -n vault vault-0 -- vault operator unseal <key>"
  exit 1
fi

echo "✅ Vault is unsealed"

# 1. Enable Kubernetes authentication
echo "📝 Enabling Kubernetes auth backend..."
vault auth enable kubernetes 2>/dev/null || echo "Kubernetes auth already enabled"

# 2. Configure Kubernetes auth
echo "📝 Configuring Kubernetes auth..."
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

# 3. Enable KV v2 secrets engine
echo "📝 Enabling KV v2 secrets engine..."
vault secrets enable -version=2 -path=secret kv 2>/dev/null || echo "KV secrets engine already enabled"

# 4. Create secrets
echo "📝 Creating secrets..."

# Database credentials (SHARED: backend + postgres)
vault kv put secret/prj/database \
  username="postgres" \
  password="changeme" \
  host="postgres.prj.svc.cluster.local" \
  port="5432" \
  database="blood_bank"

# Backend-specific secrets
vault kv put secret/prj/backend \
  jwt_secret="prj-jwt-secret-key-2024-very-secure" \
  api_key="11102004"

# Frontend-specific secrets
vault kv put secret/prj/frontend \
  api_key="frontend-api-key-2024" \
  next_public_api_url="http://backend.prj.svc.cluster.local:3000/api"

# SHARED secrets (backend + frontend)
vault kv put secret/prj/shared \
  encryption_key="shared-encryption-key-very-secure-2024" \
  session_secret="shared-session-secret-2024"

echo "✅ Secrets created successfully"

# 5. Create policies
echo "📝 Creating Vault policies..."

# Backend policy
vault policy write backend-policy - <<EOF
# Backend Policy
path "secret/data/prj/database" {
  capabilities = ["read"]
}

path "secret/data/prj/backend" {
  capabilities = ["read"]
}

path "secret/data/prj/shared" {
  capabilities = ["read"]
}
EOF

# Frontend policy
vault policy write frontend-policy - <<EOF
# Frontend Policy
path "secret/data/prj/frontend" {
  capabilities = ["read"]
}

path "secret/data/prj/shared" {
  capabilities = ["read"]
}
EOF

# PostgreSQL policy
vault policy write postgres-policy - <<EOF
# PostgreSQL Policy
path "secret/data/prj/database" {
  capabilities = ["read"]
}
EOF

echo "✅ Policies created successfully"

# 6. Create Kubernetes roles
echo "📝 Creating Kubernetes roles..."

# Backend role
vault write auth/kubernetes/role/prj-backend \
  bound_service_account_names=prj-backend-sa \
  bound_service_account_namespaces=prj \
  policies=backend-policy \
  ttl=24h

# Frontend role
vault write auth/kubernetes/role/prj-frontend \
  bound_service_account_names=prj-frontend-sa \
  bound_service_account_namespaces=prj \
  policies=frontend-policy \
  ttl=24h

# PostgreSQL role
vault write auth/kubernetes/role/prj-postgres \
  bound_service_account_names=prj-postgres-sa \
  bound_service_account_namespaces=prj \
  policies=postgres-policy \
  ttl=24h

echo "✅ Kubernetes roles created successfully"

# 7. Verify setup
echo ""
echo "🔍 Verifying setup..."
echo "Secrets:"
vault kv list secret/prj/
echo ""
echo "Policies:"
vault policy list | grep -E "backend|frontend|postgres"
echo ""
echo "Kubernetes roles:"
vault list auth/kubernetes/role
echo ""
echo "✅ Vault setup complete!"
echo ""
echo "📋 Secret Sharing Matrix:"
echo "┌──────────────────────────┬─────────┬──────────┬────────────┐"
echo "│ Secret Path              │ Backend │ Frontend │ PostgreSQL │"
echo "├──────────────────────────┼─────────┼──────────┼────────────┤"
echo "│ prj/database       │   ✓     │    ✗     │     ✓      │"
echo "│ prj/backend        │   ✓     │    ✗     │     ✗      │"
echo "│ prj/frontend       │   ✗     │    ✓     │     ✗      │"
echo "│ prj/shared         │   ✓     │    ✓     │     ✗      │"
echo "└──────────────────────────┴─────────┴──────────┴────────────┘"
echo ""
echo "🎯 Next steps:"
echo "1. Deploy application: kubectl apply -f k8s/base/"
echo "2. Check Vault injection: kubectl logs -n prj <pod> -c vault-agent-init"
echo "3. Verify secrets: kubectl exec -n prj <pod> -- cat /vault/secrets/database"
