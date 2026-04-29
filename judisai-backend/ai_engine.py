"""
ai_engine.py - Core AI functions for JudisAI.

Every major function references the specific reference file it was modeled after:
  - get_legal_context()  -> rag_reasoning_agent.py
  - get_ai_reply()       -> legal_agent_team.py
  - analyze_case()       -> support_ticket_agent.py
  - analyze_image()      -> NEW: Multimodal Evidence Analyzer
"""

import base64
import json
import os
import re

import groq
from dotenv import load_dotenv
from fastapi import HTTPException

from database import legal_collection
from schemas import AnalyzeCaseResponse, OcrResponse

# Load environment variables from .env
load_dotenv()

# ── GROQ CLIENT INIT ──

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    print("WARNING: GROQ_API_KEY not found in .env. AI features will fail at runtime.")

client = groq.Groq(api_key=GROQ_API_KEY)


# ── RAG FUNCTION ──
# Architecture from: rag_reasoning_agent.py
# Mirrors the RAG retrieval loop: query the vector DB, retrieve top-N results,
# format them as context strings with titles and summaries, and return them
# for injection into the system prompt — exactly as rag_reasoning_agent.py
# loads knowledge via its Knowledge/LanceDb vector search and feeds results
# into the agent's reasoning pipeline (search_knowledge=True).

def get_legal_context(query: str) -> str:
    """
    Query ChromaDB for the top-2 most relevant Indian legal cases and return
    a formatted context string ready to be prepended to the system prompt.

    # Architecture from: rag_reasoning_agent.py
    Mirrors the knowledge retrieval pattern where the agent always searches its
    vector database before answering (search_knowledge=True in the Agno agent),
    then includes the retrieved source titles and summaries in its response.
    ChromaDB collection.query() is the direct analogue of LanceDb vector search.

    Args:
        query: The user's legal question or message text.

    Returns:
        A formatted string of the form:
            "Relevant Case: <title>\\nSummary: <summary>\\n\\n..."
        Returns an empty string on any failure so the caller is never blocked.
    """
    try:
        results = legal_collection.query(
            query_texts=[query],
            n_results=2,
        )

        # Guard against empty results
        if (
            not results
            or not results.get("documents")
            or not results["documents"][0]
        ):
            return ""

        context_parts = []
        for i, doc in enumerate(results["documents"][0]):
            metadata = results["metadatas"][0][i] if results.get("metadatas") else {}
            title = metadata.get("title", "Unknown Case")
            summary = doc
            context_parts.append(f"Relevant Case: {title}\nSummary: {summary}")

        return "\n\n".join(context_parts)

    except Exception as exc:
        print(f"[get_legal_context] RAG retrieval error: {exc}")
        return ""


# ── CHAT FUNCTION ──
# Architecture from: legal_agent_team.py
# Mirrors the multi-persona system prompt architecture where specialized legal
# agents (Legal Researcher, Contract Analyst, Legal Strategist) each have
# detailed role-specific instructions, and the Team Lead coordinates analysis
# by combining knowledge from all agents with search_knowledge=True.
# JudisAI consolidates these personas into a single comprehensive system prompt
# that covers fact-gathering (Legal Researcher role), citing laws/precedents
# (Legal Researcher + Strategist), and step-by-step guidance (Strategist).
# RAG context is prepended to the system prompt, mirroring how legal_agent_team.py
# passes knowledge=st.session_state.knowledge_base to every agent.

