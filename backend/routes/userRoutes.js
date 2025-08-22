const express = require("express");
const router = express.Router();
const userController = require("../controller/usercontroller");
const auth = require("../middleware/authMiddleware");
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
 *   name: User
 *   description: API untuk manajemen data user
 */

/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Ambil semua data user
 *     tags: [User]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Berhasil mendapatkan daftar user
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Daftar semua user
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                         example: 1
 *                       name:
 *                         type: string
 *                         example: "Budi Santoso"
 *                       nip:
 *                         type: string
 *                         example: "123456"
 *                       role:
 *                         type: string
 *                         example: "guru"
 *                       foto:
 *                         type: string
 *                         example: "profile1.png"
 *                       jurusan:
 *                         type: string
 *                         example: "Informatika"
 *                       kelas:
 *                         type: string
 *                         example: "XII-A"
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       updatedAt:
 *                         type: string
 *                         format: date-time
 */
router.get("/", auth, userController.getAllUsers);

/**
 * @swagger
 * /api/users/{id}:
 *   get:
 *     summary: Ambil data user berdasarkan ID
 *     tags: [User]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID user
 *     responses:
 *       200:
 *         description: Berhasil mendapatkan detail user
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Detail user
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     name:
 *                       type: string
 *                       example: "Budi Santoso"
 *                     nip:
 *                       type: string
 *                       example: "123456"
 *                     role:
 *                       type: string
 *                       example: "guru"
 *                     foto:
 *                       type: string
 *                       example: "profile1.png"
 *                     jurusan:
 *                       type: string
 *                       example: "Informatika"
 *                     kelas:
 *                       type: string
 *                       example: "XII-A"
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                     updatedAt:
 *                       type: string
 *                       format: date-time
 *       404:
 *         description: User tidak ditemukan
 */
router.get("/:id", auth, userController.getUserById);

/**
 * @swagger
 * /api/users/userRegister:
 *   post:
 *     summary: Tambah user baru (dengan upload foto)
 *     tags: [User]
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Muhammad Heriyanto"
 *               nip:
 *                 type: string
 *                 example: "123456"
 *               password:
 *                 type: string
 *                 example: "password123"
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
 *         description: User berhasil didaftarkan dengan role "siswa"
 */
router.post("/userRegister", upload.single("foto"), userController.userRegister);

/**
 * @swagger
 * /api/users/userUpdate/{id}:
 *   put:
 *     summary: Update data user berdasarkan ID (foto optional, role tidak diubah)
 *     tags: [User]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID user yang ingin diupdate
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Muhammad Heriyanto"
 *               nip:
 *                 type: string
 *                 example: "123456"
 *               password:
 *                 type: string
 *                 example: "newpassword123"
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
 *       200:
 *         description: User berhasil diperbarui
 *       404:
 *         description: User tidak ditemukan
 *       500:
 *         description: Terjadi error validasi atau server
 */
router.put("/userUpdate/:id", upload.single("foto"), userController.userUpdate);

/**
 * @swagger
 * /api/users/userDelete/{id}:
 *   delete:
 *     summary: Hapus user berdasarkan ID (hanya jika tidak ada task submissions terkait)
 *     tags: [User]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID user yang ingin dihapus
 *     responses:
 *       200:
 *         description: User berhasil dihapus
 *       400:
 *         description: User tidak bisa dihapus karena masih memiliki task submissions terkait
 *       404:
 *         description: User tidak ditemukan
 *       500:
 *         description: Terjadi error server
 */
router.delete("/userDelete/:id", userController.userDelete);



module.exports = router;
