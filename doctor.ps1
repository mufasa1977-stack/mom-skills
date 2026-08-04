<#
  doctor.ps1 - one command that CHECKS and REPAIRS this machine's Claude setup.
  Built 2026-08-04 after a Windows "Can't open this app" repair on Mom's PC: an MSIX repair can roll
  app state back, so "it opens again" is not proof the brain, skills, memory and hook survived.

  CHECKS (and fixes what is safe to fix automatically):
    1. brain      ~/.claude/CLAUDE.md exists and contains the five-laws section
    2. skills     every folder has a top-level SKILL.md, and NO nested duplicate (skills/x/x/)
    3. memory     ~/.claude/memory/MEMORY.md exists and is not empty
    4. hook       hooks/mom_session_reflex.ps1 present AND wired into settings.json SessionStart
    5. python     python on PATH (cross-model-verify and other skills need it)
    6. cli        the `claude` command resolves

  SAFE: read-only except for (a) de-nesting buried skill folders, (b) re-running install.ps1 when the
  brain or hook is missing/stale. Backs up settings.json before any wiring. Never deletes user data,
  never touches ~/.claude/memory contents. ASCII-only, exits 0 always.
  Run:  powershell -ExecutionPolicy Bypass -File .\doctor.ps1
#>
$ErrorActionPreference = 'Continue'
function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }
$here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$claude = Join-Path $env:USERPROFILE '.claude'
$fail = @(); $fixed = @()

Say "=== CLAUDE DOCTOR on $env:COMPUTERNAME ===" 'Cyan'

# --- 1. brain -----------------------------------------------------------------
$brain = Join-Path $claude 'CLAUDE.md'
$brainOK = (Test-Path $brain) -and ((Get-Content $brain -Raw) -match 'five laws that stop you sliding backwards')
if ($brainOK) { Say "[ok]   brain present and current" 'Green' }
else          { Say "[FAIL] brain missing or stale" 'Red'; $fail += 'brain' }

# --- 2. skills ----------------------------------------------------------------
$skillsDir = Join-Path $claude 'skills'
$nested = @(); $noManifest = @(); $count = 0
if (Test-Path $skillsDir) {
  foreach ($d in (Get-ChildItem $skillsDir -Directory)) {
    $count++
    $dup = Join-Path $d.FullName $d.Name
    if (Test-Path $dup) { Remove-Item $dup -Recurse -Force -EA SilentlyContinue; $nested += $d.Name }
    if (-not (Test-Path (Join-Path $d.FullName 'SKILL.md'))) { $noManifest += $d.Name }
  }
}
if ($nested)     { Say ("[FIXED] de-nested buried skills: " + ($nested -join ', ')) 'Yellow'; $fixed += 'skills-denested' }
if ($noManifest) { Say ("[FAIL] folders with no SKILL.md: " + ($noManifest -join ', ')) 'Red'; $fail += 'skills' }
Say "[info] $count skill folder(s) installed" 'Gray'
if ($count -lt 10) { Say "[FAIL] expected 10+ skills - the package did not install fully" 'Red'; $fail += 'skills-count' }

# --- 3. memory ----------------------------------------------------------------
$idx = Join-Path $claude 'memory\MEMORY.md'
if ((Test-Path $idx) -and ((Get-Item $idx).Length -gt 0)) { Say "[ok]   memory index present" 'Green' }
else { Say "[FAIL] memory index missing or empty" 'Red'; $fail += 'memory' }

# --- 4. session reflex hook ---------------------------------------------------
$hookFile = Join-Path $claude 'hooks\mom_session_reflex.ps1'
$setPath  = Join-Path $claude 'settings.json'
$wired = $false
if (Test-Path $setPath) {
  try { $wired = ((Get-Content $setPath -Raw) -match 'mom_session_reflex') } catch { $wired = $false }
}
if ((Test-Path $hookFile) -and $wired) { Say "[ok]   session reflex hook wired" 'Green' }
else { Say "[FAIL] session reflex hook missing or not wired" 'Red'; $fail += 'hook' }

# --- 5/6. python + cli --------------------------------------------------------
$py = (Get-Command python -EA SilentlyContinue)
if ($py) { Say ("[ok]   python: " + (& python --version 2>&1)) 'Green' } else { Say "[FAIL] python not on PATH" 'Red'; $fail += 'python' }
$cli = (Get-Command claude -EA SilentlyContinue)
if ($cli) { Say "[ok]   claude CLI found: $($cli.Source)" 'Green' } else { Say "[warn] claude CLI not on PATH (desktop app may still be fine)" 'Yellow' }

# --- REPAIR -------------------------------------------------------------------
if ($fail -contains 'brain' -or $fail -contains 'hook' -or $fail -contains 'skills-count' -or $fail -contains 'skills') {
  $inst = Join-Path $here 'install.ps1'
  if (Test-Path $inst) {
    Say "`n--- repairing: re-running install.ps1 ---" 'Cyan'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $inst
    $fixed += 'reinstalled'
  } else { Say "[FAIL] install.ps1 not next to doctor.ps1 - run this from the mom-brain folder" 'Red' }
}

Say "`n=== RESULT ===" 'Cyan'
if ($fixed) { Say ("REPAIRED: " + ($fixed -join ', ')) 'Green' }
if ($fail)  { Say ("WAS BROKEN: " + ($fail -join ', ') + " - re-run this script to confirm the repair took") 'Yellow' }
else        { Say "ALL CHECKS PASSED - nothing was broken" 'Green' }
Say "Restart Claude Code afterwards so the brain and hook load (skills load immediately)." 'Cyan'
exit 0