def get_ai_reply(session_id: str, message: str, history: list[dict]) -> str:
    """
    Generate an AI reply using Groq LLM with RAG-enriched context and
    the last 6 messages of conversation history.

    # Architecture from: legal_agent_team.py
    Mirrors the multi-persona system prompt and fact-gathering loop.
    Combines the roles of:
      - Legal Researcher  → cite relevant cases/precedents from ChromaDB RAG
      - Contract Analyst  → identify key legal terms and issues in the user's situation
      - Legal Strategist  → provide actionable, step-by-step recommendations
    All within a single JudisAI persona, exactly as legal_agent_team.py's Team
    coordinates its three agents to produce a unified analysis.

    Args:
        session_id: The conversation session identifier (used for logging).
        message:    The current user message.
        history:    Prior messages as [{"role": "user"|"assistant", "content": "..."}].

    Returns:
        The AI-generated reply string.

    Raises:
        HTTPException(500) on any Groq API or processing failure.
    """
    try:
        # Step 1: Retrieve RAG context — mirrors search_knowledge=True in legal_agent_team.py
        rag_context = get_legal_context(message)

        # Step 2: Build multi-persona system prompt — mirrors legal_agent_team.py agent instructions
        base_system_prompt = (
            "You are JudisAI, an expert Indian legal assistant operating under Indian law "
            "(IPC, CrPC, Constitution of India, Consumer Protection Act, IT Act, etc.). "
            "Ask targeted follow-up questions to gather facts, cite relevant sections and "
            "precedents, and guide users step-by-step. Be empathetic but precise. "
            "Always recommend consulting a licensed advocate for formal advice."
        )

        if rag_context:
            system_prompt = (
                f"{base_system_prompt}\n\n"
                f"--- Relevant Legal Context (retrieved from knowledge base) ---\n"
                f"{rag_context}\n"
                f"--- End of Context ---\n"
                f"Use the above context to cite specific cases and sections where relevant."
            )
        else:
            system_prompt = base_system_prompt

        # Step 3: Assemble messages — system prompt + last 6 history + current user turn
        # This mirrors legal_agent_team.py's fact-gathering loop where the team
        # processes multiple rounds of Q&A before delivering a final analysis.
        messages: list[dict] = [{"role": "system", "content": system_prompt}]

        recent_history = history[-6:] if len(history) > 6 else history
        for msg in recent_history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            # Only include valid roles that Groq accepts
            if role in ("user", "assistant"):
                messages.append({"role": role, "content": content})

        messages.append({"role": "user", "content": message})

        # Step 4: Call Groq — the primary reasoning engine
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            max_tokens=1024,
        )

        return response.choices[0].message.content

    except HTTPException:
        raise
    except Exception as exc:
        print(f"[get_ai_reply] Error for session {session_id}: {exc}")
        raise HTTPException(
            status_code=500,
            detail=f"AI reply generation failed: {exc}",
        )


# ── CASE ANALYSIS FUNCTION ──
# Architecture from: support_ticket_agent.py
# Mirrors the structured output pattern where the agent is instructed to return
# ONLY a valid JSON object matching a specific Pydantic schema — in
# support_ticket_agent.py this is enforced via output_type=SupportTicket.
# Here we replicate that pattern by:
#   (1) Instructing the LLM to return pure JSON only (no prose, no markdown)
#   (2) Stripping ```json ... ``` markdown fences before parsing
#   (3) Using json.loads() to parse, then mapping fields to AnalyzeCaseResponse
# This is identical in spirit to how support_ticket_agent.py extracts a
# structured SupportTicket (title, priority, category, steps_to_reproduce, etc.)
# from free-form customer complaint text.

