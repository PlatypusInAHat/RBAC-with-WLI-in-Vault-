# Frontend Policy
# Allows frontend pods to access:
# - Frontend-specific secrets  
# - Shared secrets (shared with backend)

path "secret/data/bloodbank/frontend" {
  capabilities = ["read"]
}

path "secret/data/bloodbank/shared" {
  capabilities = ["read"]
}
