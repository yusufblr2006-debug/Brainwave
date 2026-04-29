"""
routes.py - All API route definitions for JudisAI.

Every endpoint:
  - Uses Pydantic models from schemas.py for both input and output.
  - Has a top-level try/except that returns a proper JSON ErrorResponse.
  - Never returns a loose dict.
"""

import re
import httpx
from fastapi import APIRouter, File, UploadFile
from fastapi.responses import JSONResponse

from schemas import (
    AdvocateMessage,          # noqa: F401  (available for WebSocket imports)
    AnalyzeCaseRequest,
    AnalyzeCaseResponse,
    ChatRequest,
    ChatResponse,
    ErrorResponse,
    FullSessionResponse,
    GenerateComplaintRequest,
    GenerateComplaintResponse,
    GenerateReportRequest,
    GenerateReportResponse,
    GeocodeRequest,
    GeocodeResponse,
    Lawyer,
    LawyerMatchRequest,
    LawyerMatchResponse,
    LawyerRegisterRequest,
    OcrResponse,
    RegisterResponse,
    SessionMetadata,
    TranslateRequest,
    TranslateResponse,
    UserHistoryResponse,
    UserRegisterRequest,
    VerifyUserRequest,
    VerifyUserResponse,
)

from database import (
    db,
    get_chat_history,
    get_user_sessions,
    legal_collection,
    save_analysis,
    save_chat_message,
    save_chat_pair,
    save_lawyer,
    save_lawyer_match,
    save_message,
    save_ocr_result,
    save_user,
    verify_lawyer,
)

from ai_engine import (
    get_ai_reply,
    analyze_case,
    analyze_image,
    translate_text,
    generate_complaint,
    generate_report,
)