def analyze_case(history: list[dict]) -> AnalyzeCaseResponse:
    """
    Analyze a conversation history and extract a structured legal case report.

    # Architecture from: support_ticket_agent.py
    Mirrors the strict Pydantic-enforced JSON extraction pattern:
      - System prompt demands ONLY a JSON object (no prose, no markdown fences)
      - Mirrors support_ticket_agent.py's output_type=SupportTicket pattern
      - Strips ```json fences before json.loads() — handles model fence wrapping
      - Maps parsed keys to AnalyzeCaseResponse fields with safe .get() defaults
      - Returns a safe default AnalyzeCaseResponse(status="error") on any failure

    Args:
        history: List of chat messages [{"role": "user"|"assistant", "content": "..."}].

    Returns:
        AnalyzeCaseResponse populated with AI-extracted legal analysis fields.
    """
    try:
        # Step 1: Flatten history into readable conversation text
        conversation_text = ""
        for msg in history:
            role = msg.get("role", "user").capitalize()
            content = msg.get("content", "")
            conversation_text += f"{role}: {content}\n"

        if not conversation_text.strip():
            conversation_text = "No conversation history available."

        # Step 2: System prompt demanding strict JSON output
        # Mirrors support_ticket_agent.py's instruction: "Always return a valid JSON object
        # matching the SupportTicket schema" / output_type=SupportTicket enforcement.
        system_prompt = (
            "You are a legal analysis engine. Return ONLY a JSON object with these keys: "
            "case_summary (string), applicable_indian_laws (array of strings), "
            "missing_evidence (array of strings), risk_score (integer 0-100), "
            "case_category (string). "
            "No prose, no markdown, no explanation outside the JSON. Pure JSON only."
        )

        messages: list[dict] = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": conversation_text},
        ]

        # Step 3: Call Groq API
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            max_tokens=1024,
        )

        raw_content = response.choices[0].message.content

        # Step 4: Strip markdown fences — handles ```json ... ``` and ``` ... ```
        # Mirrors support_ticket_agent.py's robustness requirement that the
        # output always maps cleanly to the target Pydantic model.
        cleaned = raw_content.strip()
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.IGNORECASE)
        cleaned = re.sub(r"\s*```$", "", cleaned)
        cleaned = cleaned.strip()

        # Step 5: Parse JSON and map to AnalyzeCaseResponse Pydantic model
        parsed = json.loads(cleaned)

        return AnalyzeCaseResponse(
            case_summary=str(parsed.get("case_summary", "")),
            applicable_indian_laws=list(parsed.get("applicable_indian_laws", [])),
            missing_evidence=list(parsed.get("missing_evidence", [])),
            risk_score=int(parsed.get("risk_score", 0)),
            case_category=str(parsed.get("case_category", "")),
            status="success",
        )

    except (json.JSONDecodeError, KeyError, ValueError, TypeError) as exc:
        print(f"[analyze_case] JSON parse error: {exc}")
        return AnalyzeCaseResponse(
            case_summary="",
            applicable_indian_laws=[],
            missing_evidence=[],
            risk_score=0,
            case_category="",
            status="error",
        )
    except Exception as exc:
        print(f"[analyze_case] Unexpected error: {exc}")
        return AnalyzeCaseResponse(
            case_summary="",
            applicable_indian_laws=[],
            missing_evidence=[],
            risk_score=0,
            case_category="",
            status="error",
        )


async def generate_complaint(extracted_text: str, violations: list[str], user_name: str) -> str:
    """Generate a formal complaint letter."""
    try:
        system_prompt = (
            "You are a legal assistant. Generate a formal complaint letter addressed to the appropriate Indian authority. "
            "Use the provided text, violations, and user name. "
            "Return ONLY the plain text of the letter, no formatting or JSON."
        )
        
        user_content = (
            f"User Name: {user_name}\n"
            f"Violations: {', '.join(violations)}\n"
            f"Extracted Text Context: {extracted_text}"
        )

        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content},
            ],
            max_tokens=1024,
        )
        return response.choices[0].message.content.strip()
    except Exception as exc:
        print(f"[generate_complaint] Error: {exc}")
        return f"Failed to generate complaint: {exc}"


def generate_report(history: list[dict]) -> dict:
    """Generate a structured legal report from history."""
    try:
        conversation_text = ""
        for msg in history:
            role = msg.get("role", "user").capitalize()
            content = msg.get("content", "")
            conversation_text += f"{role}: {content}\n"

        system_prompt = (
            "You are a legal analysis engine. Return ONLY a JSON object with these keys: "
            "summary (string), laws (array of strings), risks (string), actions (array of strings). "
            "Pure JSON only, no markdown."
        )

        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": conversation_text},
            ],
            max_tokens=1024,
        )

        raw = response.choices[0].message.content.strip()
        raw = re.sub(r"^```(?:json)?\s*", "", raw, flags=re.IGNORECASE)
        raw = re.sub(r"\s*```$", "", raw).strip()
        
        parsed = json.loads(raw)
        return {
            "summary": str(parsed.get("summary", "")),
            "laws": list(parsed.get("laws", [])),
            "risks": str(parsed.get("risks", "")),
            "actions": list(parsed.get("actions", [])),
        }
    except Exception as exc:
        print(f"[generate_report] Error: {exc}")
        return {
            "summary": "Error generating report",
            "laws": [],
            "risks": "Unknown",
            "actions": [],
        }


