# Quick Access Script - Open K8s Demo Applications
# Use this instead of port-forward for easier access

Write-Host "🌐 Opening K8s Demo Applications..." -ForegroundColor Cyan
Write-Host ""

# Method 1: Use minikube service (Recommended)
Write-Host "Opening services via minikube service..." -ForegroundColor Blue
Write-Host ""

# Get URLs
$FRONTEND_URL = minikube service frontend -n bloodbank --url
$BACKEND_URL = minikube service backend -n bloodbank --url

Write-Host "✓ Service URLs:" -ForegroundColor Green
Write-Host "  Frontend: $FRONTEND_URL" -ForegroundColor Cyan
Write-Host "  Backend:  $BACKEND_URL" -ForegroundColor Cyan
Write-Host ""

# Open in browser
Write-Host "Opening frontend in browser..." -ForegroundColor Yellow
Start-Process $FRONTEND_URL

Write-Host ""
Write-Host "🎉 Frontend opened!" -ForegroundColor Green
Write-Host ""
Write-Host "Backend API available at: $BACKEND_URL" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 Tip: Keep this terminal open to maintain the connection" -ForegroundColor Yellow
Write-Host ""
Write-Host "To access backend API:" -ForegroundColor Cyan
Write-Host "  Invoke-WebRequest $BACKEND_URL/health"
Write-Host "  Invoke-WebRequest $BACKEND_URL/api/info"
Write-Host ""
