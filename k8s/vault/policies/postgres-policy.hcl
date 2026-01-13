# PostgreSQL Policy
# Allows postgres pods to access:
# - Database credentials only (shared with backend)

path "secret/data/bloodbank/database" {
  capabilities = ["read"]
}
