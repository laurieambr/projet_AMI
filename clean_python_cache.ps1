# Script de nettoyage du cache Python
Write-Host "Nettoyage du cache Python..." -ForegroundColor Blue

# Supprimer les fichiers .pyc
Write-Host "Suppression des fichiers .pyc..." -ForegroundColor Yellow
$pycFiles = Get-ChildItem -Path . -Recurse -Filter "*.pyc" -ErrorAction SilentlyContinue
if ($pycFiles) {
    $pycFiles | Remove-Item -Force
    Write-Host "Supprime $($pycFiles.Count) fichiers .pyc" -ForegroundColor Green
} else {
    Write-Host "Aucun fichier .pyc trouve" -ForegroundColor Green
}

# Supprimer les dossiers __pycache__
Write-Host "Suppression des dossiers __pycache__..." -ForegroundColor Yellow
$pycacheDirs = Get-ChildItem -Path . -Recurse -Directory -Name "__pycache__" -ErrorAction SilentlyContinue
if ($pycacheDirs) {
    $pycacheDirs | ForEach-Object { Remove-Item -Path $_ -Recurse -Force }
    Write-Host "Supprime $($pycacheDirs.Count) dossiers __pycache__" -ForegroundColor Green
} else {
    Write-Host "Aucun dossier __pycache__ trouve" -ForegroundColor Green
}

# Vider le cache de pip
Write-Host "Nettoyage du cache pip..." -ForegroundColor Yellow
try {
    pip cache purge
    Write-Host "Cache pip vide" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du nettoyage du cache pip: $($_.Exception.Message)" -ForegroundColor Red
}

# Supprimer les fichiers .pyo (anciens fichiers Python optimisés)
Write-Host "Suppression des fichiers .pyo..." -ForegroundColor Yellow
$pyoFiles = Get-ChildItem -Path . -Recurse -Filter "*.pyo" -ErrorAction SilentlyContinue
if ($pyoFiles) {
    $pyoFiles | Remove-Item -Force
    Write-Host "Supprime $($pyoFiles.Count) fichiers .pyo" -ForegroundColor Green
} else {
    Write-Host "Aucun fichier .pyo trouve" -ForegroundColor Green
}

Write-Host "Nettoyage termine!" -ForegroundColor Green 