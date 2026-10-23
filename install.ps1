$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
Write-Host 'EHRNow LOCAL DEVELOPMENT installer (synthetic data only)'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Install Docker Desktop and enable Compose before continuing.' }
docker info *> $null
if ($LASTEXITCODE -ne 0) { throw 'Docker is not running.' }
docker compose version *> $null
if ($LASTEXITCODE -ne 0) { throw 'Docker Compose is unavailable.' }
if (-not (Test-Path -LiteralPath '.env.installer')) {
    $token = [Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).ToLowerInvariant()
    $password = [Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(24)).ToLowerInvariant()
    $contents = "EHR_DEV_TOKEN=$token`nEHR_DB_PASSWORD=$password`n"
    [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot '.env.installer'), $contents, [System.Text.UTF8Encoding]::new($false))
    Write-Host 'Generated local credentials in .env.installer.'
}
docker compose --env-file .env.installer -f compose.installer.yaml up -d --build --wait
if ($LASTEXITCODE -ne 0) { throw 'Container build or startup failed. Run docker compose --env-file .env.installer -f compose.installer.yaml logs' }
Write-Host 'Open http://127.0.0.1:5173'
Write-Host 'Development token is saved in .env.installer. Never share it.'
Write-Host 'Only fictional data; not for patient care or internet access.'
