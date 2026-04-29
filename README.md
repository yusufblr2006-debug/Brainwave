
⚖️ JudisAI

*Your AI-powered pocket lawyer. Built for India, designed for everyone.*

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/344b5455-12d6-4eb8-aa36-03770ebac472" />


## 💡 The Problem
The Indian legal system is complex, intimidating, and often inaccessible to the average citizen. Whether dealing with a sudden property dispute, workplace harassment, or a confusing rental agreement, people rarely know their fundamental rights. Hiring a lawyer just to understand a legal notice is a financial barrier many cannot cross.

## 🚀 The Solution
**JudisAI** democratizes legal assistance. We built a fully native, multi-agent AI mobile application that puts a highly trained legal expert right in your pocket. It reads your documents, understands Indian law, talks to you in real-time over voice, and provides actionable, step-by-step guidance. 

If the AI determines you need human representation, it seamlessly transitions you to our integrated Lawyer Marketplace to find verified experts.

---

## ✨ Core Features & Capabilities

* 🤖 **Multi-Agent Legal Engine:** The core of JudisAI isn't just a basic chatbot. We built a routing architecture that intelligently passes your query between a **RAG Reasoning Agent** (for case law), a **Support Agent** (for general guidance), and a **Legal Drafting Agent**.
* 🎙️ **The Digital Advocate (Live Voice):** A fully bidirectional, real-time voice interface powered by WebSockets. Tap the mic and have a live conversation with the AI, just like a real phone call with an advocate.
* 📸 **Evidence Analyzer (Hardware OCR):** Native camera integration allows users to snap photos of physical legal notices or contracts. The AI extracts the text, deciphers the legalese, and highlights immediate risks.
* 📝 **Automated Legal Drafting:** Need to file a formal complaint? The AI automatically drafts perfectly formatted, legally sound letters and notices based on your chat context.
* 🤝 **Lawyer Marketplace:** A fully functional booking interface that matches users with domain-specific lawyers (e.g., Property, Cyber, Family Law) complete with win-rates and consultation fees.

---

## 🛠️ The Tech Stack

**Frontend (Mobile & Web)**
* **Framework:** Flutter & Dart
* **State Management:** Riverpod / Provider
* **Hardware:** Native Android `camera` bindings and `speech_to_text` integration.

**Backend & AI Engine**
* **Framework:** FastAPI (Python)
* **Real-Time Communication:** WebSockets (`wsproto`) for live audio/text streaming.
* **Vector Database:** ChromaDB (storing context from `legal_cases.json`).
* **Authentication:** Firebase Admin SDK.

---

## 💻 How to Run the Project Locally

Before we begin all the files/folders other than judisai-backend must be put into a seperate folder to run the frontend separately. Groq api key file and firebase service accounts file must be added manually.

Because we built this to be completely cross-platform, you can run JudisAI natively on a physical Android phone or locally on a web browser. 

### Step 1: Boot the Backend
Navigate to the backend folder, install dependencies, and start the FastAPI server unlocked for external network traffic:
```bash
cd judisai-backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000 --ws wsproto
```

### Step 2: Choose your Frontend Deployment

#### Option A: Native Android Testing (Physical Device via USB)
To run the app natively with full hardware access (Camera/Mic) while tethered to the local backend:
1. Connect your Android phone via USB.
2. In a new terminal, spin up a LocalTunnel to expose the backend to the internet:
   ```bash
   npx.cmd localtunnel --port 8000
   ```
3. Copy the generated `loca.lt` link.
4. Open `lib/config/constants.dart` and update the URLs:
   ```dart
   const String BASE_URL = '[https://your-link.loca.lt](https://your-link.loca.lt)';
   const String WS_URL = 'wss://your-link.loca.lt';
   ```
5. Deploy to the phone:
   ```bash
   flutter run
   ```

#### Option B: Local Web Testing (Microsoft Edge / Chrome)
For rapid UI prototyping without network tunnels:
1. Open `lib/config/constants.dart` and point the app directly to localhost:
   ```dart
   const String BASE_URL = '[http://127.0.0.1:8000](http://127.0.0.1:8000)';
   const String WS_URL = 'ws://127.0.0.1:8000';
   ```
2. Deploy to the local browser:
   ```bash
   flutter run -d edge
   ```

---

The Hackathon Story
This project was an absolute grind. We started with basic web browser testing but realized the vision demanded a true mobile experience. 

In the final hours of the hackathon, we completely pivoted to a native Android deployment. We battled local network routing firewalls, wrestled with strict Android `RECORD_AUDIO` permissions to get the WebSockets talking, and completely rebuilt our chat architecture to eliminate rendering loops. We broke things, patched them with local tunnels and SSH routing, and ultimately delivered a fully hardware-integrated AI app.

This perfectly captures the technical complexity of the backend, the exact deployment instructions you figured out, and acknowledges the absolute battle you went through tonight. Push this up and you'll have an incredibly professional GitHub repo ready for the judges!
