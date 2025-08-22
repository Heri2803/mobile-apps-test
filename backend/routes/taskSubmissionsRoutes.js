const express = require("express");
const router = express.Router();
const taskController = require("../controller/taskcontroller");
const auth = require("../middleware/authMiddleware");
const multer = require("multer");
const path = require("path");

// Konfigurasi Multer (untuk upload PDF)
const storage = multer.diskStorage({
  destination: "./uploads",
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });

/**
 * @swagger
 * /api/task-submissions/{id}:
 *   put:
 *     summary: Update submission berdasarkan ID (siswa upload PDF)
 *     tags: [TaskSubmissions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID task submission yang akan diperbarui
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               pdf_file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Submission berhasil diperbarui
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Submission berhasil diperbarui
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     task_id:
 *                       type: integer
 *                       example: 5
 *                     user_id:
 *                       type: integer
 *                       example: 10
 *                     pdf_file:
 *                       type: string
 *                       example: "submission_12345.pdf"
 *                     submitted_at:
 *                       type: string
 *                       format: date-time
 *                       example: "2025-08-20 15:30:00"
 *                     status:
 *                       type: string
 *                       enum: [selesai, terlambat, tidak dikumpulkan]
 *                       example: selesai
 */
router.put(
  "/:id",
  auth,
  upload.single("pdf_file"),
  taskController.updateSubmission
);

module.exports = router;