# ── Compiled regexes for verify-user (module-level for performance) ──
_EMAIL_RE = re.compile(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$')
_PHONE_RE = re.compile(r'^[6-9]\d{9}$')

router = APIRouter()

# ── Hardcoded mock lawyer directory ──
# Five lawyers covering the five primary legal domains in JudisAI.

MOCK_LAWYERS: list[Lawyer] = [
    Lawyer(
        name="Adv. Priya Sharma",
        specialization="Family Law",
        city="Mumbai",
        rating=4.8,
        contact="priya.sharma@judisai.in",
    ),
    Lawyer(
        name="Adv. Rohan Mehta",
        specialization="Criminal Law",
        city="Delhi",
        rating=4.7,
        contact="rohan.mehta@judisai.in",
    ),
    Lawyer(
        name="Adv. Sunita Rao",
        specialization="Cyber Law",
        city="Bangalore",
        rating=4.9,
        contact="sunita.rao@judisai.in",
    ),
    Lawyer(
        name="Adv. Amir Khan",
        specialization="Property Law",
        city="Hyderabad",
        rating=4.6,
        contact="amir.khan@judisai.in",
    ),
    Lawyer(
        name="Adv. Deepa Nair",
        specialization="Labour Law",
        city="Chennai",
        rating=4.7,
        contact="deepa.nair@judisai.in",
    ),
]


# ── POST /api/chat ──

@router.post("/api/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Send a message to JudisAI and receive a RAG-grounded AI reply.

    - If Firestore is available: persists user message, loads history, persists reply.
    - If Firestore is unavailable (db=None): operates statelessly with empty history.
    """
    try:
        session_id = request.session_id
        message = request.message

        # Persist user message and load conversation history if Firestore is live
        if db is not None:
            save_message(session_id, "user", message)
            history = get_chat_history(session_id)
        else:
            history = []

        # Generate AI reply with RAG context and history
        reply = get_ai_reply(session_id, message, history)

        # Persist assistant reply if Firestore is live
        if db is not None:
            save_message(session_id, "assistant", reply)

        # Parallel write: one paired doc per exchange
        save_chat_pair(
            user_id=request.session_id,
            session_id=request.session_id,
            user_msg=request.message,
            assistant_msg=reply,
        )

        return ChatResponse(reply=reply, sources=[], status="success")



    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/generate-complaint ──

@router.post("/api/generate-complaint", response_model=GenerateComplaintResponse)
async def generate_complaint_endpoint(request: GenerateComplaintRequest):
    """Generate a formal complaint letter from extracted text and violations."""
    try:
        letter = await generate_complaint(
            extracted_text=request.extracted_text,
            violations=request.violations,
            user_name=request.user_name,
        )
        return GenerateComplaintResponse(complaint_letter=letter, status="success")
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/generate-report ──

@router.post("/api/generate-report", response_model=GenerateReportResponse)
async def generate_report_endpoint(request: GenerateReportRequest):
    """Generate a structured legal report from chat history."""
    try:
        report_data = generate_report(request.history)
        return GenerateReportResponse(
            summary=report_data.get("summary", ""),
            laws=report_data.get("laws", []),
            risks=report_data.get("risks", ""),
            actions=report_data.get("actions", []),
            status="success",
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/analyze-case ──

@router.post("/api/analyze-case", response_model=AnalyzeCaseResponse)
async def analyze_case_endpoint(request: AnalyzeCaseRequest):
    """
    Analyze all chat history for a session and return a structured legal case report.

    Requires Firestore to retrieve the conversation history.
    Returns 503 if the database is unavailable.
    """
    try:
        if db is None:
            return JSONResponse(
                status_code=503,
                content=ErrorResponse(detail="Database unavailable").model_dump(),
            )

        history = get_chat_history(request.session_id)
        result = analyze_case(history)

        # Parallel write to structured users/{user_id}/sessions/{session_id}/analysis/
        save_analysis(
            user_id=request.session_id,
            session_id=request.session_id,
            analysis=result.model_dump(),
        )

        return result


    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/match-lawyer ──

@router.post("/api/match-lawyer", response_model=LawyerMatchResponse)
async def match_lawyer_endpoint(request: LawyerMatchRequest):
    """
    Match a case category to the most suitable lawyers from the directory.

    - Performs a case-insensitive substring match on specialization.
    - Returns exactly 2 lawyers: matched ones first, gaps filled by highest rating.
    """
    try:
        category = request.case_category.lower().strip()

        # Primary match: specialization contains the search category
        matched: list[Lawyer] = [
            lawyer for lawyer in MOCK_LAWYERS
            if category in lawyer.specialization.lower()
        ]

        # Fill gaps up to 2 with the highest-rated unmatched lawyers
        if len(matched) < 2:
            unmatched = [lawyer for lawyer in MOCK_LAWYERS if lawyer not in matched]
            unmatched_sorted = sorted(unmatched, key=lambda l: l.rating, reverse=True)
            needed = 2 - len(matched)
            matched.extend(unmatched_sorted[:needed])

        # Parallel write → users/global/sessions/matches/lawyers_matched/
        save_lawyer_match(
            user_id="global",
            session_id="matches",
            lawyers=[l.model_dump() for l in matched[:2]],
            case_category=request.case_category,
        )

        return LawyerMatchResponse(lawyers=matched[:2], status="success")


    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── GET /api/match-lawyers ──

@router.get("/api/match-lawyers", response_model=LawyerMatchResponse)
async def get_match_lawyers_endpoint(category: str):
    """
    Match a case category to the most suitable lawyers from the directory.
    Returns top 3-5 lawyers.
    """
    try:
        search_category = category.lower().strip()

        # Primary match: specialization contains the search category
        matched: list[Lawyer] = [
            lawyer for lawyer in MOCK_LAWYERS
            if search_category in lawyer.specialization.lower()
        ]

        # Fill gaps up to 5 with the highest-rated unmatched lawyers
        if len(matched) < 5:
            unmatched = [lawyer for lawyer in MOCK_LAWYERS if lawyer not in matched]
            unmatched_sorted = sorted(unmatched, key=lambda l: l.rating, reverse=True)
            needed = 5 - len(matched)
            matched.extend(unmatched_sorted[:needed])

        # Return top 3-5 lawyers
        return LawyerMatchResponse(lawyers=matched[:5], status="success")

    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/ocr — Multimodal Evidence Analyzer ──

@router.post("/api/ocr", response_model=OcrResponse)
async def ocr_endpoint(file: UploadFile = File(...)):
    """
    Upload an image of a legal document for AI-powered analysis.
    Uses Groq vision model (llama-4-scout) to extract text and identify
    Indian legal violations. Accepts JPEG, PNG, WEBP.
    """
    try:
        contents = await file.read()
        ocr_result = await analyze_image(contents, file.filename or "upload.jpg")

        # Parallel write → users/global/sessions/ocr_results/ocr/
        save_ocr_result(
            user_id="global",
            session_id="ocr_results",
            filename=file.filename or "upload.jpg",
            result=ocr_result.model_dump(),
        )

        return ocr_result

    except Exception as e:
        return OcrResponse(
            extracted_text="",
            legal_violations=[],
            recommended_actions=[],
            status="error",
        )


# ── POST /api/translate ──

@router.post("/api/translate", response_model=TranslateResponse)
async def translate_endpoint(request: TranslateRequest):
    """
    Translates text to the target language using Groq LLM (llama-3.3-70b-versatile).
    Supports Hindi, Tamil, Telugu, Kannada, Malayalam, Bengali, and more.
    """
    try:
        result = await translate_text(request.text, request.target_language)
        return TranslateResponse(translated_text=result, status="success")
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/verify-user ──

@router.post("/api/verify-user", response_model=VerifyUserResponse)
async def verify_user_endpoint(request: VerifyUserRequest):
    """
    Validates Indian email and/or phone number without any external API.
    - Email: RFC-lite regex (user@domain.tld)
    - Phone: 10 digits, first digit 6–9 (Indian mobile format)
    """
    try:
        email = (request.email or "").strip()
        phone = (request.phone or "").strip()

        if not email and not phone:
            return VerifyUserResponse(
                is_valid=False,
                message="No contact info provided.",
                status="success",
            )

        errors: list[str] = []
        if email and not _EMAIL_RE.match(email):
            errors.append(f"Invalid email format: {email}")
        if phone and not _PHONE_RE.match(phone):
            errors.append(f"Invalid phone (10 digits, starts with 6–9): {phone}")

        if errors:
            return VerifyUserResponse(
                is_valid=False,
                message=" | ".join(errors),
                status="success",
            )

        return VerifyUserResponse(
            is_valid=True,
            message="Contact info is valid.",
            status="success",
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/geocode ──

@router.post("/api/geocode", response_model=GeocodeResponse)
async def geocode_endpoint(request: GeocodeRequest):
    """
    Resolves an Indian PIN code to District and State using the free India Post API.
    No API key required. Times out at 5 seconds.
    """
    try:
        async with httpx.AsyncClient() as http_client:
            resp = await http_client.get(
                f"https://api.postalpincode.in/pincode/{request.pin_code}",
                timeout=5.0,
            )
            data = resp.json()
        if data and data[0].get("Status") == "Success":
            po = data[0]["PostOffice"][0]
            return GeocodeResponse(
                city=po["District"],
                state=po["State"],
                status="success",
            )
        return GeocodeResponse(city="Unknown", state="Unknown", status="error")
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── GET /api/health ──

@router.get("/api/health")
async def health_endpoint():
    """
    Returns the live status of all backend services.
    Used by the Flutter app on startup and by monitoring dashboards.
    """
    return {
        "status": "ok",
        "firebase": db is not None,
        "chromadb": legal_collection is not None,
        "model": "llama-3.3-70b-versatile",
    }


# ── GET /api/conversation/{session_id} ──

@router.get("/api/conversation/{session_id}")
async def get_conversation_endpoint(session_id: str):
    """Return all messages for a session."""
    try:
        history = get_chat_history(session_id)
        return {"messages": history, "status": "success"}
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── GET /api/history/{user_id} ──

@router.get("/api/history/{user_id}", response_model=UserHistoryResponse)
async def get_user_history(user_id: str):
    """
    Return a list of all sessions (with metadata) for the given user_id,
    ordered by last_active descending.
    """
    try:
        raw_sessions = get_user_sessions(user_id)
        sessions = [SessionMetadata(**s) for s in raw_sessions]
        return UserHistoryResponse(sessions=sessions, status="success")
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── GET /api/history/{user_id}/{session_id} ──

@router.get("/api/history/{user_id}/{session_id}", response_model=FullSessionResponse)
async def get_session_detail(user_id: str, session_id: str):
    """
    Return the full detail for a single session: metadata, chat turns, analysis
    results, OCR results, and lawyer matches, all ordered by timestamp ascending.
    """
    try:
        if db is None:
            return JSONResponse(
                status_code=503,
                content=ErrorResponse(detail="Database unavailable").model_dump(),
            )

        session_ref = (
            db.collection("users")
            .document(user_id)
            .collection("sessions")
            .document(session_id)
        )

        def _stream(subcollection: str, order_field: str = "timestamp") -> list[dict]:
            docs = (
                session_ref.collection(subcollection)
                .order_by(order_field)
                .stream()
            )
            result = []
            for doc in docs:
                data = doc.to_dict() or {}
                ts = data.get("timestamp")
                if hasattr(ts, "isoformat"):
                    data["timestamp"] = ts.isoformat()
                result.append(data)
            return result

        metadata_snap = session_ref.get()
        metadata = metadata_snap.to_dict() or {} if metadata_snap.exists else {}
        last_active = metadata.get("last_active")
        if hasattr(last_active, "isoformat"):
            metadata["last_active"] = last_active.isoformat()

        return FullSessionResponse(
            metadata=metadata,
            chat=_stream("chat"),
            analysis=_stream("analysis"),
            ocr=_stream("ocr"),
            lawyers_matched=_stream("lawyers_matched"),
            status="success",
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/register/user ──

@router.post("/api/register/user", response_model=RegisterResponse)
async def register_user_endpoint(request: UserRegisterRequest):
    """Register a new user profile in Firestore."""
    try:
        save_user(
            user_id=request.user_id,
            email=request.email,
            phone=request.phone,
        )
        return RegisterResponse(message="User registered", status="success")
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/register/lawyer ──

@router.post("/api/register/lawyer", response_model=RegisterResponse)
async def register_lawyer_endpoint(request: LawyerRegisterRequest):
    """Register a new lawyer profile in Firestore (pending verification)."""
    try:
        save_lawyer(
            lawyer_id=request.lawyer_id,
            name=request.name,
            email=request.email,
            bar_number=request.bar_number,
            specialization=request.specialization,
            city=request.city,
            phone=request.phone,
        )
        return RegisterResponse(
            message="Lawyer registered, pending verification",
            status="success",
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )


# ── POST /api/verify-lawyer/{lawyer_id} ──

@router.post("/api/verify-lawyer/{lawyer_id}", response_model=RegisterResponse)
async def verify_lawyer_endpoint(lawyer_id: str):
    """Mark a registered lawyer as verified."""
    try:
        verify_lawyer(lawyer_id)
        return RegisterResponse(message="Lawyer verified", status="success")
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content=ErrorResponse(detail=str(e)).model_dump(),
        )
