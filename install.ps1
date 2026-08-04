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

# 4) session reflex hook - the "wired, not prose" layer. SessionStart hooks only PRINT; they cannot
# block, refuse, or trap a turn, so this can never lock her out. Idempotent; backs up settings first;
# skips entirely if settings.json exists but does not parse (never corrupt a file we can't read).
$hookSrc = Join-Path $here 'hooks\mom_session_reflex.ps1'
if (Test-Path $hookSrc) {
  $hookDir = Join-Path $claude 'hooks'
  New-Item -ItemType Directory -Force $hookDir | Out-Null
  $hookDst = Join-Path $hookDir 'mom_session_reflex.ps1'
  Copy-Item $hookSrc $hookDst -Force
  $cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$hookDst`""
  $setPath = Join-Path $claude 'settings.json'
  $settings = $null; $readable = $true
  if (Test-Path $setPath) {
    try { $settings = Get-Content $setPath -Raw | ConvertFrom-Json } catch { $readable = $false }
  }
  if (-not $readable) {
    Say "[hook] settings.json exists but does not parse - left untouched. Reflex hook copied, not wired." 'Red'
  } else {
    if (-not $settings) { $settings = [pscustomobject]@{} }
    if (-not $settings.PSObject.Properties['hooks']) {
      $settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) }
    if (-not $settings.hooks.PSObject.Properties['SessionStart']) {
      $settings.hooks | Add-Member -NotePropertyName SessionStart -NotePropertyValue @() }
    $already = ($settings | ConvertTo-Json -Depth 20) -match 'mom_session_reflex'
    if ($already) { Say "[hook] session reflex already wired" 'DarkGray' }
    else {
      if (Test-Path $setPath) { Copy-Item $setPath "$setPath.bak_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force }
      $entry = [pscustomobject]@{ hooks = @([pscustomobject]@{ type = 'command'; command = $cmd }) }
      # NOTE: the @( ) around the whole pipeline is load-bearing. Without it the pipeline unrolls to a
      # single object and ConvertTo-Json emits SessionStart as an OBJECT, not an ARRAY - Claude Code
      # then ignores the hook while the installer still prints "WIRED". Verified in a sandbox 2026-08-04.
      $settings.hooks.SessionStart = @(@($settings.hooks.SessionStart) + $entry | Where-Object { $_ })
      $settings | ConvertTo-Json -Depth 20 | Set-Content $setPath -Encoding UTF8
      try {
        Get-Content $setPath -Raw | ConvertFrom-Json | Out-Null
        Say "[hook] session reflex WIRED - the laws now load every session, not just when read" 'Green'
      } catch {
        $bk = Get-ChildItem "$setPath.bak_*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($bk) { Copy-Item $bk.FullName $setPath -Force; Say "[hook] wiring produced invalid JSON - ROLLED BACK" 'Red' }
      }
    }
  }
}

Say "`n=== DONE ===" 'Cyan'
Say "Restart Claude Code so it loads the update: close it, then type  claude" 'Green'
