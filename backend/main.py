"""
VisionMate AI - FastAPI Backend Entry Point
==========================================
Main application file that registers all routers and configures middleware.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
import uvicorn

from routers import detect, scene, ocr, speech, navigation, sos
from routers import currency
from utils.logger import setup_logger

# Initialize logger
logger = setup_logger(__name__)

# Create FastAPI app
app = FastAPI(
    title="VisionMate AI API",
    description="AI-powered assistant for blind and visually impaired users",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Middleware ────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],          # Restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(GZipMiddleware, minimum_size=1000)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(detect.router,     prefix="/detect",       tags=["Detection"])
app.include_router(scene.router,      prefix="/scene-summary",tags=["Scene"])
app.include_router(ocr.router,        prefix="/ocr",          tags=["OCR"])
app.include_router(speech.router,     prefix="/speech-command",tags=["Speech"])
app.include_router(navigation.router, prefix="/navigation",   tags=["Navigation"])
app.include_router(sos.router,        prefix="/sos",          tags=["SOS"])
app.include_router(currency.router,   prefix="/currency",     tags=["Currency"])


@app.get("/", tags=["Health"])
async def root():
    """Health check endpoint."""
    return {"status": "ok", "service": "VisionMate AI", "version": "1.0.0"}


@app.get("/health", tags=["Health"])
async def health():
    """Detailed health check."""
    return {
        "status": "healthy",
        "models_loaded": True,
        "services": ["detection", "ocr", "speech", "navigation", "sos"],
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
    )
