# projet_AMI

Projet AMI avec architecture client-serveur séparée.

## Structure du projet

```
projet_AMI/
├── client/                 # Interface utilisateur Streamlit
│   ├── app.py             # Application Streamlit
│   ├── requirements.txt   # Dépendances client
│   └── README.md          # Documentation client
├── database/              # Configuration base de données
│   ├── __init__.py        # Exports du module database
│   └── database.py        # Configuration SQLAlchemy
├── routes/                # Routes de l'API
│   ├── __init__.py        # Exports des routeurs
│   ├── stream.py          # Routes de streaming
│   ├── history.py         # Routes d'historique
│   └── main.py            # Routes principales
├── services/              # Services métier
├── models/                # Modèles de données
├── schemas/               # Schémas de validation
├── main.py               # Serveur API FastAPI
├── requirements.txt      # Dépendances serveur
├── start_ami.sh          # Script de lancement (Linux/Mac)
├── start_ami.ps1         # Script de lancement (Windows)
└── README.md            # Documentation principale
```

## Installation

### 1. Création et activation de l'environnement virtuel

```bash
# Créer l'environnement virtuel
python -m venv llm_env

# Activer l'environnement virtuel
# Sur Windows (PowerShell)
llm_env\Scripts\activate

# Sur Linux/Mac
source llm_env/bin/activate
```

### 2. Installation de llama-cpp-python avec support NVIDIA

```bash
# Désinstaller la version existante si présente
pip uninstall llama-cpp-python

# Configurer la variable d'environnement pour CUDA
# Sur Windows (PowerShell)
$env:CMAKE_ARGS="-DGGML_CUDA=on"

# Sur Linux/Mac
export CMAKE_ARGS="-DGGML_CUDA=on"

# Installer llama-cpp-python avec support serveur et CUDA
pip install llama-cpp-python[server] --extra-index-url https://pypi.nvidia.com --force-reinstall --no-cache-dir
```

### 3. Installation des dépendances

```bash
# Dépendances serveur
pip install -r requirements.txt

# Dépendances client
pip install -r client/requirements.txt
```

## Lancement

### Option 1: Lancement automatique (Recommandé)

Des scripts de lancement automatique sont disponibles pour simplifier le démarrage du projet :

#### Sur Windows :
```powershell
# Activer l'environnement virtuel
llm_env\Scripts\activate

# Lancer le projet
.\start_ami.ps1
```

#### Sur Linux/Mac :
```bash
# Rendre le script exécutable (une seule fois)
chmod +x start_ami.sh

# Activer l'environnement virtuel
source llm_env/bin/activate

# Lancer le projet
./start_ami.sh
```

**Fonctionnalités des scripts :**
- Vérification automatique de l'environnement virtuel
- Vérification des dépendances (uvicorn, streamlit)
- Vérification de la présence du modèle
- Configuration des variables d'environnement
- Lancement du serveur API (port 8000)
- Lancement de l'interface Streamlit (port 8501)
- Vérification du bon fonctionnement
- Arrêt propre avec Ctrl+C

### Option 2: Lancement manuel

#### Serveur API

```bash
# Lancer le serveur API
uvicorn main:app --host 0.0.0.0 --port 8000
```

#### Client Streamlit

```bash
# Lancer l'interface utilisateur
cd client
streamlit run app.py
```

## Configuration

Définissez les variables d'environnement pour le client :
- `SERVEUR_IP` : Adresse IP du serveur API
- `SERVEUR_PORT` : Port du serveur API

## URLs d'accès

Une fois lancé, vous pouvez accéder à :

- **Interface utilisateur** : http://localhost:8501
- **API** : http://localhost:8000
- **Documentation API** : http://localhost:8000/docs

## Modèle utilisé

**URL du modèle distillé 3B GGUF :**
https://huggingface.co/hassenhamdi/DeepSeek-R1-Distill-Llama-3B-GGUF

**Version :** Q4 K M (4 bit)

## Dépannage

### Erreur "Environnement virtuel non activé"
```bash
# Activer l'environnement virtuel
source llm_env/bin/activate  # Linux/Mac
# ou
llm_env\Scripts\activate     # Windows
```

### Erreur "Modèle non trouvé"
Téléchargez le modèle depuis :
https://huggingface.co/hassenhamdi/DeepSeek-R1-Distill-Llama-3B-GGUF

### Erreur de port déjà utilisé
Les scripts utilisent les ports par défaut :
- API : 8000
- Streamlit : 8501

Si ces ports sont occupés, modifiez les scripts ou arrêtez les services qui les utilisent.

## Documentation client

Pour plus d'informations sur l'interface utilisateur, consultez [client/README.md](client/README.md).