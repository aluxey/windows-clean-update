param(
  [string]$Root = 'D:\Image',
  [ValidateSet('list','move','delete')][string]$Action = 'list',
  [string]$Quarantine = 'D:\QUARANTAINE_DUPS',
  [ValidateSet('oldest','newest')][string]$Keep = 'oldest',
  [int]$MinSizeMB = 0,
  $OnlyExt = @(
  'jpg','jpeg','png','gif','bmp','tiff','tif','webp','heic','heif','jp2','j2k','jpf','jpx','jpm','mj2',
  'ico','cur','raw','cr2','nef','arw','dng','raf','orf','sr2','pef','x3f','psd','ai','eps',
  'mp4','mov','mkv','avi','webm','flv','wmv','mpg','mpeg','m2v','3gp','3g2','m4v','ts','mts','m2ts',
  'vob','ogv','rm','rmvb','asf','f4v','divx'
  ),
  [string]$Report = (Join-Path $env:USERPROFILE 'Desktop\duplicates_report.csv'),
  [switch]$Apply
)

if (-not (Test-Path -LiteralPath $Root)) { throw "Le dossier racine n'existe pas : $Root" }
$RootResolved  = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\')
$MinSizeBytes  = [int64]$MinSizeMB * 1MB
$ExtFilterOn   = ($OnlyExt -ne $null -and $OnlyExt.Count -gt 0)
if ($ExtFilterOn) { $OnlyExt = $OnlyExt | ForEach-Object { $_.ToLower().TrimStart('.') } }

