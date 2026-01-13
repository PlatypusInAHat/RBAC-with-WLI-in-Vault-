# Setup Minikube Cluster for K8s Demo
# Updated based on successful manual setup steps

Write-Host "🚀 Setting up Minikube cluster for K8s demo..." -ForegroundColor Cyan
Write-Host ""

# Step 0: Check if cluster exists and delete if needed
Write-Host "Step 0: Checking existing cluster..." -ForegroundColor Blue
$clusterStatus = minikube status 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Found existing cluster. Deleting..." -ForegroundColor Yellow
    minikube delete
    Write-Host "  ✓ Cluster deleted" -ForegroundColor Green
}
else {
    Write-Host "  No existing cluster found" -ForegroundColor Gray
}

Write-Host ""

# Step 1: Start minikube with Docker driver and Calico CNI
Write-Host "Step 1: Starting minikube (1 node, 3072MB, Calico CNI)..." -ForegroundColor Blue
minikube start --driver=docker --cni=calico --nodes=2 --memory=2048  --cpus=2

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to start minikube" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Minikube started" -ForegroundColor Green
Write-Host ""

# Step 2: Enable ingress addon
Write-Host "Step 2: Enabling ingress addon..." -ForegroundColor Blue
minikube addons enable ingress

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to enable ingress" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Ingress enabled" -ForegroundColor Green
Write-Host ""

# Step 3: Enable metrics-server addon
Write-Host "Step 3: Enabling metrics-server addon..." -ForegroundColor Blue
minikube addons enable metrics-server

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to enable metrics-server" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Metrics-server enabled" -ForegroundColor Green
Write-Host ""

# Step 4: Wait for pods to be ready
Write-Host "Step 4: Waiting for system pods to be ready..." -ForegroundColor Blue
Write-Host "  This may take 1-2 minutes..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check pod status
kubectl get pods -n kube-system | Select-String "calico|coredns|metrics"
Write-Host ""

# Step 5: Load backend image
Write-Host "Step 5: Loading backend image into minikube..." -ForegroundColor Blue
minikube image load bloodbank-backend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to load backend image" -ForegroundColor Red
    Write-Host "  Make sure you've built the image first: .\scripts\build-images.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "✓ Backend image loaded" -ForegroundColor Green
Write-Host ""

# Step 6: Load frontend image
Write-Host "Step 6: Loading frontend image into minikube..." -ForegroundColor Blue
minikube image load bloodbank-frontend:latest

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to load frontend image" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Frontend image loaded" -ForegroundColor Green
Write-Host ""

# Step 7: Verify setup
Write-Host "Step 7: Verifying setup..." -ForegroundColor Blue
Write-Host ""
Write-Host "Cluster nodes:" -ForegroundColor Cyan
kubectl get nodes
Write-Host ""

Write-Host "Loaded images:" -ForegroundColor Cyan
minikube image ls | Select-String "bloodbank"
Write-Host ""

Write-Host "System pods:" -ForegroundColor Cyan
kubectl get pods -n kube-system
Write-Host ""

Write-Host "Ingress controller:" -ForegroundColor Cyan
kubectl get pods -n ingress-nginx
Write-Host ""

# Final summary
Write-Host ""
Write-Host "🎉 Minikube setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Cluster configuration:" -ForegroundColor Cyan
Write-Host "  Driver:  Docker"
Write-Host "  CNI:     Calico"
Write-Host "  Nodes:   1 node"
Write-Host "  Memory:  3072MB"
Write-Host "  CPUs:    2"
Write-Host ""
Write-Host "Enabled addons:" -ForegroundColor Cyan
Write-Host "  ✓ ingress"
Write-Host "  ✓ metrics-server"
Write-Host ""
Write-Host "Loaded images:" -ForegroundColor Cyan
Write-Host "  ✓ bloodbank-backend:latest"
Write-Host "  ✓ bloodbank-frontend:latest"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Deploy application: .\scripts\deploy.ps1"
Write-Host "  2. Check pods: kubectl get pods -n bloodbank"
Write-Host "  3. Port-forward services to access:"
Write-Host "     kubectl port-forward -n bloodbank svc/frontend 30080:3000"
Write-Host "     kubectl port-forward -n bloodbank svc/backend 30000:3000"
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  minikube status    - Check cluster status"
Write-Host "  minikube dashboard - Open Kubernetes dashboard"
Write-Host "  minikube stop      - Stop the cluster"
Write-Host "  minikube delete    - Delete the cluster"
Write-Host ""
