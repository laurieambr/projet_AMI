#!/bin/bash

# Script de lancement pour le projet AMI
# Lance le serveur API et l'interface Streamlit

echo "Demarrage du projet AMI..."

# Verification de l'environnement virtuel
if [[ "$VIRTUAL_ENV" == "" ]]; then
    echo "Environnement virtuel non active!"
    echo "Veuillez activer l'environnement virtuel avec:"
    echo "source llm_env/bin/activate"
    exit 1
fi

echo "Environnement virtuel active: $VIRTUAL_ENV"

# Verification des dependances
echo "Verification des dependances..."

# Verifier si uvicorn est installe
if ! command -v uvicorn &> /dev/null; then
    echo "uvicorn non trouve. Installation..."
    pip install uvicorn
fi

# Verifier si streamlit est installe
if ! command -v streamlit &> /dev/null; then
    echo "streamlit non trouve. Installation..."
    pip install streamlit
fi

echo "Dependances verifiees"

# Verification du modele
MODEL_PATH="./DeepSeek-R1-Distill-Llama-3B-Q4_K_M.gguf"
if [[ ! -f "$MODEL_PATH" ]]; then
    echo "Modele non trouve: $MODEL_PATH"
    echo "Veuillez telecharger le modele depuis:"
    echo "https://huggingface.co/hassenhamdi/DeepSeek-R1-Distill-Llama-3B-GGUF"
    exit 1
fi

echo "Modele trouve: $MODEL_PATH"

# Configuration des variables d'environnement
export SERVEUR_IP="localhost"
export SERVEUR_PORT="8000"

echo "Configuration:"
echo "   - Serveur IP: $SERVEUR_IP"
echo "   - Serveur Port: $SERVEUR_PORT"

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "Arret des services..."
    kill $API_PID $STREAMLIT_PID 2>/dev/null
    echo "Services arretes"
    exit 0
}

# Capture du signal d'interruption
trap cleanup SIGINT SIGTERM

# Lancement du serveur API en arriere-plan
echo "Lancement du serveur API..."
uvicorn main:app --host $SERVEUR_IP --port $SERVEUR_PORT &
API_PID=$!

# Attendre que le serveur API demarre
echo "Attente du demarrage du serveur API..."
sleep 5

# Verification que le serveur API fonctionne
if ! curl -s http://$SERVEUR_IP:$SERVEUR_PORT/ > /dev/null; then
    echo "Le serveur API n'a pas demarre correctement"
    kill $API_PID 2>/dev/null
    exit 1
fi

echo "Serveur API demarre (PID: $API_PID)"

# Lancement de Streamlit en arriere-plan avec les variables d'environnement
echo "Lancement de l'interface Streamlit..."
cd client
SERVEUR_IP=$SERVEUR_IP SERVEUR_PORT=$SERVEUR_PORT streamlit run app.py --server.port 8501 --server.address localhost &
STREAMLIT_PID=$!
cd ..

echo "Interface Streamlit demarree (PID: $STREAMLIT_PID)"

echo ""
echo "Projet AMI demarre avec succes!"
echo ""
echo "Interface utilisateur: http://localhost:8501"
echo "API: http://$SERVEUR_IP:$SERVEUR_PORT"
echo "Documentation API: http://$SERVEUR_IP:$SERVEUR_PORT/docs"
echo ""
echo "Appuyez sur Ctrl+C pour arreter tous les services"

# Attendre que les processus se terminent
wait 