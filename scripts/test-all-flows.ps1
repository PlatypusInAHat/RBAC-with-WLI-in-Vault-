# Comprehensive Flow Testing Script
# Tests all K8s features: RBAC, Network, Vault, Secret Sharing

Write-Host "🧪 K8s Demo - Comprehensive Flow Testing" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$results = @()

# Helper function to test and record
function Test-Flow {
    param(
        [string]$Name,
        [scriptblock]$TestCommand,
        [string]$ExpectedPattern
    )
    
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    try {
        $output = & $TestCommand 2>&1
        $success = if ($ExpectedPattern) {
            $output -match $ExpectedPattern
        }
        else {
            $LASTEXITCODE -eq 0
        }
        
        if ($success) {
            Write-Host "  ✅ PASS" -ForegroundColor Green
            $script:results += [PSCustomObject]@{Test = $Name; Result = "PASS" }
        }
        else {
            Write-Host "  ❌ FAIL" -ForegroundColor Red
            Write-Host "  Output: $output" -ForegroundColor Gray
            $script:results += [PSCustomObject]@{Test = $Name; Result = "FAIL" }
        }
    }
    catch {
        Write-Host "  ❌ ERROR: $_" -ForegroundColor Red
        $script:results += [PSCustomObject]@{Test = $Name; Result = "ERROR" }
    }
    Write-Host ""
}

Write-Host "📊 FLOW 1: Infrastructure Health" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

Test-Flow "Cluster has 2 nodes" {
    $nodes = kubectl get nodes --no-headers | Measure-Object
    $nodes.Count
} "2"

Test-Flow "All prj pods running" {
    kubectl get pods -n prj --field-selector=status.phase=Running --no-headers | Measure-Object | Select-Object -ExpandProperty Count
} "[3-9]"

Test-Flow "Vault pods running" {
    kubectl get pods -n vault --field-selector=status.phase=Running --no-headers
}

Write-Host ""
Write-Host "🔐 FLOW 2: RBAC Permissions" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

Test-Flow "Backend ServiceAccount exists" {
    kubectl get sa prj-backend-sa -n prj
}

Test-Flow "Backend SA has Vault annotations" {
    kubectl get sa prj-backend-sa -n prj -o yaml | Select-String "vault.hashicorp.com"
}

Test-Flow "Secret-reader role exists" {
    kubectl get role secret-reader -n prj
}

Test-Flow "Backend can access RBAC API" {
    Invoke-WebRequest -Uri "http://localhost:30000/api/rbac" -UseBasicParsing | Select-Object -ExpandProperty StatusCode
} "200"

Write-Host ""
Write-Host "🌐 FLOW 3: Network Connectivity" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host ""

Test-Flow "Frontend reachable" {
    Invoke-WebRequest -Uri "http://localhost:30080" -UseBasicParsing | Select-Object -ExpandProperty StatusCode
} "200"

Test-Flow "Backend health endpoint" {
    Invoke-WebRequest -Uri "http://localhost:30000/health" -UseBasicParsing | Select-Object -ExpandProperty StatusCode
} "200"

Test-Flow "Frontend → Backend connectivity" {
    Invoke-WebRequest -Uri "http://localhost:30000/api/info" -UseBasicParsing | Select-Object -ExpandProperty StatusCode
} "200"

Test-Flow "Backend → PostgreSQL (direct IP)" {
    kubectl exec -n prj deploy/backend -- nc -zv -w 3 10.244.1.12 5432 2>&1
} "open"

Write-Host ""
Write-Host "🔒 FLOW 4: Vault Integration" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
Write-Host ""

Test-Flow "Vault API endpoint accessible" {
    $response = Invoke-WebRequest -Uri "http://localhost:30000/api/vault" -UseBasicParsing
    $response.StatusCode
} "200"

Test-Flow "Vault role configured" {
    $response = Invoke-WebRequest -Uri "http://localhost:30000/api/vault" -UseBasicParsing | ConvertFrom-Json
    $response.vaultAgent.role
} "prj-backend"

Test-Flow "Vault policies exist" {
    Test-Path "k8s\vault\backend-policy.hcl"
}

Write-Host ""
Write-Host "🔄 FLOW 5: Secret Sharing Architecture" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

Test-Flow "Secrets API endpoint" {
    Invoke-WebRequest -Uri "http://localhost:30000/api/secrets" -UseBasicParsing | Select-Object -ExpandProperty StatusCode
} "200"

Test-Flow "Backend policy allows shared secrets" {
    Select-String -Path "k8s\vault\backend-policy.hcl" -Pattern "shared"
}

Test-Flow "Frontend policy allows shared secrets" {
    Select-String -Path "k8s\vault\frontend-policy.hcl" -Pattern "shared"
}

Write-Host ""
Write-Host "🛡️ FLOW 6: Network Policies" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

Test-Flow "Network policies applied" {
    kubectl get networkpolicies -n prj --no-headers | Measure-Object | Select-Object -ExpandProperty Count
} "[4-9]"

Test-Flow "Backend network policy exists" {
    kubectl get networkpolicy backend-netpol -n prj
}

Test-Flow "PostgreSQL network policy exists" {
    kubectl get networkpolicy postgres-netpol -n prj
}

Write-Host ""
Write-Host "📱 FLOW 7: Frontend Dashboard" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

Test-Flow "Dashboard loads HTML" {
    $response = Invoke-WebRequest -Uri "http://localhost:30080" -UseBasicParsing
    $response.Content -match "RBAC"
}

Test-Flow "Service Info API" {
    Invoke-WebRequest -Uri "http://localhost:30000/api/info" -UseBasicParsing | Select-Object -ExpandProperty StatusCode
} "200"

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "📋 TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host ""

$passed = ($results | Where-Object { $_.Result -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Result -ne "PASS" }).Count
$total = $results.Count

Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""

$percentage = [math]::Round(($passed / $total) * 100, 1)
Write-Host "Success Rate: $percentage%" -ForegroundColor $(if ($percentage -ge 90) { "Green" } elseif ($percentage -ge 75) { "Yellow" } else { "Red" })

Write-Host ""
Write-Host "Detailed Results:" -ForegroundColor Cyan
$results | Format-Table -AutoSize

Write-Host ""
if ($percentage -ge 90) {
    Write-Host "🎉 EXCELLENT! All critical flows working!" -ForegroundColor Green
}
elseif ($percentage -ge 75) {
    Write-Host "✅ GOOD! Most flows working, minor issues found." -ForegroundColor Yellow
}
else {
    Write-Host "⚠️ NEEDS ATTENTION: Multiple flows failing." -ForegroundColor Red
}
