# Frontend policy - can read frontend secrets and shared secrets
# NOTE: Frontend can access the SAME shared secrets as backend!
path "secret/data/bloodbank/frontend" {
  capabilities = ["read"]
}

path "secret/data/bloodbank/shared" {
  capabilities = ["read"]
}
