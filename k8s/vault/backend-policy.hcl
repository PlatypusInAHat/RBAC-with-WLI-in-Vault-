# Backend policy - can read backend secrets, database secrets, and shared secrets
path "secret/data/bloodbank/backend" {
  capabilities = ["read"]
}

path "secret/data/bloodbank/database" {
  capabilities = ["read"]
}

path "secret/data/bloodbank/shared" {
  capabilities = ["read"]
}
