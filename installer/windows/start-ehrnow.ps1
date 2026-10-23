$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
Write-Host 'Starting EHRNow (synthetic data only)...'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing Docker Desktop using Windows Package Manager, if available...'
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id Docker.DockerDesktop --exact --accept-package-agreements --accept-source-agreements
    } else {
        Write-Host 'Please install Docker Desktop before relaunching EHRNow.'
    }
    Write-Host 'Finish Docker/WSL2 setup and restart Windows if prompted. Then click EHRNow again.'
    exit 1
}
docker info *> $null
if ($LASTEXITCODE -ne 0) { Write-Host 'Start Docker Desktop first, then relaunch EHRNow.'; exit 1 }
if (-not (Test-Path '.env.installer')) {
    $rng=[System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $a=New-Object byte[] 32; $b=New-Object byte[] 24
        $rng.GetBytes($a); $rng.GetBytes($b)
        $token=([BitConverter]::ToString($a) -replace '-','').ToLowerInvariant()
        $pwd=([BitConverter]::ToString($b) -replace '-','').ToLowerInvariant()
    } finally { $rng.Dispose() }
    [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot '.env.installer'), "EHR_DEV_TOKEN=$token`nEHR_DB_PASSWORD=$pwd`n",[System.Text.UTF8Encoding]::new($false))
}
docker compose --project-name ehrnow --env-file .env.installer -f compose.installer.yaml up -d --build --wait
if ($LASTEXITCODE -ne 0) { Write-Host 'Startup failed. Check Docker Desktop logs.'; exit 1 }
Start-Process 'http://127.0.0.1:5173'
Write-Host 'EHRNow is running locally. The development token is in .env.installer.'
