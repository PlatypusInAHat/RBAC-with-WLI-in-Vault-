# Build script for K8s demo application (PowerShell)
# This script builds Docker images for backend and frontend

Write-Host "Building Docker images for K8s demo..." -ForegroundColor Cyan

# Change to project directory
$ProjectDir = "d:\k8\RBAC-with-WLI-in-Vault-"

Write-Host "Building backend image..." -ForegroundColor Blue
docker build -t prj-backend:latest "$ProjectDir\backend"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Backend image built successfully" -ForegroundColor Green
} else {
    Write-Host "Backend build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Building frontend image..." -ForegroundColor Blue
docker build -t prj-frontend:latest "$ProjectDir\frontend"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Frontend image built successfully" -ForegroundColor Green
} else {
    Write-Host "Frontend build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All images built successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Images created:" -ForegroundColor Cyan
Write-Host "  - prj-backend:latest"
Write-Host "  - prj-frontend:latest"
Write-Host ""
Write-Host "Tip: If using kind/minikube, load images with:" -ForegroundColor Yellow
Write-Host "  minikube image load prj-backend:latest"
Write-Host "  minikube image load prj-frontend:latest"
