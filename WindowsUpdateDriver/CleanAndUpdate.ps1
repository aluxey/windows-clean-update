#--- Vérification de l'élévation ---
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
     ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "❌ Ce script doit être lancé en tant qu’administrateur !" -Category Security
    Break
}

#--- Module PSWindowsUpdate ---
Function Install-PSWindowsUpdate {
    If (-Not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "[INFO] Installation de PSWindowsUpdate…" -ForegroundColor Cyan
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Install-Module -Name PSWindowsUpdate -Force
    }
    Import-Module PSWindowsUpdate
}

#--- Mises à jour Windows (sans reboot) ---
Function Update-Windows {
    Write-Host "[INFO] Recherche et installation des mises à jour Windows…" -ForegroundColor Cyan
    # -IgnoreReboot : n’interrompt pas le script par un reboot
    $results = Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -Verbose
    # Détecter si un reboot sera nécessaire
    $needsReboot = $results | Where-Object RestartRequired -eq $true
    return ($needsReboot -ne $null)
}

#--- Mise à jour des paquets utilisateurs ---
Function Update-PackageManagers {
    If (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "[INFO] Mise à jour Chocolatey…" -ForegroundColor Cyan
        choco upgrade all -y
    }
    If (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "[INFO] Mise à jour Winget…" -ForegroundColor Cyan
        winget upgrade --all --silent
    }
}

#--- Nettoyage des temporaires ---
Function Clean-TempFolders {
    $paths = @(
        $env:TEMP,
        "$env:SystemRoot\Temp",
        "$env:LOCALAPPDATA\Temp"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Write-Host "[INFO] Nettoyage de $p…" -ForegroundColor Cyan
            Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

#--- Nettoyage DISM et Compact OS ---
Function Clean-DISM {
    Write-Host "[INFO] Nettoyage des composants Windows (DISM)..." -ForegroundColor Cyan
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
}
Function Compact-OS {
    Write-Host "[INFO] Compactage de l'OS (CompactOS)..." -ForegroundColor Cyan
    Compact.exe /CompactOS:always
}

#--- Vidage des journaux d’événements ---
Function Clear-EventLogs {
    Write-Host "[INFO] Vidage des journaux d'événements..." -ForegroundColor Cyan
    Get-WinEvent -ListLog * |
      ForEach-Object { wevtutil cl $_.LogName } 2>$null
}

#--- Ancien point de restauration (optionnel) ---
Function Remove-OldRestorePoints {
    Write-Host "[INFO] Suppression des anciens points de restauration..." -ForegroundColor Cyan
    Enable-ComputerRestore -Drive "C:\"
    vssadmin delete shadows /For=C: /Oldest | Out-Null
}

#--- Exécution du workflow ---
Install-PSWindowsUpdate
$rebootNeeded = Update-Windows
Update-PackageManagers
Clean-TempFolders
Clean-DISM
Compact-OS
Clear-EventLogs
# Uncomment the next line to remove old restore points
# Remove-OldRestorePoints

#--- Redémarrage final ---
if ($rebootNeeded) {
    Write-Host "⚠️ Redémarrage requis. Le PC va redémarrer dans 1 minute…" -ForegroundColor Yellow
    shutdown /r /t 60 /c "Reboot après nettoyage complet"
} else {
    Write-Host "✅ Aucune relance nécessaire. Votre système est à jour et propre !" -ForegroundColor Green
}
