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

# Start production application on port 8080
$process = Start-Process `
    -FilePath "java" `
    -ArgumentList "-jar `"$productionJar`" --server.port=8080" `
    -WorkingDirectory $productionDir `
    -PassThru

$process.Id | Out-File "$productionDir\pid.txt"

Write-Host "PetClinic released to production."
Write-Host "Build: $buildNumber"
Write-Host "URL: http://localhost:8080"
Write-Host "PID: $($process.Id)"