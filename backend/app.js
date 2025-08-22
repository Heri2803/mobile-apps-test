const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const path = require("path");
const { sequelize } = require("./models");

// Import Routes
const userRoutes = require("./routes/userRoutes");
const taskRoutes = require("./routes/taskRoutes");
const authRoutes = require("./routes/authRoutes");
const taskSubmissions = require("./routes/taskSubmissionsRoutes");

// Import Swagger (sudah Anda buat di swagger.js)
const swaggerDocs = require("./swagger");

dotenv.config();
const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// Serve file statis untuk upload PDF
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Serve file statis untuk folder uploadFoto
app.use("/uploadFoto", express.static(path.join(__dirname, "uploadFoto")));

// Routes
app.use("/api/users", userRoutes);
app.use("/api/tasks", taskRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/task-submissions", taskSubmissions);

app.get("/", (req, res) => {
  res.send("Backend API for Task Management is running 🚀");
});

// Swagger Documentation
swaggerDocs(app);

// Database Initialization
const initializeDatabase = async () => {
  try {
    await sequelize.sync({ force: false }); // force:false agar data lama tidak hilang
    console.log("✅ Database synced");
  } catch (error) {
    console.error("❌ Error syncing database:", error);
    throw error;
  }
};

// Start Server
const PORT = process.env.PORT || 5000;
initializeDatabase()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`🚀 Server running on port ${PORT}`);
      console.log(`📑 Swagger UI available at http://localhost:${PORT}/api-docs`);
    });
  })
  .catch((error) => {
    console.error("❌ Error starting the server:", error);
    process.exit(1);
  });
