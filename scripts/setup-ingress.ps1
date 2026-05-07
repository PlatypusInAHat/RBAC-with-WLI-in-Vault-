# Setup Ingress Access for K8s Demo
# This script configures Ingress for easy access via domain names

Write-Host "🌐 Setting up Ingress access..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Apply ingress configuration
Write-Host "Step 1: Deploying Ingress resources..." -ForegroundColor Blue
kubectl apply -f k8s\base\ingress.yaml

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to deploy ingress" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Ingress deployed" -ForegroundColor Green
Write-Host ""

# Step 2: Wait for ingress to be ready
Write-Host "Step 2: Waiting for ingress to be ready (30 seconds)..." -ForegroundColor Blue
Start-Sleep -Seconds 30

# Step 3: Check ingress status
Write-Host "Step 3: Checking ingress status..." -ForegroundColor Blue
kubectl get ingress -n prj
Write-Host ""

# Step 4: Add hosts file entries
Write-Host "Step 4: Configuring hosts file..." -ForegroundColor Blue
Write-Host ""

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"
$entries = @(
    "127.0.0.1 prj.local",
    "127.0.0.1 api.prj.local"
)

Write-Host "Adding entries to hosts file (requires admin):" -ForegroundColor Yellow
foreach ($entry in $entries) {
    Write-Host "  $entry"
}
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    foreach ($entry in $entries) {
        # Check if entry already exists
        $content = Get-Content $hostsFile
        if ($content -notcontains $entry) {
            Add-Content -Path $hostsFile -Value $entry
            Write-Host "  ✓ Added: $entry" -ForegroundColor Green
        }
        else {
            Write-Host "  ℹ Already exists: $entry" -ForegroundColor Gray
        }
    }
}
else {
    Write-Host "⚠️  Not running as Administrator" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please add these lines to: $hostsFile" -ForegroundColor Yellow
    Write-Host ""
    foreach ($entry in $entries) {
        Write-Host "  $entry" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "To edit hosts file:" -ForegroundColor Cyan
    Write-Host "  1. Run PowerShell as Administrator"
    Write-Host "  2. notepad C:\Windows\System32\drivers\etc\hosts"
    Write-Host "  3. Add the lines above"
    Write-Host "  4. Save and close"
    Write-Host ""
}

# Step 5: Start minikube tunnel
Write-Host "Step 5: Starting minikube tunnel (requires admin)..." -ForegroundColor Blue
Write-Host ""
Write-Host "⚠️  IMPORTANT: minikube tunnel needs to run continuously" -ForegroundColor Yellow
Write-Host "   Keep this terminal open while using the app" -ForegroundColor Yellow
Write-Host ""

if ($isAdmin) {
    Write-Host "Starting tunnel..." -ForegroundColor Blue
    Write-Host ""
    Write-Host "Once tunnel is running, you can access:" -ForegroundColor Cyan
    Write-Host "  Frontend: http://prj.local" -ForegroundColor Green
    Write-Host "  Backend:  http://api.prj.local" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the tunnel" -ForegroundColor Yellow
    Write-Host ""
    
    # Run tunnel (will block)
    minikube tunnel
}
else {
    Write-Host "Please run this script as Administrator to start tunnel:" -ForegroundColor Yellow
    Write-Host "  Right-click PowerShell → Run as Administrator" -ForegroundColor Cyan
    Write-Host "  Then run: .\scripts\setup-ingress.ps1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or manually start tunnel:" -ForegroundColor Yellow
    Write-Host "  minikube tunnel" -ForegroundColor Cyan
}
