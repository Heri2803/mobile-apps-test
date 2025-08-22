const express = require("express");
const router = express.Router();
const authController = require("../controller/authcontroller");
const multer = require("multer");
const path = require("path");

// Setup Multer untuk upload foto
const storage = multer.diskStorage({
  destination: "./uploadFoto", // simpan di folder uploads/foto
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});
const upload = multer({ storage });


/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: API untuk autentikasi user
 */

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register user baru (dengan upload foto)
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Guru Satu"
 *               nip:
 *                 type: string
 *                 example: "123456"
 *               password:
 *                 type: string
 *                 example: "password123"
 *               role:
 *                 type: string
 *                 enum: [siswa, guru]
 *                 example: "guru"
 *               jurusan:
 *                 type: string
 *                 example: "Teknik Informatika"
 *               kelas:
 *                 type: string
 *                 example: "XII RPL 1"
 *               foto:
 *                 type: string
 *                 format: binary
 *     responses:
 *       201:
 *         description: User berhasil didaftarkan
 */
router.post("/register", upload.single("foto"), authController.register);


/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user dengan NIP dan Password
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nip:
 *                 type: string
 *                 example: "123456"
 *               password:
 *                 type: string
 *                 example: "password123"
 *     responses:
 *       200:
 *         description: Login berhasil dan mengembalikan token JWT serta info user
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Login berhasil"
 *                 token:
 *                   type: string
 *                   example: "eyJhbGciOiJIUzI1NiIsInR5..."
 *                 name:
 *                   type: string
 *                   example: "Muhammad Heriyanto"
 *                 role:
 *                   type: string
 *                   example: "supervisor"
 */
router.post("/login", authController.login);

/**
 * @swagger
 * /api/auth/update-password:
 *   put:
 *     summary: Perbarui password user berdasarkan NIP
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nip:
 *                 type: string
 *                 example: "123456"
 *               newPassword:
 *                 type: string
 *                 example: "passwordBaru123"
 *     responses:
 *       200:
 *         description: Password berhasil diperbarui
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       400:
 *         description: NIP atau password baru tidak diisi
 *       404:
 *         description: User tidak ditemukan
 */
router.put("/update-password", authController.updatePassword);


module.exports = router;