# ── IMAGE ANALYSIS FUNCTION ──
# Architecture from: NEW — Multimodal Evidence Analyzer
# Uses Groq's vision-capable model (meta-llama/llama-4-scout-17b-16e-instruct)
# to analyze images of legal documents (FIRs, notices, receipts, contracts, etc.).

async def analyze_image(image_bytes: bytes, filename: str) -> OcrResponse:
    """
    Analyze an image of a legal document using Groq's multimodal vision model.

    Extracts all visible text from the image, identifies any Indian legal
    violations cited in that text, and suggests recommended legal actions —
    all returned as a structured OcrResponse.

    # Architecture from: NEW — Multimodal Evidence Analyzer
    Follows the same Pydantic-enforced JSON extraction pattern as analyze_case():
      - System prompt demands pure JSON only (no prose, no markdown)
      - Image is base64-encoded and sent as a data URI in the vision message
      - ```json fences are stripped before json.loads()
      - All fields mapped to OcrResponse with safe defaults
      - Returns OcrResponse(status="error") on any failure — never raises

    Args:
        image_bytes: Raw bytes of the uploaded image (JPEG, PNG, WEBP, etc.).
        filename:    Original filename used to detect MIME type.

    Returns:
        OcrResponse with extracted_text, legal_violations, recommended_actions,
        and status="success" on success, or status="error" on any failure.
    """
    try:
        # Step 1: Base64-encode; detect MIME type from extension
        base64_image = base64.b64encode(image_bytes).decode("utf-8")
        ext = filename.split(".")[-1].lower()
        media_type = "image/png" if ext == "png" else "image/jpeg"
        image_data_uri = f"data:{media_type};base64,{base64_image}"

        # Step 2: Call Groq vision model with image + instruction
        response = client.chat.completions.create(
            model="meta-llama/llama-4-scout-17b-16e-instruct",
            messages=[{
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {"url": image_data_uri},
                    },
                    {
                        "type": "text",
                        "text": (
                            "You are an Indian legal evidence analyzer. Extract all text from this image. "
                            "Identify any legal violations under Indian law (cite specific Acts and sections). "
                            "Return ONLY JSON with keys: extracted_text (string), "
                            "legal_violations (array of strings), recommended_actions (array of strings). "
                            "Pure JSON only, no markdown."
                        ),
                    },
                ],
            }],
            max_tokens=1024,
        )

        # Step 3: Strip markdown fences and parse
        raw = response.choices[0].message.content.strip()
        raw = raw.replace("```json", "").replace("```", "").strip()
        cleaned = raw

        # Step 4: Parse JSON → OcrResponse
        parsed = json.loads(cleaned)
        return OcrResponse(
            extracted_text=parsed.get("extracted_text", ""),
            legal_violations=parsed.get("legal_violations", []),
            recommended_actions=parsed.get("recommended_actions", []),
            status="success",
        )

    except (json.JSONDecodeError, KeyError, ValueError, TypeError) as exc:
        print(f"[analyze_image] JSON parse error: {exc}")
        return OcrResponse(extracted_text="", legal_violations=[], recommended_actions=[], status="error")
    except Exception as exc:
        print(f"[analyze_image] Unexpected error: {exc}")
        return OcrResponse(extracted_text="", legal_violations=[], recommended_actions=[], status="error")


# ── TRANSLATION FUNCTION ──

async def translate_text(text: str, target_language: str) -> str:
    """
    Translate text to the target language using Groq LLM.

    Args:
        text:            Source text.
        target_language: Target language name (e.g. 'Hindi', 'Tamil', 'Telugu').

    Returns:
        Translated text string.

    Raises:
        HTTPException(500) on Groq API failure.
    """
    try:
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[
                {
                    "role": "system",
                    "content": (
                        f"Translate the following to {target_language}. "
                        "Return ONLY the translated text, nothing else."
                    ),
                },
                {"role": "user", "content": text},
            ],
            max_tokens=1024,
        )
        return response.choices[0].message.content.strip()
    except Exception as exc:
        print(f"[translate_text] Error: {exc}")
        raise HTTPException(status_code=500, detail=f"Translation failed: {exc}")
