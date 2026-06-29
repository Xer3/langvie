const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const openaiApiKey = defineSecret("OPENAI_API_KEY");

exports.aiChat = onRequest(
  {
    region: "europe-west1",
    secrets: [openaiApiKey],
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (req, res) => {
    try {
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      if (req.method !== "POST") {
        res.status(405).json({ error: "Method not allowed" });
        return;
      }

      const authHeader = req.headers.authorization || "";
      const match = authHeader.match(/^Bearer (.+)$/);

      if (!match) {
        res.status(401).json({ error: "Brak tokenu użytkownika." });
        return;
      }

      const idToken = match[1];

      try {
        await admin.auth().verifyIdToken(idToken);
      } catch (e) {
        logger.warn("Invalid Firebase ID token", e);
        res.status(401).json({ error: "Nieprawidłowy token użytkownika." });
        return;
      }

      const messages = req.body && req.body.messages;

      if (!Array.isArray(messages)) {
        res.status(400).json({ error: "Brak poprawnej listy messages." });
        return;
      }

      const allowedRoles = new Set(["system", "user", "assistant"]);

      const safeMessages = messages
        .filter((m) => {
          return (
            m &&
            typeof m.role === "string" &&
            typeof m.content === "string" &&
            allowedRoles.has(m.role)
          );
        })
        .slice(-20)
        .map((m) => ({
          role: m.role,
          content: m.content.slice(0, 4000),
        }));

      if (safeMessages.length === 0) {
        res.status(400).json({ error: "Brak wiadomości do wysłania." });
        return;
      }

      const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openaiApiKey.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: "gpt-4.1-mini",
          temperature: 0.4,
          messages: safeMessages,
        }),
      });

      const data = await openaiRes.json();

      if (!openaiRes.ok) {
        logger.error("OpenAI error", data);
        res.status(500).json({
          error: "Błąd po stronie asystenta AI.",
        });
        return;
      }

      const reply = data?.choices?.[0]?.message?.content;

      if (typeof reply !== "string" || reply.trim().length === 0) {
        res.status(500).json({ error: "Pusta odpowiedź z AI." });
        return;
      }

      res.status(200).json({
        reply: reply.trim(),
      });
    } catch (e) {
      logger.error("aiChat failed", e);
      res.status(500).json({
        error: "Wewnętrzny błąd serwera.",
      });
    }
  }
);