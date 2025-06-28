"""Module de configuration de la base de données."""

import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

# Récupérer les variables d'environnement avec des valeurs par défaut
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_NAME = os.getenv("DB_NAME")

DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"

engine = create_engine(
    DATABASE_URL,
    pool_size=10,      # nombre de connexions simultanées max
    max_overflow=20,   # connexions "temporaires" supplémentaires
    echo=False         # True pour voir le SQL généré pour debug
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Fournit une session SQLAlchemy, puis la ferme après usage."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close() 