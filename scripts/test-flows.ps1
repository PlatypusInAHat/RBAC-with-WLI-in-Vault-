# Test K8s Demo - Kiểm tra các luồng
# Script này sẽ deploy app và test từng luồng một

Write-Host "🧪 Testing K8s Demo - RBAC, Workload Identity & Vault" -ForegroundColor Cyan
Write-Host ""

# Step 1: Load Docker images
Write-Host "Step 1: Loading Docker images vào minikube..." -ForegroundColor Blue
minikube image load bloodbank-backend:latest
minikube image load bloodbank-frontend:latest
Write-Host "✓ Images loaded" -ForegroundColor Green
Write-Host ""

# Step 2: Deploy all resources
Write-Host "Step 2: Deploying K8s resources..." -ForegroundColor Blue
.\scripts\deploy.ps1
Write-Host ""

# Wait for pods to be ready
Write-Host "Step 3: Waiting for pods to be ready (60s)..." -ForegroundColor Blue
Start-Sleep -Seconds 60

# Step 4: Check deployment status
Write-Host "Step 4: Checking deployment status..." -ForegroundColor Blue
Write-Host ""
Write-Host "=== Namespaces ===" -ForegroundColor Yellow
kubectl get namespaces | Select-String -Pattern "bloodbank|vault"

Write-Host ""
Write-Host "=== Pods in bloodbank namespace ===" -ForegroundColor Yellow
kubectl get pods -n bloodbank

Write-Host ""
Write-Host "=== Pods in vault namespace ===" -ForegroundColor Yellow
kubectl get pods -n vault

Write-Host ""
Write-Host "=== Services ===" -ForegroundColor Yellow
kubectl get svc -n bloodbank

Write-Host ""
Write-Host ""
Write-Host "🔍 Detailed Testing Guide:" -ForegroundColor Cyan
Write-Host ""

Write-Host "📊 TEST 1: Network Flow (Frontend → Backend → Database)" -ForegroundColor Green
Write-Host "  1. Port forward frontend: kubectl port-forward -n bloodbank svc/frontend 30080:3000"
Write-Host "  2. Open browser: http://localhost:30080"
Write-Host "  3. Check all cards load data (green status)"
Write-Host ""

Write-Host "🔐 TEST 2: RBAC Permissions" -ForegroundColor Green
Write-Host "  # Check ServiceAccounts"
Write-Host "  kubectl get sa -n bloodbank"
Write-Host ""
Write-Host "  # View backend SA details"
Write-Host "  kubectl describe sa bloodbank-backend-sa -n bloodbank"
Write-Host ""
Write-Host "  # Check roles & bindings"
Write-Host "  kubectl get roles,rolebindings -n bloodbank"
Write-Host ""
Write-Host "  # Test from inside pod"
Write-Host '  $POD = kubectl get pod -n bloodbank -l component=backend -o jsonpath="{.items[0].metadata.name}"'
Write-Host '  kubectl exec -n bloodbank $POD -- cat /var/run/secrets/kubernetes.io/serviceaccount/namespace'
Write-Host ""

Write-Host "🔒 TEST 3: Vault Workload Identity" -ForegroundColor Green
Write-Host "  # Check Vault pod"
Write-Host "  kubectl get pods -n vault"
Write-Host ""
Write-Host "  # Check Vault annotations on backend pod"
Write-Host '  $POD = kubectl get pod -n bloodbank -l component=backend -o jsonpath="{.items[0].metadata.name}"'
Write-Host '  kubectl describe pod -n bloodbank $POD | Select-String "vault"'
Write-Host ""
Write-Host "  # Check if secrets are injected"
Write-Host '  kubectl exec -n bloodbank $POD -c backend -- ls -la /vault/secrets/'
Write-Host ""

Write-Host "🔄 TEST 4: Secret Sharing (Backend ↔ Frontend)" -ForegroundColor Green
Write-Host "  # Port forward backend"
Write-Host "  kubectl port-forward -n bloodbank svc/backend 30000:3000"
Write-Host ""
Write-Host "  # Test API endpoints (in new terminal)"
Write-Host "  curl http://localhost:30000/api/vault"
Write-Host "  curl http://localhost:30000/api/secrets"
Write-Host ""
Write-Host "  # Verify shared secrets accessible from both pods"
Write-Host '  $BE_POD = kubectl get pod -n bloodbank -l component=backend -o jsonpath="{.items[0].metadata.name}"'
Write-Host '  $FE_POD = kubectl get pod -n bloodbank -l component=frontend -o jsonpath="{.items[0].metadata.name}"'
Write-Host '  kubectl exec -n bloodbank $BE_POD -c backend -- cat /vault/secrets/shared'
Write-Host '  kubectl exec -n bloodbank $FE_POD -c frontend -- cat /vault/secrets/shared'
Write-Host ""

Write-Host "🌐 TEST 5: Network Policies" -ForegroundColor Green
Write-Host "  # Check network policies"
Write-Host "  kubectl get networkpolicies -n bloodbank"
Write-Host ""
Write-Host "  # Test connectivity from frontend to backend (should work)"
Write-Host '  $FE_POD = kubectl get pod -n bloodbank -l component=frontend -o jsonpath="{.items[0].metadata.name}"'
Write-Host '  kubectl exec -n bloodbank $FE_POD -- curl -s http://backend-internal:3000/health'
Write-Host ""
Write-Host "  # Test backend to database (should work)"
Write-Host '  $BE_POD = kubectl get pod -n bloodbank -l component=backend -o jsonpath="{.items[0].metadata.name}"'
Write-Host '  kubectl exec -n bloodbank $BE_POD -- nc -zv postgres 5432'
Write-Host ""

Write-Host "💾 TEST 6: Database Connection" -ForegroundColor Green
Write-Host "  # Check via API"
Write-Host "  curl http://localhost:30000/api/database"
Write-Host ""
Write-Host "  # Or check from frontend dashboard at http://localhost:30080"
Write-Host ""

Write-Host ""
Write-Host "🎯 Quick Access URLs (after port-forward):" -ForegroundColor Cyan
Write-Host "  Frontend: http://localhost:30080"
Write-Host "  Backend:  http://localhost:30000"
Write-Host ""
Write-Host "📋 Useful monitoring commands:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n bloodbank -w"
Write-Host "  kubectl logs -n bloodbank -l component=backend --tail=50 -f"
Write-Host "  kubectl describe pod -n bloodbank <pod-name>"
