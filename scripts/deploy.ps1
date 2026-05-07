# Deploy script for K8s demo application (PowerShell)
# This script deploys all resources to Kubernetes cluster

Write-Host "Deploying K8s demo application..." -ForegroundColor Cyan

# Change to project directory
$ProjectDir = "d:\k8\RBAC-with-WLI-in-Vault-"
$K8sDir = Join-Path $ProjectDir "k8s"

Write-Host ""
Write-Host "Step 1: Creating namespaces..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "vault\vault-rbac.yaml")
kubectl apply -f (Join-Path $K8sDir "base\namespace.yaml")

Write-Host ""
Write-Host "Step 2: Deploying Vault..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "vault\vault-deployment.yaml")
kubectl apply -f (Join-Path $K8sDir "vault\vault-service.yaml")
kubectl apply -f (Join-Path $K8sDir "vault\vault-injector-webhook.yaml")

Write-Host ""
Write-Host "Step 3: Creating RBAC rules..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\rbac.yaml")

Write-Host ""
Write-Host "Step 4: Creating secrets..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\secrets.yaml")

Write-Host ""
Write-Host "Step 5: Creating storage..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\storage.yaml")

Write-Host ""
Write-Host "Step 6: Deploying PostgreSQL..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\postgres-deployment-no-vault.yaml")

Write-Host ""
Write-Host "Step 7: Deploying backend..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\backend-deployment.yaml")

Write-Host ""
Write-Host "Step 8: Deploying frontend..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\frontend-deployment.yaml")

Write-Host ""
Write-Host "Step 9: Creating services..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\services.yaml")

Write-Host ""
Write-Host "Step 10: Applying network policies..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\network-policies.yaml")

Write-Host ""
Write-Host "Step 11: Creating ingress..." -ForegroundColor Blue
kubectl apply -f (Join-Path $K8sDir "base\ingress.yaml")

Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Check deployment status:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n prj"
Write-Host "  kubectl get pods -n vault"
