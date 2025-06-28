"""Module de gestion des routes de streaming du chat."""

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from database import get_db
from services.chat_service import chat_service
from schemas.chat_schemas import ChatRequest

router = APIRouter()

@router.post("/stream")
def chat_stream(request: ChatRequest, db: Session = Depends(get_db)):
    """Endpoint pour le streaming de chat avec le modèle LLM."""
    message = {"role": "user", "content": request.message}
    
    def text_generator():
        for chunk in chat_service.stream_response(message, db):
            yield str(chunk)
    
    return StreamingResponse(
        text_generator(),
        media_type="text/plain; charset=utf-8"
    ) 