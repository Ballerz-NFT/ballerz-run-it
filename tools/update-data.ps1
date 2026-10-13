<#
  Rebuilds the embedded Baller dataset inside index.html.

  Usage (from the repo root):
    pwsh tools/update-data.ps1                 # fetch rosters from ballerz.com, then rewrite index.html
    pwsh tools/update-data.ps1 -FromJson x.json  # skip the fetch, use a saved roster dump

  The fetch reads the ~47 public team pages (one request per team, ~1s apart) and
  rewrites the block between the DATA:START / DATA:END markers in index.html.
#>
param(
  [string]$FromJson,
  [string]$Index = (Join-Path $PSScriptRoot '..\index.html')
)
$ErrorActionPreference = 'Stop'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124 Safari/537.36'

if ($FromJson) {
  $balls = Get-Content $FromJson -Raw | ConvertFrom-Json
} else {
  $idx = (Invoke-WebRequest -UseBasicParsing -Uri 'https://ballerz.com/teams' -UserAgent $ua).Content -replace '\\"','"'
  $slugs = [regex]::Matches($idx, 'href="/teams/([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  Write-Host "teams: $($slugs.Count)"
  $all = @{}
  foreach ($s in $slugs) {
    Start-Sleep -Milliseconds 900
    $html = (Invoke-WebRequest -UseBasicParsing -Uri "https://ballerz.com/teams/$s" -UserAgent $ua).Content -replace '\\"','"'
    foreach ($m in [regex]::Matches($html, '\{"id":\d+,"team":"[^"]*"[^{}]*\}')) {
      $o = $m.Value | ConvertFrom-Json
      if ($null -ne $o.dunks -and -not $all.ContainsKey([int]$o.id)) { $all[[int]$o.id] = $o }
    }
    Write-Host ("{0,-28} total {1}" -f $s, $all.Count)
  }
  $balls = $all.Values | Sort-Object id
}

$teams  = @($balls | ForEach-Object { $_.team } | Sort-Object -Unique)
$bodies = @($balls | ForEach-Object { $_.body } | Sort-Object -Unique)
$accs   = @($balls | ForEach-Object { $_.accessories } | Where-Object { $_ -and $_ -ne 'None' } | Sort-Object -Unique)
$roles  = @('Player','Captain','All-Star')
$tIdx = @{}; for ($i=0;$i -lt $teams.Count;$i++)  { $tIdx[$teams[$i]]  = $i }
$bIdx = @{}; for ($i=0;$i -lt $bodies.Count;$i++) { $bIdx[$bodies[$i]] = $i }
$aIdx = @{}; for ($i=0;$i -lt $accs.Count;$i++)   { $aIdx[$accs[$i]]   = $i }

$rows = foreach ($b in ($balls | Sort-Object id)) {
  $r = [array]::IndexOf($roles, $b.role); if ($r -lt 0) { $r = 0 }
  $g = switch ($b.gender) { 'M' {0} 'W' {1} default {2} }
  $a = ($b.accessories | Where-Object { $_ -and $_ -ne 'None' } | ForEach-Object { $aIdx[$_] }) -join '.'
  '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11}' -f $b.id,$tIdx[$b.team],$b.number,$b.dunks,$b.shooting,$b.playmaking,$b.defense,$r,[int][bool]$b.mvp,$bIdx[$b.body],$g,$a
}

$q = { param($x) '"' + ($x -replace '"','\"') + '"' }
$block = @(
  '/*DATA:START*/',
  'const DATA={',
  ('teams:[' + (($teams  | ForEach-Object { & $q $_ }) -join ',') + '],'),
  ('bodies:[' + (($bodies | ForEach-Object { & $q $_ }) -join ',') + '],'),
  ('accs:[' + (($accs   | ForEach-Object { & $q $_ }) -join ',') + '],'),
  ('rows:"' + ($rows -join ';') + '"'),
  '};',
  '/*DATA:END*/'
) -join "`n"

$html = Get-Content $Index -Raw -Encoding UTF8
$pattern = '(?s)/\*DATA:START\*/.*?/\*DATA:END\*/'
if ($html -notmatch $pattern) { throw "DATA markers not found in $Index" }
$html = [regex]::Replace($html, $pattern, { param($m) $block })
[System.IO.File]::WriteAllText((Resolve-Path $Index), $html, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "Wrote $($rows.Count) ballerz into $Index"
