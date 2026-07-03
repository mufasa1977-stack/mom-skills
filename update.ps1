<#
  update.ps1 — one command to pull the latest mom-brain and (re)install it.
  Run from the cloned repo folder:  powershell -ExecutionPolicy Bypass -File .\update.ps1
#>
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Pulling latest mom-brain..." -ForegroundColor Cyan
git -C $here pull --ff-only
& powershell -ExecutionPolicy Bypass -File (Join-Path $here 'install.ps1')
