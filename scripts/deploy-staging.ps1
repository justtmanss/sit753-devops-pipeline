$ErrorActionPreference = "Stop"

$workspace = $env:WORKSPACE
$buildNumber = $env:BUILD_NUMBER

$deployDir = "C:\Jenkins\petclinic\staging"
$jar = Get-ChildItem "$workspace\target\*.jar" | Select-Object -First 1

if (-not $jar) {
    throw "No JAR file found in target folder."
}

New-Item -ItemType Directory -Force -Path $deployDir | Out-Null

# Stop previous staging process
if (Test-Path "$deployDir\pid.txt") {
    $oldPid = Get-Content "$deployDir\pid.txt"

    if (Get-Process -Id $oldPid -ErrorAction SilentlyContinue) {
        Stop-Process -Id $oldPid -Force
        Start-Sleep -Seconds 2
    }

    Remove-Item "$deployDir\pid.txt" -Force
}

# Copy artifact
$targetJar = "$deployDir\petclinic-$buildNumber.jar"
Copy-Item $jar.FullName $targetJar -Force

# Start application
$process = Start-Process `
    -FilePath "java" `
    -ArgumentList "-jar `"$targetJar`" --server.port=8081" `
    -WorkingDirectory $deployDir `
    -PassThru

$process.Id | Out-File "$deployDir\pid.txt"

# Wait for application startup
Write-Host "Waiting for PetClinic to start..."

$healthy = $false

for ($i = 1; $i -le 30; $i++) {
    Start-Sleep -Seconds 2

    try {
        $response = Invoke-WebRequest `
            -Uri "http://localhost:8081/actuator/health" `
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
    throw "Staging application failed health check on port 8081."
}

Write-Host "PetClinic staging deployment successful."
Write-Host "Build: $buildNumber"
Write-Host "Health check: PASSED"
Write-Host "URL: http://localhost:8081"