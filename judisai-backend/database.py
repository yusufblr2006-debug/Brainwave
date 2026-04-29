"""
database.py - Firebase Admin SDK and ChromaDB initialization for JudisAI.
"""

import json
import os
from datetime import datetime, timezone

import chromadb
import firebase_admin
from fastapi import HTTPException
from firebase_admin import credentials, firestore

# ── FIREBASE ADMIN SDK INIT ──

db = None

try:
    if not firebase_admin._apps:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase Admin SDK initialized successfully.")
except FileNotFoundError:
    print("WARNING: serviceAccountKey.json not found. Firestore is DISABLED.")
    db = None
except json.JSONDecodeError:
    print("WARNING: serviceAccountKey.json contains invalid JSON. Firestore is DISABLED.")
    db = None
except Exception as exc:
    print(f"WARNING: Firebase initialization failed ({exc}). Firestore is DISABLED.")
    db = None

# ── FIRESTORE HELPERS ──

def save_message(session_id: str, role: str, content: str) -> None:
    if db is None:
        return
    try:
        doc_ref = db.collection("sessions").document(session_id).collection("messages")
        doc_ref.add({"role": role, "content": content, "timestamp": datetime.now(timezone.utc)})
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Firestore save_message failed: {exc}")


def get_chat_history(session_id: str) -> list[dict]:
    if db is None:
        return []
    try:
        messages_ref = db.collection("sessions").document(session_id).collection("messages").order_by("timestamp")
        docs = messages_ref.stream()
        history = []
        for doc in docs:
            data = doc.to_dict()
            history.append({"role": data.get("role", "user"), "content": data.get("content", "")})
        return history
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Firestore get_chat_history failed: {exc}")

# ── CHROMADB INIT + SEEDING ──

chroma_client = chromadb.PersistentClient(path="./chroma_store")
legal_collection = chroma_client.get_or_create_collection(name="indian_legal_cases")


def seed_legal_cases() -> None:
    if legal_collection.count() > 0:
        print(f"ChromaDB already seeded ({legal_collection.count()} docs). Skipping.")
        return
    json_path = os.path.join(os.path.dirname(__file__), "legal_cases.json")
    try:
        with open(json_path, "r", encoding="utf-8") as f:
            cases = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as exc:
        print(f"WARNING: Could not load legal_cases.json ({exc}). Collection empty.")
        return
    ids = [c["id"] for c in cases]
    documents = [c["summary"] for c in cases]
    metadatas = [{"title": c["title"], "keywords": ", ".join(c["keywords"])} for c in cases]
    legal_collection.add(ids=ids, documents=documents, metadatas=metadatas)
    print(f"Seeded ChromaDB with {len(ids)} Indian legal cases.")


seed_legal_cases()


# ── NEW STRUCTURED-HISTORY HELPERS ──

def save_analysis(user_id: str, session_id: str, analysis: dict) -> None:
    """Persist an analysis result to users/{user_id}/sessions/{session_id}/analysis/."""
    if db is None:
        return
    try:
        ref = (
            db.collection("users")
            .document(user_id)
            .collection("sessions")
            .document(session_id)
            .collection("analysis")
        )
        payload = {**analysis, "timestamp": firestore.SERVER_TIMESTAMP}
        ref.add(payload)
    except Exception as exc:
        print(f"WARNING: save_analysis failed ({exc})")


def save_ocr_result(
    user_id: str, session_id: str, filename: str, result: dict
) -> None:
    """Persist an OCR result to users/{user_id}/sessions/{session_id}/ocr/."""
    if db is None:
        return
    try:
        ref = (
            db.collection("users")
            .document(user_id)
            .collection("sessions")
            .document(session_id)
            .collection("ocr")
        )
        payload = {
            "extracted_text": result.get("extracted_text", ""),
            "legal_violations": result.get("legal_violations", []),
            "recommended_actions": result.get("recommended_actions", []),
            "filename": filename,
            "timestamp": firestore.SERVER_TIMESTAMP,
        }
        ref.add(payload)
    except Exception as exc:
        print(f"WARNING: save_ocr_result failed ({exc})")


def save_lawyer_match(
    user_id: str, session_id: str, lawyers: list, case_category: str
) -> None:
    """Persist a lawyer-match result to users/{user_id}/sessions/{session_id}/lawyers_matched/."""
    if db is None:
        return
    try:
        ref = (
            db.collection("users")
            .document(user_id)
            .collection("sessions")
            .document(session_id)
            .collection("lawyers_matched")
        )
        payload = {
            "lawyers": lawyers,
            "case_category": case_category,
            "timestamp": firestore.SERVER_TIMESTAMP,
        }
        ref.add(payload)
    except Exception as exc:
        print(f"WARNING: save_lawyer_match failed ({exc})")


