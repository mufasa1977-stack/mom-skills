<#
  unfreeze.ps1 - recover a Windows machine that is stuck/frozen after a Claude app problem.
  Built 2026-08-04 (Mom's PC froze right after an MSIX "Repair" of the Claude desktop app).

  RUN IT EVEN IF THE DESKTOP IS DEAD:
    Ctrl+Shift+Esc  (or Ctrl+Alt+End inside Chrome Remote Desktop) -> Task Manager
    -> File -> Run new task -> tick "Create this task with administrative privileges" is NOT needed
    -> paste:   powershell -ExecutionPolicy Bypass -File %USERPROFILE%\mom-brain\unfreeze.ps1

  WHAT IT DOES, in escalating order (stops as soon as something works):
    1. reports which Claude-related processes are running and whether they are RESPONDING
    2. ends only the NOT-RESPONDING Claude processes (a healthy one is left alone)
    3. if the desktop shell itself is hung, restarts explorer.exe
    4. clears a stuck AppX servicing operation, the usual cause of a freeze right after a Repair
  It never touches documents, never signs anyone out, never reboots. Exits 0 always.

  -DryRun  : print what WOULD be ended, change nothing. Use this first if unsure.
#>
param([switch]$DryRun)
$ErrorActionPreference = 'Continue'
function Say($m,$c='Gray'){ Write-Host $m -ForegroundColor $c }
$acted = @()

Say "=== UNFREEZE on $env:COMPUTERNAME ===" 'Cyan'
if ($DryRun) { Say "(DRY RUN - nothing will be ended)" 'Yellow' }

# --- 1/2. Claude processes ----------------------------------------------------
$names = @('claude','Claude','AnthropicClaude','claude-desktop')
$procs = @()
foreach ($n in $names) { $procs += @(Get-Process -Name $n -EA SilentlyContinue) }
$procs = $procs | Sort-Object Id -Unique
if (-not $procs) { Say "[info] no Claude process running" 'Gray' }
foreach ($p in $procs) {
  $resp = $true
  try { $resp = $p.Responding } catch { $resp = $true }
  Say ("[proc] {0} pid={1} responding={2}" -f $p.ProcessName, $p.Id, $resp) 'Gray'
  if (-not $resp) {
    if ($DryRun) { Say "        would END this one (not responding)" 'Yellow' }
    else {
      try { Stop-Process -Id $p.Id -Force -EA Stop; Say "        ENDED (was not responding)" 'Green'; $acted += "killed:$($p.ProcessName)" }
      catch { Say "        could not end: $($_.Exception.Message)" 'Red' }
    }
  }
}

# --- 3. desktop shell ---------------------------------------------------------
$exp = @(Get-Process -Name explorer -EA SilentlyContinue)
$shellDead = ($exp.Count -eq 0)
$shellHung = $false
foreach ($e in $exp) { try { if (-not $e.Responding) { $shellHung = $true } } catch {} }
if ($shellDead -or $shellHung) {
  Say ("[shell] explorer is " + $(if($shellDead){"NOT RUNNING"}else{"HUNG"})) 'Yellow'
  if ($DryRun) { Say "        would restart explorer.exe" 'Yellow' }
  else {
    if ($shellHung) { Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep -Seconds 2 }
    Start-Process explorer.exe
    Say "        restarted explorer.exe - the desktop and taskbar should come back" 'Green'
    $acted += 'explorer-restarted'
  }
} else { Say "[shell] explorer is running and responding" 'Green' }

# --- 4. stuck AppX servicing (classic freeze right after a Repair) -------------
$appx = @(Get-Process -Name AppXSvc,AppXDeploymentClient,wsappx -EA SilentlyContinue)
if ($appx) {
  Say "[appx] Store/AppX servicing is active - this is what hangs a machine right after a Repair." 'Yellow'
  Say "       Give it 2-3 minutes to finish on its own before doing anything drastic." 'Yellow'
} else { Say "[appx] no AppX servicing in progress" 'Green' }

Say "`n=== RESULT ===" 'Cyan'
if ($acted) { Say ("ACTIONS: " + ($acted -join ', ')) 'Green' } else { Say "No hung process found to end." 'Gray' }
Say "If the machine is STILL frozen, nothing software-side can reach it: hold the power button ~10s," 'Cyan'
Say "wait, power on, then run doctor.ps1 to confirm the Claude setup survived." 'Cyan'
exit 0
