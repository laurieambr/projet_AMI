"""
Module principal de l'API du PROJET AMI, gérant l'initialisation et la configuration de l'application FastAPI.
"""

import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from llama_cpp import Llama

from database import SessionLocal, engine
import models
from routes.stream import router as stream_router
from routes.history import router as history_router
from routes.main import router as main_router
from services.chat_service import chat_service

# Création des tables
models.Base.metadata.create_all(bind=engine)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestion du cycle de vie de l'application."""
    print("Chargement de l'historique...")
    with SessionLocal() as db:
        chat_service.init_system_message(db)
    print(chat_service.history)
    yield

app = FastAPI(
    title="AMI API",
    description="API de chat avec un modèle LLM",
    version="1.0.0",
    lifespan=lifespan
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Vérification des chemins des modèles
MODEL_3B_PATH = "./DeepSeek-R1-Distill-Llama-3B-Q4_K_M.gguf"

print("Vérification des fichiers de modèles...")
model_exists = os.path.exists(MODEL_3B_PATH)

if not model_exists:
    print(f"Modèle non trouvé: {MODEL_3B_PATH}")
    raise FileNotFoundError(f"Modèle non trouvé: {MODEL_3B_PATH}")

try:
    print("Chargement du modèle...")
    llm_3b = Llama(
        model_path=MODEL_3B_PATH,
        n_gpu_layers=-1,
        n_batch=512,
        n_ctx=2048,
        verbose=False
    )
    print("Modèle chargé avec succès.")
    chat_service.set_llm_model(llm_3b)
except Exception as e:
    print(f"Erreur lors du chargement du modèle 3B: {str(e)}")
    raise

# Inclusion des routes
app.include_router(main_router, tags=["main"])
app.include_router(stream_router, prefix="/chat", tags=["stream"])
app.include_router(history_router, prefix="/chat", tags=["history"])
