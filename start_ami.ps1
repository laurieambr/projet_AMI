# Script de lancement pour le projet AMI (Windows PowerShell)
# Lance le serveur API et l'interface Streamlit

Write-Host "Demarrage du projet AMI..." -ForegroundColor Green

# Verification de l'environnement virtuel
if (-not $env:VIRTUAL_ENV) {
    Write-Host "Environnement virtuel non active!" -ForegroundColor Red
    Write-Host "Veuillez activer l'environnement virtuel avec:" -ForegroundColor Yellow
    Write-Host "llm_env\Scripts\activate" -ForegroundColor Cyan
    exit 1
}

Write-Host "Environnement virtuel active: $env:VIRTUAL_ENV" -ForegroundColor Green

# Verification des dependances
Write-Host "Verification des dependances..." -ForegroundColor Blue

# Verifier si uvicorn est installe
try {
    uvicorn --version | Out-Null
    Write-Host "uvicorn trouve" -ForegroundColor Green
} catch {
    Write-Host "uvicorn non trouve. Installation..." -ForegroundColor Yellow
    pip install uvicorn
}

# Verifier si streamlit est installe
try {
    streamlit --version | Out-Null
    Write-Host "streamlit trouve" -ForegroundColor Green
} catch {
    Write-Host "streamlit non trouve. Installation..." -ForegroundColor Yellow
    pip install streamlit
}

# Verifier si requests est installe
try {
    python -c "import requests" 2>$null
    Write-Host "requests trouve" -ForegroundColor Green
} catch {
    Write-Host "requests non trouve. Installation..." -ForegroundColor Yellow
    pip install requests
}

Write-Host "Dependances verifiees" -ForegroundColor Green

# Verification du modele
$MODEL_PATH = ".\DeepSeek-R1-Distill-Llama-3B-Q4_K_M.gguf"
if (-not (Test-Path $MODEL_PATH)) {
    Write-Host "Modele non trouve: $MODEL_PATH" -ForegroundColor Red
    Write-Host "Veuillez telecharger le modele depuis:" -ForegroundColor Yellow
    Write-Host "https://huggingface.co/hassenhamdi/DeepSeek-R1-Distill-Llama-3B-GGUF" -ForegroundColor Cyan
    exit 1
}

Write-Host "Modele trouve: $MODEL_PATH" -ForegroundColor Green

# Verification du fichier app.py du client
$CLIENT_APP_PATH = ".\client\app.py"
if (-not (Test-Path $CLIENT_APP_PATH)) {
    Write-Host "Fichier app.py non trouve dans le dossier client!" -ForegroundColor Red
    exit 1
}

Write-Host "Fichier app.py trouve: $CLIENT_APP_PATH" -ForegroundColor Green

# Configuration des variables d'environnement
$env:SERVEUR_IP = "localhost"
$env:SERVEUR_PORT = "8000"

Write-Host "Configuration:" -ForegroundColor Blue
Write-Host "   - Serveur IP: $env:SERVEUR_IP" -ForegroundColor White
Write-Host "   - Serveur Port: $env:SERVEUR_PORT" -ForegroundColor White

