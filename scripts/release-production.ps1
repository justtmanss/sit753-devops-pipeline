$ErrorActionPreference = "Stop"

$buildNumber = $env:BUILD_NUMBER

$stagingDir = "C:\Jenkins\petclinic\staging"
$productionDir = "C:\Jenkins\petclinic\production"

$stagingJar = "$stagingDir\petclinic-$buildNumber.jar"
$productionJar = "$productionDir\petclinic-$buildNumber.jar"

if (-not (Test-Path $stagingJar)) {
    throw "Staging artifact not found: $stagingJar"
}

New-Item -ItemType Directory -Force -Path $productionDir | Out-Null

# Stop previous production application
if (Test-Path "$productionDir\pid.txt") {
    $oldPid = Get-Content "$productionDir\pid.txt"

    if (Get-Process -Id $oldPid -ErrorAction SilentlyContinue) {
        Stop-Process -Id $oldPid -Force
        Start-Sleep -Seconds 2
    }

    Remove-Item "$productionDir\pid.txt" -Force
}

# Promote the exact artifact that passed staging
Copy-Item $stagingJar $productionJar -Force

# Start production application independently of Jenkins
$process = Start-Process `
    -FilePath "java" `
    -ArgumentList "-jar `"$productionJar`" --server.port=8082" `
    -WorkingDirectory $productionDir `
    -PassThru

$process.Id | Out-File "$productionDir\pid.txt"

Write-Host "PetClinic released to production."
Write-Host "Build: $buildNumber"
Write-Host "URL: http://localhost:8082"
Write-Host "PID: $($process.Id)"

# Wait for production to become healthy
Write-Host "Waiting for production application to start..."

$healthy = $false

for ($i = 1; $i -le 30; $i++) {
    Start-Sleep -Seconds 2

    try {
        $response = Invoke-WebRequest `
            -Uri "http://localhost:8082/actuator/health" `
            -UseBasicParsing `
            -TimeoutSec 3

        if ($response.StatusCode -eq 200) {
            $healthy = $true
            break
        }
    }
    catch {
        # Application is still starting
    }
}

if (-not $healthy) {
    throw "Production application failed health check on port 8082."
}

Write-Host "Production deployment successful."
Write-Host "Health check: PASSED"