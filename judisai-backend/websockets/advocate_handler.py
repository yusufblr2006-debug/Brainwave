"""
websockets/advocate_handler.py — Digital Advocate: Live Police Stop AI Proxy.

This WebSocket endpoint acts as a real-time legal proxy on behalf of an Indian
citizen during a live police traffic stop or interrogation. It receives text
from the Flutter client (typically the transcribed speech of a police officer),
sends it to Groq LLM with a specialized authoritative legal persona, and returns
the AI's response as a plain string for the Flutter Text-to-Speech engine.

Design principles:
  - String in, string out. No audio bytes, no binary frames.
  - Minimum latency: no extra processing layers between receive and send.
  - Graceful degradation: on any error, sends a JSON error message and closes.
  - AdvocateMessage schema validates every incoming JSON payload.
"""

import json
import os

import groq
from dotenv import load_dotenv
from fastapi import WebSocket, WebSocketDisconnect

from schemas import AdvocateMessage

# Load environment variables
load_dotenv()

# ── GROQ CLIENT for advocate handler ──
# Uses the same API key as ai_engine.py but is instantiated separately here
# to keep the WebSocket handler self-contained and independently testable.

_GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not _GROQ_API_KEY:
    print("WARNING: GROQ_API_KEY not set. advocate_socket_handler will fail at runtime.")

_advocate_client = groq.Groq(api_key=_GROQ_API_KEY)

# ── SYSTEM PROMPT — injected exactly as specified ──
# This prompt must NOT be modified. It is the legal persona of the Digital Advocate.
# Output is fed directly into a Text-to-Speech engine on the Flutter side, so:
#   - No asterisks or markdown formatting
#   - Short, authoritative sentences
#   - Cites BNSS (Bharatiya Nagarik Suraksha Sanhita) or Motor Vehicles Act
#   - Politely immovable — firm but not aggressive

ADVOCATE_SYSTEM_PROMPT = (
    "You are a Digital Legal Advocate AI. You speak in the SAME LANGUAGE "
    "the user is speaking (auto-detect). Sound natural and human, not robotic. "
    "You protect the citizen's legal rights under Indian law. "
    "Be authoritative but calm. Keep responses under 3 sentences."
)


async def advocate_socket_handler(websocket: WebSocket, user_id: str) -> None:
    """
    WebSocket handler for the Digital Advocate endpoint.

    Endpoint: ws://<host>/ws/advocate/{user_id}

    Message contract (Flutter → Backend):
        JSON string: {"speaker": "police", "text": "<what the officer said>"}
        Parsed via AdvocateMessage schema.

    Response contract (Backend → Flutter):
        Plain UTF-8 string — the AI advocate's spoken response.
        On error: JSON string {"error": "Advocate offline", "status": "error"}
        followed by graceful connection close.

    Args:
        websocket: The FastAPI WebSocket connection object.
        user_id:   Path parameter identifying the citizen; used for logging.
    """
    await websocket.accept()
    print(f"[AdvocateHandler] Connection accepted for user_id={user_id}")

    try:
        while True:
            # ── Step 1: Receive raw text payload from Flutter client ──
            raw_payload = await websocket.receive_text()

            # ── Step 2: Parse and validate using AdvocateMessage schema ──
            try:
                payload_dict = json.loads(raw_payload)
                advocate_message = AdvocateMessage(**payload_dict)
            except (json.JSONDecodeError, ValueError) as parse_err:
                print(f"[AdvocateHandler] Parse error for user_id={user_id}: {parse_err}")
                await websocket.send_text(
                    json.dumps({"error": "Invalid payload format", "status": "error"})
                )
                continue

            officer_text = advocate_message.text
            print(
                f"[AdvocateHandler] user_id={user_id} | "
                f"speaker={advocate_message.speaker} | text={officer_text[:80]}"
            )

            # ── Step 3: Build Groq message list — system prompt + history + officer utterance ──
            messages: list[dict] = []
            
            if not getattr(advocate_message, "is_continuation", False) or not getattr(advocate_message, "history", []):
                messages.append({"role": "system", "content": ADVOCATE_SYSTEM_PROMPT})
            else:
                continuation_prompt = (
                    ADVOCATE_SYSTEM_PROMPT + 
                    " This is the same conversation continuing. Do NOT re-introduce yourself. Continue naturally."
                )
                messages.append({"role": "system", "content": continuation_prompt})
                for msg in advocate_message.history:
                    role = msg.get("role", "user")
                    if role == "ai":
                        role = "assistant"
                    messages.append({"role": role, "content": msg.get("text", "")})
            
            messages.append({
                "role": "user",
                "content": officer_text,
            })

            # ── Step 4: Call Groq — minimise latency with max_tokens=300 ──
            try:
                response = _advocate_client.chat.completions.create(
                    model="llama-3.3-70b-versatile",
                    messages=messages,
                    max_tokens=300,
                )
                ai_reply = response.choices[0].message.content.strip()
            except Exception as groq_err:
                print(f"[AdvocateHandler] Groq error for user_id={user_id}: {groq_err}")
                await websocket.send_text(
                    json.dumps({"error": "Advocate offline", "status": "error"})
                )
                await websocket.close()
                return

            # ── Step 5: Send plain string response back to Flutter TTS engine ──
            await websocket.send_text(ai_reply)
            print(
                f"[AdvocateHandler] Sent reply to user_id={user_id}: {ai_reply[:80]}"
            )

    except WebSocketDisconnect:
        print(f"[AdvocateHandler] Client disconnected: user_id={user_id}")

    except Exception as exc:
        print(f"[AdvocateHandler] Unexpected error for user_id={user_id}: {exc}")
        try:
            await websocket.send_text(
                json.dumps({"error": "Advocate offline", "status": "error"})
            )
            await websocket.close()
        except Exception:
            pass  # Connection may already be closed; suppress secondary errors