function Get-RelativePath([string]$root, [string]$full) {
  $root = $root.TrimEnd('\') + '\'
  try {
    $uRoot = [Uri]("file:///" + $root.Replace('\','/'))
    $uFull = [Uri]("file:///" + $full.Replace('\','/'))
    $rel = [Uri]::UnescapeDataString($uRoot.MakeRelativeUri($uFull).ToString()).Replace('/','\')
    if ([string]::IsNullOrWhiteSpace($rel) -or $rel -eq ".") { return [IO.Path]::GetFileName($full) }
    return $rel
  } catch {
    if ($full.Length -gt $root.Length -and $full.Substring(0,$root.Length).Equals($root,[StringComparison]::OrdinalIgnoreCase)) {
      return $full.Substring($root.Length).TrimStart('\')
    }
    return [IO.Path]::GetFileName($full)
  }
}
function Get-UniqueDest([string]$dest) {
  if (-not (Test-Path -LiteralPath $dest)) { return $dest }
  $dir  = Split-Path -Path $dest -Parent
  $name = [System.IO.Path]::GetFileNameWithoutExtension($dest)
  $ext  = [System.IO.Path]::GetExtension($dest)
  $i = 1
  do {
    $candidate = Join-Path $dir ("{0}__DUP{1}{2}" -f $name, $i, $ext)
    $i++
  } until (-not (Test-Path -LiteralPath $candidate))
  return $candidate
}

Write-Host "[+] Scan racine : $RootResolved"
Write-Host "[+] Action      : $Action  | Apply=$($Apply.IsPresent)"
Write-Host "[+] Keep        : $Keep"
Write-Host "[+] Min size    : $MinSizeMB MB"
Write-Host "[+] Extensions  : " -NoNewline; if ($ExtFilterOn) { Write-Host ($OnlyExt -join ',') } else { Write-Host "Toutes" }
Write-Host "[+] Rapport CSV : $Report"; if ($Action -eq 'move') { Write-Host "[+] Quarantaine : $Quarantine" }

Write-Host "`n[1/3] Énumération des fichiers..."
$files = Get-ChildItem -LiteralPath $RootResolved -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Length -ge $MinSizeBytes -and
    (-not $ExtFilterOn -or ($OnlyExt -contains ($_.Extension.TrimStart('.').ToLower())))
  }
if (-not $files) { Write-Host "Aucun fichier après filtrage."; return }

Write-Host "[2/3] Pré-groupement par taille..."
$sizeGroups = $files | Group-Object -Property Length | Where-Object { $_.Count -gt 1 }
if (-not $sizeGroups) { Write-Host "Pas de groupes >1 par taille. ✅"; return }

Write-Host "[3/3] Calcul des SHA-256..."
$hashed = New-Object System.Collections.Generic.List[object]
$idx=0; $total=$sizeGroups.Count
foreach ($sg in $sizeGroups) {
  $idx++; Write-Progress -Activity "Hash" -Status "$idx / $total" -PercentComplete ([int](100*$idx/$total))
  foreach ($f in $sg.Group) {
    try {
      $h = Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName -ErrorAction Stop
      $hashed.Add([PSCustomObject]@{
        FullName  = $f.FullName
        Size      = $f.Length
        LastWrite = $f.LastWriteTimeUtc
        Hash      = $h.Hash
      })
    } catch {
      Write-Host "[WARN] Hash impossible : $($f.FullName)" -ForegroundColor Yellow
    }
  }
}
Write-Progress -Activity "Hash" -Completed
$dupGroups = $hashed | Group-Object -Property Hash | Where-Object { $_.Count -gt 1 }
if (-not $dupGroups) { Write-Host "Aucun doublon exact. ✅"; return }

# Rapport CSV
$rows = New-Object System.Collections.Generic.List[object]
$gid=0; $potential=[int64]0
foreach ($g in $dupGroups) {
  $gid++
  $sorted = if ($Keep -eq 'oldest') { $g.Group | Sort-Object LastWrite } else { $g.Group | Sort-Object LastWrite -Descending }
  $keeper = $sorted[0]
  $dups   = $sorted | Where-Object { $_.FullName -ne $keeper.FullName }
  foreach ($item in $sorted) {
    $rel = Get-RelativePath -root $RootResolved -full $item.FullName
    $rows.Add([PSCustomObject]@{
      group_id   = $gid
      sha256     = $g.Name
      role       = ($(if ($item.FullName -eq $keeper.FullName) { 'KEEP' } else { 'DUP' }))
      size_bytes = $item.Size
      mtime_utc  = [int][double]([DateTimeOffset]$item.LastWrite).ToUnixTimeSeconds()
      relpath    = $rel
      abspath    = $item.FullName
    })
  }
  foreach ($d in $dups) { $potential += [int64]$d.Size }
}
$rows | Sort-Object group_id, role -Descending | Export-Csv -Path $Report -NoTypeInformation -Encoding UTF8
Write-Host "`n[+] Groupes : $($dupGroups.Count)"
Write-Host "[+] Espace potentiel : $([math]::Round($potential/1MB,2)) MB"
Write-Host "[+] Rapport : $Report`n"

switch ($Action) {
  'list' {
    Write-Host "[i] list (dry-run). Rien modifié."
  }
  'move' {
    if (-not $Apply) { Write-Host "[i] Dry-run. Ajoute -Apply pour déplacer."; break }
    if (-not (Test-Path -LiteralPath $Quarantine)) { New-Item -ItemType Directory -Force -Path $Quarantine | Out-Null }
    $moved = 0
    foreach ($g in $dupGroups) {
      $sorted = if ($Keep -eq 'oldest') { $g.Group | Sort-Object LastWrite } else { $g.Group | Sort-Object LastWrite -Descending }
      $keeper = $sorted[0]
      $dups   = $sorted | Where-Object { $_.FullName -ne $keeper.FullName }
      foreach ($d in $dups) {
        $rel = Get-RelativePath -root $RootResolved -full $d.FullName
        if ([string]::IsNullOrWhiteSpace($rel)) { $rel = [IO.Path]::GetFileName($d.FullName) }
        $dest    = Join-Path -Path $Quarantine -ChildPath $rel
        $destDir = [System.IO.Path]::GetDirectoryName($dest)
        if (-not [string]::IsNullOrWhiteSpace($destDir) -and -not (Test-Path -LiteralPath $destDir)) {
          [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
        }
        $final = Get-UniqueDest -dest $dest
        try {
          Move-Item -LiteralPath $d.FullName -Destination $final -Force -ErrorAction Stop
          $moved++
          Write-Host "[moved] $($d.FullName) -> $final"
        } catch {
          Write-Host "[error] Déplacement impossible : $($d.FullName) ($_)" -ForegroundColor Yellow
        }
      }
    }
    Write-Host "`n[+] Fichiers déplacés : $moved"
  }
  'delete' {
    if (-not $Apply) { Write-Host "[i] Dry-run. Ajoute -Apply pour supprimer."; break }
    $deleted = 0
    foreach ($g in $dupGroups) {
      $sorted = if ($Keep -eq 'oldest') { $g.Group | Sort-Object LastWrite } else { $g.Group | Sort-Object LastWrite -Descending }
      $keeper = $sorted[0]
      $dups   = $sorted | Where-Object { $_.FullName -ne $keeper.FullName }
      foreach ($d in $dups) {
        try {
          Remove-Item -LiteralPath $d.FullName -Force -ErrorAction Stop
          $deleted++
          Write-Host "[deleted] $($d.FullName)"
        } catch {
          Write-Host "[error] Suppression impossible : $($d.FullName) ($_)" -ForegroundColor Yellow
        }
      }
    }
    Write-Host "`n[+] Fichiers supprimés : $deleted"
  }
}
