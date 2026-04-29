"""
main.py - FastAPI application entry point for JudisAI.

Startup sequence:
  1. Importing `database` triggers Firebase Admin SDK init + ChromaDB seeding.
  2. CORSMiddleware is configured for cross-origin Flutter app access.
     IMPORTANT: allow_credentials MUST be False when allow_origins=["*"].
  3. All HTTP API routes are included from routes.py.
  4. The Digital Advocate WebSocket is registered at /ws/advocate/{user_id}.
  5. A health-check GET / endpoint confirms the server is running.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Importing database triggers Firebase Admin SDK initialization
# and ChromaDB seeding (legal_cases.json → "indian_legal_cases" collection)
# at module level — before any request is served.
import database  # noqa: F401

from routes import router
from websockets.advocate_handler import advocate_socket_handler

# ── FastAPI application instance ──

app = FastAPI(
    title="JudisAI",
    description=(
        "AI-powered Indian legal assistant backend. "
        "Provides chat, case analysis, lawyer matching, OCR, "
        "and a real-time Digital Advocate WebSocket."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS Middleware ──
# allow_credentials MUST be False when allow_origins=["*"].
# Setting both to True simultaneously is rejected by browsers (CORS spec violation).

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── HTTP API Routes ──

app.include_router(router)

# ── WebSocket: Digital Advocate ──
# Registered via add_api_websocket_route so path parameters ({user_id}) are
# correctly forwarded to the handler function signature.

app.add_api_websocket_route(
    "/ws/advocate/{user_id}",
    advocate_socket_handler,
)

# ── Health Check ──

@app.get("/", tags=["Health"])
async def root():
    """Basic health-check endpoint. Returns immediately with no dependencies."""
    return {"status": "JudisAI backend is running"}
