# Windows preflight for the portfolio demo.
# Usage:
#   .\scripts\00-preflight.ps1
#   .\scripts\00-preflight.ps1 -SourceHost <src-endpoint> -TargetHost <tgt-endpoint>

param(
  [string]$SourceHost = $env:SRC_HOST,
  [string]$TargetHost = $env:TGT_HOST,
  [string]$AwsProfile = $(if ($env:AWS_PROFILE) { $env:AWS_PROFILE } else { "summit-demo" }),
  [string]$AwsRegion = $(if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" })
)

$ErrorActionPreference = "Continue"

$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
if ((Test-Path "$awsCliPath\aws.exe") -and ($env:Path -notlike "*$awsCliPath*")) {
  $env:Path += ";$awsCliPath"
}

$mysqlBins = @(
  "C:\Program Files\MySQL\MySQL Server 8.4\bin",
  "C:\Program Files\MySQL\MySQL Server 8.0\bin",
  "C:\Program Files\MySQL\MySQL Shell 8.4\bin",
  "C:\Program Files\MySQL\MySQL Shell 8.0\bin"
)
foreach ($mysqlBin in $mysqlBins) {
  if ((Test-Path "$mysqlBin\mysql.exe") -and ($env:Path -notlike "*$mysqlBin*")) {
    $env:Path += ";$mysqlBin"
    break
  }
}

$gitBin = "C:\Program Files\Git\bin"
if ((Test-Path "$gitBin\bash.exe") -and ($env:Path -notlike "*$gitBin*")) {
  $env:Path += ";$gitBin"
}

function Write-Check {
  param([string]$Name, [bool]$Ok, [string]$Detail)
  $status = if ($Ok) { "OK" } else { "MISSING" }
  Write-Host ("[{0}] {1} - {2}" -f $status, $Name, $Detail)
}

function Test-CommandExists {
  param([string]$Command)
  $cmd = Get-Command $Command -ErrorAction SilentlyContinue
  Write-Check $Command ([bool]$cmd) $(if ($cmd) { $cmd.Source } else { "not found in PATH" })
}

Write-Host "=== Local tools ==="
Test-CommandExists "python"
Test-CommandExists "aws"
Test-CommandExists "mysql"
Test-CommandExists "bash"

Write-Host ""
Write-Host "=== Python dependencies ==="
if (Get-Command python -ErrorAction SilentlyContinue) {
  python -c "import yaml, mysql.connector; print('OK PyYAML and mysql-connector-python installed')" 2>$null
  Write-Check "python deps" ($LASTEXITCODE -eq 0) "run: python -m pip install -r requirements.txt"
}

Write-Host ""
Write-Host "=== AWS config ==="
$awsConfig = Test-Path "$HOME\.aws\config"
$awsCreds = Test-Path "$HOME\.aws\credentials"
Write-Check "AWS config" $awsConfig "$HOME\.aws\config"
Write-Check "AWS credentials" $awsCreds "$HOME\.aws\credentials"
Write-Host "AWS_PROFILE=$AwsProfile"
Write-Host "AWS_REGION=$AwsRegion"

if (Get-Command aws -ErrorAction SilentlyContinue) {
  Write-Host ""
  Write-Host "=== CloudFormation stack ==="
  aws cloudformation describe-stacks --profile $AwsProfile --region $AwsRegion --stack-name dms-demo --query "Stacks[0].StackStatus" --output text
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Could not describe stack dms-demo. Check AWS credentials/profile/region."
  }
}

Write-Host ""
Write-Host "=== Endpoint connectivity ==="
if ($SourceHost) {
  $src = Test-NetConnection $SourceHost -Port 3306
  Write-Check "source MySQL endpoint" $src.TcpTestSucceeded "${SourceHost}:3306"
} else {
  Write-Check "source MySQL endpoint" $false "SRC_HOST not set"
}

if ($TargetHost) {
  $tgt = Test-NetConnection $TargetHost -Port 3306
  Write-Check "target MySQL endpoint" $tgt.TcpTestSucceeded "${TargetHost}:3306"
} else {
  Write-Check "target MySQL endpoint" $false "TGT_HOST not set"
}

Write-Host ""
Write-Host "Next steps when all checks are OK:"
Write-Host "  mysql -h `$env:SRC_HOST -u admin -p`$env:DB_PASSWORD demo < scripts/10-seed-finance-source.sql"
Write-Host "  ./scripts/start-task.sh"
Write-Host "  ./scripts/11-generate-live-finance-events.sh"
Write-Host "  ./scripts/13-measure-finance-lag.sh"
Write-Host "  python ai/ask_dashboard.py `"How fresh is the dashboard?`" --host `$env:TGT_HOST --password `$env:DB_PASSWORD"
