"""
schemas.py — Pydantic v2 request/response models for JudisAI.

This file is the SINGLE SOURCE OF TRUTH for all API contracts.
The Flutter developer should mirror these models exactly in Dart.
All response models use ConfigDict(from_attributes=True) for ORM compatibility.
NEVER return loose dicts from any endpoint — always use these models.
"""

from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


# ──────────────────────────────────────────────
# REQUEST MODELS
# ──────────────────────────────────────────────

class ChatRequest(BaseModel):
    """Request body for the /api/chat endpoint."""
    session_id: str = Field(..., description="Unique session identifier for the conversation")
    message: str = Field(..., description="The user's message text")


class AnalyzeCaseRequest(BaseModel):
    """Request body for the /api/analyze-case endpoint."""
    session_id: str = Field(..., description="Session ID whose chat history will be analyzed")


class LawyerMatchRequest(BaseModel):
    """Request body for the /api/match-lawyer endpoint."""
    case_category: str = Field(
        ...,
        description="Legal category to match lawyers against (e.g. 'Family Law', 'Criminal Law')",
    )


class TranslateRequest(BaseModel):
    """Request body for the /api/translate endpoint."""
    text: str = Field(..., description="Source text to translate")
    target_language: str = Field(
        ...,
        description="Target language code or name (e.g. 'Hindi', 'Tamil')",
    )


class VerifyUserRequest(BaseModel):
    """Request body for the /api/verify-user endpoint."""
    email: Optional[str] = Field(default=None, description="User email address to verify")
    phone: Optional[str] = Field(default=None, description="User phone number to verify")


class GeocodeRequest(BaseModel):
    """Request body for the /api/geocode endpoint."""
    pin_code: str = Field(..., description="Indian PIN code to geocode")


class AdvocateMessage(BaseModel):
    """
    WebSocket payload for the /ws/advocate/{user_id} endpoint.
    The Flutter app sends this JSON to the WebSocket on each turn.
    speaker should always be 'police' for officer utterances or 'citizen'
    for citizen-side messages; the AI always speaks as the citizen's advocate.
    """
    speaker: str = Field(
        ...,
        description="Who is speaking: 'police' for an officer utterance, 'citizen' for the user",
    )
    text: str = Field(..., description="The spoken text transcribed from audio or typed input")
    is_continuation: bool = Field(
        default=False,
        description="True if this is an ongoing conversation, False if it is a new one",
    )
    history: list[dict] = Field(
        default_factory=list,
        description="Array of past messages like [{'role':'user', 'text':'...'}, {'role':'ai', 'text':'...'}]",
    )


class GenerateComplaintRequest(BaseModel):
    """Request body for the /generate-complaint endpoint."""
    extracted_text: str = Field(..., description="Text extracted from evidence")
    violations: list[str] = Field(default_factory=list, description="Identified violations")
    user_name: str = Field(..., description="Name of the user filing the complaint")


class GenerateReportRequest(BaseModel):
    """Request body for the /generate-report endpoint."""
    history: list[dict] = Field(..., description="Chat history")


# ──────────────────────────────────────────────
# RESPONSE MODELS
# ──────────────────────────────────────────────

class ChatResponse(BaseModel):
    """Response body for the /api/chat endpoint."""
    model_config = ConfigDict(from_attributes=True)

    reply: str = Field(..., description="AI-generated reply text")
    sources: list[str] = Field(
        default_factory=list,
        description="List of source references used (RAG citations)",
    )
    status: str = Field(default="success", description="Response status indicator")


class AnalyzeCaseResponse(BaseModel):
    """Response body for the /api/analyze-case endpoint."""
    model_config = ConfigDict(from_attributes=True)

    case_summary: str = Field(default="", description="Brief summary of the legal case")
    applicable_indian_laws: list[str] = Field(
        default_factory=list,
        description="List of applicable Indian laws and sections",
    )
    missing_evidence: list[str] = Field(
        default_factory=list,
        description="Evidence or information still needed to strengthen the case",
    )
    risk_score: int = Field(
        default=0,
        ge=0,
        le=100,
        description="Risk assessment score from 0 (low risk) to 100 (high risk)",
    )
    case_category: str = Field(default="", description="Classified category of the legal case")
    status: str = Field(default="success", description="Response status indicator")


class GenerateComplaintResponse(BaseModel):
    """Response body for the /generate-complaint endpoint."""
    model_config = ConfigDict(from_attributes=True)

    complaint_letter: str = Field(..., description="Formatted complaint letter")
    status: str = Field(default="success", description="Response status indicator")


