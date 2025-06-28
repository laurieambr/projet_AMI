"""Module de gestion des routes d'historique du chat."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from services.chat_service import chat_service

router = APIRouter()

@router.get("/history")
def get_history(db: Session = Depends(get_db)):
    """Endpoint pour récupérer l'historique du jour."""
    return chat_service.get_today_history(db)

@router.delete("/history")
def delete_history(db: Session = Depends(get_db)):
    """Endpoint pour supprimer l'historique des messages du jour."""
    return chat_service.delete_history(db) 