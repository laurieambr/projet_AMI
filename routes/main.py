"""Routes principales de l'API Learnie."""

from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def root():
    """Renvoie un message de bienvenue pour la racine de l'API."""
    return {"message": "Bienvenue sur l'API Learnie"} 