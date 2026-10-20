
import "dotenv/config";
import express from "express";
import cors from "cors";
import { GoogleGenAI } from "@google/genai";

const app = express();

app.use(cors({
    origin: [
        /^http:\/\/localhost:\d+$/,
        /^http:\/\/127\.0\.0\.1:\d+$/
    ]
}));

app.use(express.json({ limit: "20kb" }));

const apiKey = process.env.GEMINI_API_KEY;

if (!apiKey) {
    throw new Error("GEMINI_API_KEY is missing from .env");
}

const ai = new GoogleGenAI({ apiKey });

app.get("/health", (req, res) => {
    res.json({ status: "ok", service: "UniRide AI Backend" });
});

// Role-specific system instructions
function getSystemInstruction(role) {
    const base = `You are UniRide AI, an intelligent university bus transportation assistant for a mobile app called UniRide (tagline: "Your campus. Our ride.").
The app manages bus reservations, QR boarding passes, real-time seat availability, and demand-based bus allocation for university students.
Key facts about UniRide:
- Students can reserve seats or standing spots on buses.
- Each reservation gets a unique QR code for boarding.
- Cancellation limit: ${2} per period before a ${7}-day penalty is applied.
- When buses are full, students can request extra buses; 15+ requests for same destination triggers admin notification.
- Three user roles: Student, Driver, Administrator.
Never invent real-time data (schedules, seat counts, confirmations) — only the booking system has ground truth.
Be helpful, concise, friendly, and professional.`;

    switch (role) {
        case "student":
            return base + `
You are speaking with a STUDENT. Help them:
- Find the best buses for their schedule and location
- Understand reservation and cancellation policies
- Plan trips using AI recommendations
- Understand QR code boarding process
- Request extra buses when needed`;

        case "driver":
            return base + `
You are speaking with a DRIVER. Help them:
- Manage their daily route and passenger lists
- Understand boarding procedures and QR validation
- Handle passenger queries professionally
- Report issues or request support
- Understand schedule and status updates`;

        case "admin":
            return base + `
You are speaking with an ADMINISTRATOR. Help them:
- Analyze ridership patterns and demand
- Make data-driven decisions about bus allocation
- Understand extra bus request thresholds
- Manage user penalties and access issues
- Optimize fleet scheduling based on demand`;

        default:
            return base;
    }
}

app.post("/api/chat", async (req, res) => {
    try {
        const message = req.body?.message;
        const role = req.body?.role || "student";
        const context = req.body?.context || "";

        if (typeof message !== "string" || !message.trim()) {
            return res.status(400).json({ error: "Please enter a message." });
        }

        const fullMessage = context ? `${context}${message.trim()}` : message.trim();

        const result = await ai.models.generateContent({
            model: "gemma-4-26b-a4b-it",
            contents: fullMessage,
            config: {
                systemInstruction: getSystemInstruction(role)
            }
        });

        res.json({
            reply: result.text || "Sorry, I couldn't generate a response.",
            role: role
        });

    } catch (error) {
        console.error("AI request failed:", error.message);
        res.status(502).json({
            error: "The AI service is temporarily unavailable.",
            details: error.message
        });
    }
});

// Trip recommendation endpoint
app.post("/api/recommend", async (req, res) => {
    try {
        const { origin, destination, time, schedule } = req.body;

        const prompt = `As UniRide AI, recommend bus options for a student:
- From: ${origin || "campus"}
- To: ${destination || "university"}  
- Preferred departure: ${time || "8:00 AM"}
${schedule ? `- Student schedule: ${schedule}` : ""}

Provide 2-3 specific, actionable recommendations. Format as numbered list.`;

        const result = await ai.models.generateContent({
            model: "gemma-4-26b-a4b-it",
            contents: prompt,
            config: { systemInstruction: getSystemInstruction("student") }
        });

        res.json({ recommendations: result.text });
    } catch (error) {
        res.status(502).json({ error: "AI unavailable" });
    }
});

const PORT = 3000;
app.listen(PORT, "127.0.0.1", () => {
    console.log(`✅ UniRide AI Backend running at http://127.0.0.1:${PORT}`);
    console.log(`   Endpoints: GET /health | POST /api/chat | POST /api/recommend`);
});
