import os
from typing import Generator
import streamlit as st
import requests

# Configuration des variables d'environnement avec valeurs par défaut
SERVEUR_IP = os.getenv("SERVEUR_IP", "localhost")
SERVEUR_PORT = os.getenv("SERVEUR_PORT", "8000")

# Configuration de la page
st.set_page_config(
    page_title="AMI Chat",
    page_icon="",
    layout="centered"
)

# Construction des URLs avec vérification
API_URL = f"http://{SERVEUR_IP}:{SERVEUR_PORT}/chat/stream"
API_HISTORY_URL = f"http://{SERVEUR_IP}:{SERVEUR_PORT}/chat/history"

def stream_response(message: str) -> Generator[str, None, None]:
    """Envoie une requête à l'API et récupère la réponse en streaming."""
    try:
        with requests.post(
            API_URL,
            json={"message": message},
            stream=True,
            headers={"Content-Type": "application/json"},
            timeout=(5, 60)
        ) as response:
            response.raise_for_status()
            
            buffer = ""
            for chunk in response.iter_content(chunk_size=1, decode_unicode=True):
                if chunk:
                    buffer += chunk
                    if chunk in [' ', '\n', '.', ',', '!', '?']:
                        if buffer:
                            yield buffer
                        buffer = ""
            if buffer:
                yield buffer
    except requests.exceptions.RequestException as e:
        st.error(f"Erreur de connexion à l'API : {str(e)}")
        return

def fetch_history():
    """Récupère l'historique des messages depuis l'API."""
    try:
        response = requests.get(API_HISTORY_URL, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        st.warning(f"Impossible de récupérer l'historique : {e}")
        return []

def reset_history():
    """Réinitialise l'historique des conversations."""
    try:
        response = requests.delete(API_HISTORY_URL, timeout=10)
        response.raise_for_status()
        st.session_state.messages = []
    except Exception as e:
        st.error(f"Erreur lors de la suppression de l'historique : {e}")

def main():
    """Fonction principale qui gère l'interface utilisateur et les interactions du chat."""
    st.title("AMI Chat")
    
    # Affichage de la configuration
    st.sidebar.info(f"Serveur: {SERVEUR_IP}:{SERVEUR_PORT}")

    # Ajout du bouton de réinitialisation
    if st.button("Effacer l'historique"):
        reset_history()
        st.rerun()

    if "messages" not in st.session_state or not st.session_state.messages:
        st.session_state.messages = fetch_history()

    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.markdown(msg["content"], unsafe_allow_html=True)

    prompt = st.chat_input("Écrivez votre message ici...")

    if prompt:
        st.session_state.messages.append({"role": "user", "content": prompt})

        with st.chat_message("user"):
            st.write(prompt)

        assistant_msg = st.chat_message("assistant")
        message_placeholder = assistant_msg.empty()
        full_response = ""

        for chunk in stream_response(prompt):
            full_response += chunk
            message_placeholder.markdown(full_response, unsafe_allow_html=True)

        st.session_state.messages.append({"role": "assistant", "content": full_response})
        st.rerun()

if __name__ == "__main__":
    main() 