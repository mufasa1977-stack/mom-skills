# mom_bridge_install.ps1 — set up the "text your Claude from your phone" bridge on THIS laptop.
# Safe to read before running. Does NOT touch passwords/2FA/cards. Needs: Python + Claude Code already installed.
# Usage (run in PowerShell on the laptop):
#   $env:BOT_TOKEN="<token BotFather gave you>"; irm <this-gist-raw-url> | iex
# The bot token is the only thing you supply; your phone's chat id auto-binds the first time you text the bot.

$ErrorActionPreference = "Stop"
$dir = Join-Path $HOME "claude_mom\telegram_bridge"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Write-Host "install dir: $dir"

# 1) Fetch the bridge script (published alongside this installer).
$bridgeUrl = "https://raw.githubusercontent.com/mufasa1977-stack/mom-skills/main/bridge/mom_telegram_bridge.py"
try {
  Invoke-RestMethod $bridgeUrl -OutFile (Join-Path $dir "mom_telegram_bridge.py")
  Write-Host "downloaded mom_telegram_bridge.py"
} catch {
  Write-Warning "could not fetch bridge from $bridgeUrl — place mom_telegram_bridge.py in $dir manually."
}

# 2) Save the bot token (from env, so it isn't echoed into history).
if ($env:BOT_TOKEN) {
  Set-Content -Path (Join-Path $dir "bot_token.txt") -Value $env:BOT_TOKEN.Trim() -NoNewline -Encoding ascii
  Write-Host "saved bot_token.txt"
} else {
  Write-Warning "BOT_TOKEN not set — create $dir\bot_token.txt with your BotFather token before starting."
}

# 3) Point the bridge at the claude_mom workspace (so the phone drives her real assistant folder).
$ws = Join-Path $HOME "claude_mom"
if (Test-Path $ws) { Set-Content -Path (Join-Path $dir "workspace.txt") -Value $ws -NoNewline -Encoding ascii }

# 4) Make sure the one dependency is present.
try { python -m pip install --quiet --user requests | Out-Null; Write-Host "requests ok" } catch { Write-Warning "pip install requests failed: $_" }

# 5) start_bridge.bat — auto-restart loop, leaves a window running.
$bat = @"
@echo off
cd /d "%~dp0"
:loop
python mom_telegram_bridge.py
echo bridge exited, restarting in 5s...
timeout /t 5 >nul
goto loop
"@
Set-Content -Path (Join-Path $dir "start_bridge.bat") -Value $bat -Encoding ascii
Write-Host "wrote start_bridge.bat"

# 6) Boot persistence — shortcut in the Startup folder so it comes back after a reboot.
$startup = [Environment]::GetFolderPath("Startup")
$lnk = Join-Path $startup "claude_phone_bridge.lnk"
$ws2 = New-Object -ComObject WScript.Shell
$sc = $ws2.CreateShortcut($lnk)
$sc.TargetPath = Join-Path $dir "start_bridge.bat"
$sc.WorkingDirectory = $dir
$sc.WindowStyle = 7   # minimized
$sc.Save()
Write-Host "startup shortcut: $lnk"

# 7) Keep the laptop reachable (don't sleep on AC). Lid-close action is handled separately.
try { powercfg /change standby-timeout-ac 0; powercfg /change monitor-timeout-ac 0 } catch {}

Write-Host ""
Write-Host "DONE. To start now:  Start-Process (Join-Path '$dir' 'start_bridge.bat')"
Write-Host "Then, from the phone, open Telegram, find your bot, and send it any message to connect."