class GenerateReportResponse(BaseModel):
    """Response body for the /generate-report endpoint."""
    model_config = ConfigDict(from_attributes=True)

    summary: str = Field(..., description="Summary of the legal situation")
    laws: list[str] = Field(default_factory=list, description="Applicable laws")
    risks: str = Field(..., description="Identified risks")
    actions: list[str] = Field(default_factory=list, description="Recommended actions")
    status: str = Field(default="success", description="Response status indicator")


class Lawyer(BaseModel):
    """A single lawyer entry in the match-lawyer response."""
    model_config = ConfigDict(from_attributes=True)

    name: str = Field(..., description="Full name of the lawyer")
    specialization: str = Field(..., description="Area of legal specialization")
    city: str = Field(..., description="City where the lawyer practices")
    rating: float = Field(..., ge=0.0, le=5.0, description="Average client rating (0.0–5.0)")
    contact: str = Field(..., description="Contact email address")
    experience: str = Field(default="5+ Years", description="Lawyer's experience")
    price: str = Field(default="₹2000/hr", description="Lawyer's consultation fee")


class LawyerMatchResponse(BaseModel):
    """Response body for the /api/match-lawyer endpoint."""
    model_config = ConfigDict(from_attributes=True)

    lawyers: list[Lawyer] = Field(
        default_factory=list,
        description="Matched lawyers sorted by relevance then by rating",
    )
    status: str = Field(default="success", description="Response status indicator")


class TranslateResponse(BaseModel):
    """Response body for the /api/translate endpoint."""
    model_config = ConfigDict(from_attributes=True)

    translated_text: str = Field(..., description="Translated text output")
    status: str = Field(default="success", description="Response status indicator")


class OcrResponse(BaseModel):
    """
    Response body for the /api/ocr endpoint (Multimodal Evidence Analyzer).
    Returns extracted text plus AI-identified legal violations and recommended actions.
    """
    model_config = ConfigDict(from_attributes=True)

    extracted_text: str = Field(
        default="",
        description="All text extracted from the uploaded image or document",
    )
    legal_violations: list[str] = Field(
        default_factory=list,
        description=(
            "Indian legal violations identified in the document, "
            "each citing the specific Act and section (e.g. 'Section 138 NI Act — Dishonour of cheque')"
        ),
    )
    recommended_actions: list[str] = Field(
        default_factory=list,
        description="Step-by-step recommended legal actions the user should take",
    )
    status: str = Field(default="success", description="Response status indicator")


class VerifyUserResponse(BaseModel):
    """Response body for the /api/verify-user endpoint."""
    model_config = ConfigDict(from_attributes=True)

    is_valid: bool = Field(..., description="Whether the user credentials are valid")
    message: str = Field(..., description="Human-readable verification result message")
    status: str = Field(default="success", description="Response status indicator")


class GeocodeResponse(BaseModel):
    """Response body for the /api/geocode endpoint."""
    model_config = ConfigDict(from_attributes=True)

    city: str = Field(..., description="City name resolved from PIN code")
    state: str = Field(..., description="State name resolved from PIN code")
    status: str = Field(default="success", description="Response status indicator")


class ErrorResponse(BaseModel):
    """Standard error response returned on any unhandled exception."""
    model_config = ConfigDict(from_attributes=True)

    detail: str = Field(..., description="Human-readable error description")
    status: str = Field(default="error", description="Always 'error' for error responses")


# ──────────────────────────────────────────────
# SESSION / HISTORY MODELS (new)
# ──────────────────────────────────────────────

class SessionMetadata(BaseModel):
    """Lightweight metadata for a single session (used in history listings)."""
    model_config = ConfigDict(from_attributes=True)

    session_id: str
    last_active: Optional[str] = None
    case_category: Optional[str] = None
    status: Optional[str] = None


class UserHistoryResponse(BaseModel):
    """Response body for GET /api/history/{user_id}."""
    model_config = ConfigDict(from_attributes=True)

    sessions: list[SessionMetadata]
    status: str


class FullSessionResponse(BaseModel):
    """Response body for GET /api/history/{user_id}/{session_id}."""
    model_config = ConfigDict(from_attributes=True)

    metadata: dict
    chat: list[dict]
    analysis: list[dict]
    ocr: list[dict]
    lawyers_matched: list[dict]
    status: str


# ──────────────────────────────────────────────
# REGISTRATION MODELS (new)
# ──────────────────────────────────────────────

class UserRegisterRequest(BaseModel):
    """Request body for POST /api/register/user."""
    user_id: str
    email: str
    phone: Optional[str] = None


class LawyerRegisterRequest(BaseModel):
    """Request body for POST /api/register/lawyer."""
    lawyer_id: str
    name: str
    email: str
    bar_number: str
    specialization: str
    city: str
    phone: Optional[str] = None


class RegisterResponse(BaseModel):
    """Response body for all registration endpoints."""
    model_config = ConfigDict(from_attributes=True)

    message: str
    status: str
