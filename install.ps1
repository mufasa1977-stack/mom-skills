<#
  install.ps1 — installs/refreshes the mom-brain package into ~/.claude
  (brain CLAUDE.md + general skills + memory scaffold). Safe: backs up before overwriting,
  never touches personal files, no secrets, no session-trapping hooks.
  Run from the cloned repo folder:  powershell -ExecutionPolicy Bypass -File .\install.ps1
#>
$ErrorActionPreference = 'Continue'
function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$claude = Join-Path $env:USERPROFILE '.claude'
New-Item -ItemType Directory -Force $claude, (Join-Path $claude 'skills'), (Join-Path $claude 'memory') | Out-Null
Say "=== Updating mom-brain from $here ===" 'Cyan'

# 1) brain (back up existing first)
$brainSrc = Join-Path $here 'CLAUDE.md'
$brainDst = Join-Path $claude 'CLAUDE.md'
if (Test-Path $brainSrc) {
  if (Test-Path $brainDst) { Copy-Item $brainDst "$brainDst.bak_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force }
  Copy-Item $brainSrc $brainDst -Force
  Say "[brain] ~/.claude/CLAUDE.md updated" 'Green'
}

# 2) skills (copy each folder; overwrite = refresh to latest)
$skillsSrc = Join-Path $here 'skills'
if (Test-Path $skillsSrc) {
  $n = 0
  Get-ChildItem $skillsSrc -Directory | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $claude "skills\$($_.Name)") -Recurse -Force; $n++
  }
  Say "[skills] $n skill folder(s) synced into ~/.claude/skills" 'Green'
}

# 3) memory scaffold (create only if missing — never clobber her memories)
$idx = Join-Path $claude 'memory\MEMORY.md'
if (-not (Test-Path $idx)) {
@'
# Memory Index
> One line per memory. Skim at the start of each session; open any that look relevant.
> Save durable facts as ~/.claude/memory/<name>.md and add a pointer line here.

- [about-me](about-me.md) — who I am and how I like to be helped
'@ | Set-Content $idx -Encoding UTF8
}
$about = Join-Path $claude 'memory\about-me.md'
if (-not (Test-Path $about)) {
@'
---
name: about-me
description: who the user is and how she likes to be helped
metadata: { type: user }
---
Warm, non-technical user learning the computer. Prefers plain-English, one-step-at-a-time help; wants
her assistant to DO things for her, remember across sessions, and get more helpful over time. Never ask
her to type passwords, card numbers, or 2FA codes.
'@ | Set-Content $about -Encoding UTF8
}
Say "[memory] scaffold present" 'Green'

Say "`n=== DONE ===" 'Cyan'
Say "Restart Claude Code so it loads the update: close it, then type  claude" 'Green'