# Fonction de nettoyage
function Cleanup {
    Write-Host ""
    Write-Host "Arret des services..." -ForegroundColor Yellow
    
    if ($API_Process) {
        Stop-Process -Id $API_Process.Id -Force -ErrorAction SilentlyContinue
    }
    
    if ($STREAMLIT_Process) {
        Stop-Process -Id $STREAMLIT_Process.Id -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "Services arretes" -ForegroundColor Green
    exit 0
}

# Capture du signal d'interruption
Register-EngineEvent PowerShell.Exiting -Action { Cleanup }

# Lancement du serveur API en arriere-plan
Write-Host "Lancement du serveur API..." -ForegroundColor Blue
$API_Process = Start-Process -FilePath "uvicorn" -ArgumentList "main:app", "--host", $env:SERVEUR_IP, "--port", $env:SERVEUR_PORT -PassThru -WindowStyle Hidden

# Attendre que le serveur API demarre
Write-Host "Attente du demarrage du serveur API..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verification que le serveur API fonctionne
$retryCount = 0
$maxRetries = 5
$apiReady = $false

while ($retryCount -lt $maxRetries -and -not $apiReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://$($env:SERVEUR_IP):$($env:SERVEUR_PORT)/" -UseBasicParsing -TimeoutSec 10
        $apiReady = $true
        Write-Host "Serveur API demarre" -ForegroundColor Green
    } catch {
        $retryCount++
        Write-Host "Tentative $retryCount/$maxRetries - Attente du serveur API..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
}

if (-not $apiReady) {
    Write-Host "Le serveur API n'a pas demarre correctement" -ForegroundColor Red
    Cleanup
    exit 1
}

# Lancement de Streamlit en arriere-plan avec les variables d'environnement
Write-Host "Lancement de l'interface Streamlit..." -ForegroundColor Blue

# Creation des variables d'environnement pour Streamlit
$envVars = @{
    "SERVEUR_IP" = $env:SERVEUR_IP
    "SERVEUR_PORT" = $env:SERVEUR_PORT
}

# Definir les variables d'environnement temporairement
$originalSERVEUR_IP = $env:SERVEUR_IP
$originalSERVEUR_PORT = $env:SERVEUR_PORT

$STREAMLIT_Process = Start-Process -FilePath "streamlit" -ArgumentList "run", "app.py", "--server.port", "8501", "--server.address", "localhost", "--server.headless", "true" -WorkingDirectory "client" -PassThru -WindowStyle Hidden

# Attendre que Streamlit demarre
Write-Host "Attente du demarrage de Streamlit..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Verification que Streamlit fonctionne
$retryCount = 0
$maxRetries = 5
$streamlitReady = $false

while ($retryCount -lt $maxRetries -and -not $streamlitReady) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8501" -UseBasicParsing -TimeoutSec 10
        $streamlitReady = $true
        Write-Host "Interface Streamlit demarree" -ForegroundColor Green
    } catch {
        $retryCount++
        Write-Host "Tentative $retryCount/$maxRetries - Attente de Streamlit..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
}

if (-not $streamlitReady) {
    Write-Host "Streamlit n'a pas demarre correctement" -ForegroundColor Red
    Write-Host "Verification des processus..." -ForegroundColor Yellow
    
    # Vérifier si le processus Streamlit existe
    $streamlitProcesses = Get-Process -Name "streamlit" -ErrorAction SilentlyContinue
    if ($streamlitProcesses) {
        Write-Host "Processus Streamlit trouve: $($streamlitProcesses.Count) processus" -ForegroundColor Yellow
        foreach ($proc in $streamlitProcesses) {
            Write-Host "  - PID: $($proc.Id), Memoire: $([math]::Round($proc.WorkingSet/1MB, 2)) MB" -ForegroundColor White
        }
    } else {
        Write-Host "Aucun processus Streamlit trouve" -ForegroundColor Red
    }
    
    Cleanup
    exit 1
}

Write-Host ""
Write-Host "Projet AMI demarre avec succes!" -ForegroundColor Green
Write-Host ""
Write-Host "Interface utilisateur: http://localhost:8501" -ForegroundColor Cyan
Write-Host "API: http://$($env:SERVEUR_IP):$($env:SERVEUR_PORT)" -ForegroundColor Cyan
Write-Host "Documentation API: http://$($env:SERVEUR_IP):$($env:SERVEUR_PORT)/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour arreter tous les services" -ForegroundColor Yellow

# Attendre que l'utilisateur appuie sur une touche
try {
    Read-Host "Appuyez sur Entree pour arreter les services"
} catch {
    Write-Host "Arret demande par l'utilisateur" -ForegroundColor Yellow
} finally {
    Cleanup
} 