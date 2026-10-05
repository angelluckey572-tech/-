const express = require("express");
const cors = require("cors");
const app = express();

app.use(cors());
app.use(express.json());

const activeSessions = new Set();
const commandQueues = {};

// Root URL Check
app.get("/", (req, res) => {
  res.send("Roblox Relay Server is running online!");
});

// Register Active User ID
app.post("/register", (req, res) => {
  const { userId } = req.body;
  if (userId) {
    activeSessions.add(userId);
    if (!commandQueues[userId]) commandQueues[userId] = [];
  }
  res.json({ success: true });
});

// Poll for Commands & Active Directory
app.get("/poll/:userId", (req, res) => {
  const { userId } = req.params;
  activeSessions.add(userId);
  
  const commands = commandQueues[userId] || [];
  commandQueues[userId] = [];

  res.json({
    activeSessions: Array.from(activeSessions),
    commands: commands
  });
});

// Send Commands to Clients
app.post("/send-command", (req, res) => {
  const { senderId, targetId, text } = req.body;
  const payload = { senderId, text, timestamp: Date.now() };

  if (targetId === "ALL" || !targetId) {
    for (const uid of activeSessions) {
      if (!commandQueues[uid]) commandQueues[uid] = [];
      commandQueues[uid].push(payload);
    }
  } else {
    if (!commandQueues[targetId]) commandQueues[targetId] = [];
    commandQueues[targetId].push(payload);
  }

  res.json({ success: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
