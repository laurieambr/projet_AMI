"""Service de gestion des conversations avec le modèle LLM."""

from datetime import datetime, date
from typing import List, Generator
from sqlalchemy.orm import Session

import models

class ChatService:
    """Service pour gérer les conversations avec le modèle LLM."""
    
    def __init__(self):
        self.llm = None
        self.history = [
            {"role": "system", "content": "Tu es un assistant ami qui répond à des questions de manière amicale et naturelle, tu m'aides dans mes réflexions et m'accompagne dans mes décisions de tous les jours."}
        ]
        self.DEFAULT_USER_ID = 1
    
    def set_llm_model(self, model):
        """Définit le modèle LLM à utiliser."""
        self.llm = model
    
    def get_or_create_default_user(self, db: Session) -> models.User:
        """Récupère ou crée l'utilisateur par défaut."""
        user = db.query(models.User).filter(models.User.id == self.DEFAULT_USER_ID).first()
        if not user:
            user = models.User(
                id=self.DEFAULT_USER_ID,
                username="default_user",
                email="default@example.com",
                hashed_password="dummy_password",  # À changer en production
                created_at=datetime.now(),
                is_active=True
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        return user
    
    def init_system_message(self, db: Session):
        """Initialise le message système pour la journée courante s'il n'existe pas déjà."""
        today_str = date.today()
        system_message = db.query(models.Message).filter(
            models.Message.date == today_str,
            models.Message.role == "system"
        ).first()
        if not system_message:
            user = self.get_or_create_default_user(db)
            msg = models.Message(
                user_id=user.id,
                date=today_str,
                timestamp=datetime.now(),
                role="system",
                content=self.history[0]["content"]
            )
            db.add(msg)
            db.commit()
    
    def get_today_history(self, db: Session) -> List[dict]:
        """Récupère l'historique des messages du jour (hors message système)."""
        today_str = date.today()
        user = self.get_or_create_default_user(db)
        messages = db.query(models.Message).filter(
            models.Message.date == today_str,
            models.Message.user_id == user.id,
            models.Message.role != "system"
        ).order_by(models.Message.timestamp.asc()).all()
        return [
            {"role": msg.role, "content": msg.content, "timestamp": msg.timestamp.isoformat()} 
            for msg in messages
        ]
    
    def stream_response(self, message: dict, db: Session) -> Generator[str, None, None]:
        """Génère un flux de réponses du modèle LLM."""
        if self.llm is None:
            raise RuntimeError("Le modèle LLM n'a pas été initialisé")
        
        self.history.append(message)
        user = self.get_or_create_default_user(db)
        
        # Sauvegarde du message utilisateur
        db_msg_user = models.Message(
            user_id=user.id,
            date=date.today(),
            timestamp=datetime.now(),
            role=message["role"],
            content=message["content"]
        )
        db.add(db_msg_user)
        db.commit()
        db.refresh(db_msg_user)
        
        # Génération de la réponse
        full_response = ""
        for chunk in self.llm.create_chat_completion(messages=self.history, stream=True):
            content = chunk["choices"][0]["delta"].get("content", "")
            if content:
                print(f"content: {content}")
                full_response += content
                yield content
        
        # Sauvegarde de la réponse de l'assistant
        self.history.append({"role": "assistant", "content": full_response})
        db_msg_assistant = models.Message(
            user_id=user.id,
            date=date.today(),
            timestamp=datetime.now(),
            role="assistant",
            content=full_response
        )
        db.add(db_msg_assistant)
        db.commit()
        db.refresh(db_msg_assistant)
    
    def delete_history(self, db: Session) -> dict:
        """Supprime l'historique des messages du jour."""
        today_str = date.today()
        user = self.get_or_create_default_user(db)
        
        # Suppression dans la base de données
        db.query(models.Message).filter(
            models.Message.date == today_str,
            models.Message.user_id == user.id,
            models.Message.role != "system"
        ).delete()
        db.commit()
        
        # Réinitialisation de l'historique
        self.history = [self.history[0]]  # Garde uniquement le message système
        
        return {"message": "Historique supprimé avec succès"}

# Instance globale du service
chat_service = ChatService() 