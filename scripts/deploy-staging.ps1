$ErrorActionPreference = "Stop"

$workspace = $env:WORKSPACE
$buildNumber = $env:BUILD_NUMBER

$deployDir = "C:\Jenkins\petclinic\staging"
$jar = Get-ChildItem "$workspace\target\*.jar" | Select-Object -First 1

if (-not $jar) {
    throw "No JAR file found in target folder."
}

New-Item -ItemType Directory -Force -Path $deployDir | Out-Null

# Stop existing staging application
if (Test-Path "$deployDir\pid.txt") {
    $oldPid = Get-Content "$deployDir\pid.txt"

    if (Get-Process -Id $oldPid -ErrorAction SilentlyContinue) {
        Stop-Process -Id $oldPid -Force
        Start-Sleep -Seconds 2
    }

    Remove-Item "$deployDir\pid.txt" -Force
}

# Copy the versioned artifact
$targetJar = "$deployDir\petclinic-$buildNumber.jar"
Copy-Item $jar.FullName $targetJar -Force

# Start staging application on port 8081
$process = Start-Process `
    -FilePath "java" `
    -ArgumentList "-jar `"$targetJar`" --server.port=8081" `
    -WorkingDirectory $deployDir `
    -PassThru

$process.Id | Out-File "$deployDir\pid.txt"

Write-Host "PetClinic deployed to staging."
Write-Host "Build: $buildNumber"
Write-Host "URL: http://localhost:8081"
Write-Host "PID: $($process.Id)"