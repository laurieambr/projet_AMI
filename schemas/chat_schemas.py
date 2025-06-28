"""Schémas Pydantic pour les routes de chat."""

from typing import List
from pydantic import BaseModel

class ChatRequest(BaseModel):
    """Schéma pour les requêtes de chat."""
    message: str
    
class ContextResponse(BaseModel):
    """Schéma pour les réponses de contexte."""
    date: str
    messages: List[dict] 