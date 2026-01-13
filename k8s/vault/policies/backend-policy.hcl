# Backend Policy
# Allows backend pods to access:
# - Database credentials (shared with postgres)
# - Backend-specific secrets
# - Shared secrets (shared with frontend)

path "secret/data/bloodbank/database" {
  capabilities = ["read"]
}

path "secret/data/bloodbank/backend" {
  capabilities = ["read"]
}

path "secret/data/bloodbank/shared" {
  capabilities = ["read"]
}
