# Build script for K8s demo application (PowerShell)
# This script builds Docker images for backend and frontend

Write-Host "🔨 Building Docker images for K8s demo..." -ForegroundColor Cyan

# Change to project directory
$ProjectDir = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectDir

Write-Host "📦 Building backend image..." -ForegroundColor Blue
docker build -t bloodbank-backend:latest ./backend
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Backend image built successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Backend build failed" -ForegroundColor Red
    exit 1
}

Write-Host "📦 Building frontend image..." -ForegroundColor Blue
docker build -t bloodbank-frontend:latest ./frontend
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Frontend image built successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Frontend build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 All images built successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Images created:" -ForegroundColor Cyan
Write-Host "  - bloodbank-backend:latest"
Write-Host "  - bloodbank-frontend:latest"
Write-Host ""
Write-Host "💡 Tip: If using kind/minikube, load images with:" -ForegroundColor Yellow
Write-Host "  kind load docker-image bloodbank-backend:latest --name <cluster-name>"
Write-Host "  kind load docker-image bloodbank-frontend:latest --name <cluster-name>"

minikube addons enable ingress
minikube addons enable metrics-server
