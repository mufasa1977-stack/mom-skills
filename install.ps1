<#
  install.ps1 - installs/refreshes the mom-brain package into ~/.claude
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

# 2) skills (replace each folder cleanly = refresh to latest)
# FIX 2026-08-03: Copy-Item into an EXISTING folder NESTS it (skills/x/x/SKILL.md). A nested skill does
# not load, so every re-install quietly buried the skills one level deeper and Claude "lost" abilities.
# We now (a) delete any nested duplicate left behind by older installs, (b) replace instead of merge.
$skillsDst = Join-Path $claude 'skills'
Get-ChildItem $skillsDst -Directory -EA SilentlyContinue | ForEach-Object {
  $nested = Join-Path $_.FullName $_.Name
  if (Test-Path $nested) { Remove-Item $nested -Recurse -Force -EA SilentlyContinue; Say "[repair] removed nested copy in $($_.Name)" 'Yellow' }
}
$skillsSrc = Join-Path $here 'skills'
if (Test-Path $skillsSrc) {
  $n = 0
  Get-ChildItem $skillsSrc -Directory | ForEach-Object {
    $dst = Join-Path $skillsDst $_.Name
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    Copy-Item $_.FullName $dst -Recurse -Force; $n++
  }
  Say "[skills] $n skill folder(s) synced into ~/.claude/skills" 'Green'
  $bad = @(Get-ChildItem $skillsDst -Directory | Where-Object { -not (Test-Path (Join-Path $_.FullName 'SKILL.md')) })
  if ($bad) { Say ("[warn] folders with NO SKILL.md (will not load): " + ($bad.Name -join ', ')) 'Red' }
  else { Say "[verify] every skill folder has a SKILL.md at its top level" 'Green' }
}

# 3) memory scaffold (create only if missing - never clobber her memories)
$idx = Join-Path $claude 'memory\MEMORY.md'
if (-not (Test-Path $idx)) {
@'
# Memory Index
> One line per memory. Skim at the start of each session; open any that look relevant.
> Save durable facts as ~/.claude/memory/<name>.md and add a pointer line here.

- [about-me](about-me.md) - who I am and how I like to be helped
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