def save_chat_message(
    user_id: str, session_id: str, role: str, content: str
) -> None:
    """Persist a chat turn to users/{user_id}/sessions/{session_id}/chat/ and
    upsert the session metadata doc with last_active + status."""
    if db is None:
        return
    try:
        session_doc_ref = (
            db.collection("users")
            .document(user_id)
            .collection("sessions")
            .document(session_id)
        )
        # Upsert session metadata — never overwrites existing fields
        session_doc_ref.set(
            {"last_active": firestore.SERVER_TIMESTAMP, "status": "active"},
            merge=True,
        )
        # Append the chat message
        session_doc_ref.collection("chat").add(
            {"role": role, "content": content, "timestamp": firestore.SERVER_TIMESTAMP}
        )
    except Exception as exc:
        print(f"WARNING: save_chat_message failed ({exc})")


def get_user_sessions(user_id: str) -> list:
    """Return all session metadata docs for a user, ordered by last_active descending."""
    if db is None:
        return []
    try:
        sessions_ref = (
            db.collection("users")
            .document(user_id)
            .collection("sessions")
            .order_by("last_active", direction=firestore.Query.DESCENDING)
        )
        docs = sessions_ref.stream()
        results = []
        for doc in docs:
            data = doc.to_dict() or {}
            # Convert any Firestore DatetimeWithNanoseconds to ISO string
            last_active = data.get("last_active")
            if hasattr(last_active, "isoformat"):
                last_active = last_active.isoformat()
            results.append(
                {
                    "session_id": doc.id,
                    "last_active": last_active,
                    "case_category": data.get("case_category"),
                    "status": data.get("status"),
                }
            )
        return results
    except Exception as exc:
        print(f"WARNING: get_user_sessions failed ({exc})")
        return []


# ── CHAT PAIR HELPER ──

def save_chat_pair(
    user_id: str, session_id: str, user_msg: str, assistant_msg: str
) -> None:
    """Save a user+assistant exchange as ONE document in chat/."""
    if db is None:
        return
    try:
        session_doc_ref = (
            db.collection("users")
            .document(user_id)
            .collection("sessions")
            .document(session_id)
        )
        session_doc_ref.set(
            {"last_active": firestore.SERVER_TIMESTAMP, "status": "active"},
            merge=True,
        )
        session_doc_ref.collection("chat").add(
            {
                "user_message": user_msg,
                "assistant_reply": assistant_msg,
                "timestamp": firestore.SERVER_TIMESTAMP,
            }
        )
    except Exception as exc:
        print(f"WARNING: save_chat_pair failed ({exc})")


# ── USER / LAWYER REGISTRATION HELPERS ──

def save_user(user_id: str, email: str, phone: str = None) -> None:
    """Create or update a user profile at users/{user_id}/profile."""
    if db is None:
        return
    try:
        payload = {
            "email": email,
            "role": "user",
            "created_at": firestore.SERVER_TIMESTAMP,
        }
        if phone:
            payload["phone"] = phone
        db.collection("users").document(user_id).set(
            {"profile": payload}, merge=True
        )
    except Exception as exc:
        print(f"WARNING: save_user failed ({exc})")


def save_lawyer(
    lawyer_id: str,
    name: str,
    email: str,
    bar_number: str,
    specialization: str,
    city: str,
    phone: str = None,
) -> None:
    """Create or update a lawyer profile at lawyers/{lawyer_id}/profile."""
    if db is None:
        return
    try:
        payload = {
            "name": name,
            "email": email,
            "bar_number": bar_number,
            "specialization": specialization,
            "city": city,
            "role": "lawyer",
            "verified": False,
            "created_at": firestore.SERVER_TIMESTAMP,
        }
        if phone:
            payload["phone"] = phone
        db.collection("lawyers").document(lawyer_id).set(
            {"profile": payload}, merge=True
        )
    except Exception as exc:
        print(f"WARNING: save_lawyer failed ({exc})")


def verify_lawyer(lawyer_id: str) -> None:
    """Mark a lawyer as verified at lawyers/{lawyer_id}/profile."""
    if db is None:
        return
    try:
        db.collection("lawyers").document(lawyer_id).set(
            {"profile": {"verified": True}}, merge=True
        )
    except Exception as exc:
        print(f"WARNING: verify_lawyer failed ({exc})")
