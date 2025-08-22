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
 * /api/tasks:
 *   post:
 *     summary: Tambah task baru
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *                 example: "Belajar Flutter"
 *               description:
 *                 type: string
 *                 example: "Kerjakan soal latihan"
 *               due_date:
 *                 type: string
 *                 format: date-time
 *                 example: "2025-08-20T10:00:00Z"
 *               pdf_file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       201:
 *         description: Task berhasil ditambahkan
 */
router.post("/", auth, upload.single("pdf_file"), taskController.createTask);

/**
 * @swagger
 * /api/tasks/{id}:
 *   put:
 *     summary: Update task berdasarkan ID
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID task yang akan diperbarui
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *                 example: "Belajar Flutter Advanced"
 *               description:
 *                 type: string
 *                 example: "Kerjakan soal latihan tambahan"
 *               due_date:
 *                 type: string
 *                 format: date-time
 *                 example: "2025-08-21T10:00:00Z"
 *               pdf_file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       200:
 *         description: Task berhasil diperbarui
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Task berhasil diperbarui
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     title:
 *                       type: string
 *                       example: Belajar Flutter Advanced
 *                     description:
 *                       type: string
 *                       example: Kerjakan soal latihan tambahan
 *                     due_date:
 *                       type: string
 *                       format: date-time
 *                       example: "2025-08-21T10:00:00Z"
 *                     completed:
 *                       type: string
 *                       format: date-time
 *                       example: "2025-08-20 15:30:00"
 *                     pdf_file:
 *                       type: string
 *                       example: "1755600285604.pdf"
 *                     created_by:
 *                       type: integer
 *                       example: 2
 *                 status_submission:
 *                   type: string
 *                   example: selesai
 */
router.put("/:id", auth, upload.single("pdf_file"), taskController.updateTask);

/**
 * @swagger
 * /api/tasks:
 *   get:
 *     summary: Ambil semua task beserta status submissions
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Data semua task berhasil diambil
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: Data semua task berhasil diambil
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: integer
 *                         example: 1
 *                       title:
 *                         type: string
 *                         example: Belajar Flutter
 *                       description:
 *                         type: string
 *                         example: Kerjakan soal latihan
 *                       due_date:
 *                         type: string
 *                         format: date-time
 *                         example: "2025-08-20T10:00:00Z"
 *                       completed:
 *                         type: string
 *                         format: date-time
 *                         nullable: true
 *                         example: null
 *                       pdf_file:
 *                         type: string
 *                         example: "1755600285604.pdf"
 *                       created_by:
 *                         type: integer
 *                         example: 2
 *                       submissions:
 *                         type: array
 *                         items:
 *                           type: object
 *                           properties:
 *                             id:
 *                               type: integer
 *                               example: 1
 *                             status:
 *                               type: string
 *                               example: tidak dikumpulkan
 *                             user_id:
 *                               type: integer
 *                               example: 2
 *                             user:
 *                               type: object
 *                               properties:
 *                                 id:
 *                                   type: integer
 *                                   example: 2
 *                                 name:
 *                                   type: string
 *                                   example: Budi
 *                                 nip:
 *                                   type: string
 *                                   example: "123456"
 *                                 role:
 *                                   type: string
 *                                   example: guru
 */
router.get("/", auth, taskController.getAllTasks);


/**
 * @swagger
 * components:
 *   schemas:
 *     TaskSummary:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           description: ID unik task
 *           example: 11
 *         title:
 *           type: string
 *           description: Judul task
 *           example: "Tugas Puisi"
 *         description:
 *           type: string
 *           description: Deskripsi task
 *           example: "Buat puisi individu"
 *         due_date:
 *           type: string
 *           format: date-time
 *           description: Deadline task
 *           example: "2025-08-20T17:00:00.000Z"
 *         completed:
 *           type: boolean
 *           nullable: true
 *           description: Status completion task
 *           example: null
 *         pdf_file:
 *           type: string
 *           nullable: true
 *           description: File PDF task
 *           example: "1755757012086.pdf"
 *         created_at:
 *           type: string
 *           format: date-time
 *           description: Tanggal dibuat
 *           example: "2025-08-21T06:16:52.000Z"
 *         updated_at:
 *           type: string
 *           format: date-time
 *           description: Tanggal diupdate
 *           example: "2025-08-21T06:16:52.000Z"
 *         creator:
 *           $ref: '#/components/schemas/User'
 *         total_students:
 *           type: integer
 *           description: Total siswa yang mengerjakan
 *           example: 25
 *         total_submissions:
 *           type: integer
 *           description: Total submissions yang masuk
 *           example: 15
 *         submitted_count:
 *           type: integer
 *           description: Jumlah yang sudah submit
 *           example: 12
 *         pending_count:
 *           type: integer
 *           description: Jumlah yang masih pending
 *           example: 3
 *         status_summary:
 *           type: object
 *           properties:
 *             on_time:
 *               type: integer
 *               description: Submissions tepat waktu
 *               example: 10
 *             late:
 *               type: integer
 *               description: Submissions terlambat
 *               example: 2
 *             not_submitted:
 *               type: integer
 *               description: Belum submit
 *               example: 10
 *             pending:
 *               type: integer
 *               description: Status pending
 *               example: 3
 *         completion_percentage:
 *           type: integer
 *           description: Persentase completion
 *           example: 60
 *         latest_submission:
 *           type: object
 *           nullable: true
 *           description: Info submission terbaru
 *     
 *     User:
 *       type: object
 *       properties:
 *         id:
 *           type: integer
 *           example: 1
 *         name:
 *           type: string
 *           example: "Guru Satu"
 *         nip:
 *           type: string
 *           example: "123456"
 *         role:
 *           type: string
 *           example: "guru"
 *         jurusan:
 *           type: string
 *           example: "Teknik Informatika"
 *         kelas:
 *           type: string
 *           nullable: true
 *           example: null
 *     
 *     TasksGuruResponse:
 *       type: object
 *       properties:
 *         message:
 *           type: string
 *           example: "Daftar tasks berhasil diambil"
 *         data:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/TaskSummary'
 *         total:
 *           type: integer
 *           description: Total tasks
 *           example: 5
 *         summary:
 *           type: object
 *           properties:
 *             total_tasks:
 *               type: integer
 *               example: 5
 *             active_tasks:
 *               type: integer
 *               example: 3
 *             completed_tasks:
 *               type: integer
 *               example: 2
 *     
 *     ErrorResponse:
 *       type: object
 *       properties:
 *         message:
 *           type: string
 *           example: "Error message"
 *         error:
 *           type: string
 *           example: "ERROR_CODE"
 *         debug:
 *           type: string
 *           description: Debug info (development only)
 *           example: "Detailed error message"
 */

/**
 * @swagger
 * /api/tasks/guru:
 *   get:
 *     tags:
 *       - Tasks
 *     summary: Get all tasks created by logged-in teacher
 *     description: Mengambil semua tasks yang dibuat oleh guru yang sedang login, beserta statistik submissions dari siswa
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Daftar tasks berhasil diambil
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/TasksGuruResponse'
 *             example:
 *               message: "Daftar tasks berhasil diambil"
 *               data:
 *                 - id: 11
 *                   title: "Tugas Puisi"
 *                   description: "Buat puisi individu"
 *                   due_date: "2025-08-20T17:00:00.000Z"
 *                   completed: null
 *                   pdf_file: "1755757012086.pdf"
 *                   created_at: "2025-08-21T06:16:52.000Z"
 *                   updated_at: "2025-08-21T06:16:52.000Z"
 *                   creator:
 *                     id: 1
 *                     name: "Guru Satu"
 *                     nip: "123456"
 *                     role: "guru"
 *                     jurusan: "Teknik Informatika"
 *                     kelas: null
 *                   total_students: 25
 *                   total_submissions: 15
 *                   submitted_count: 12
 *                   pending_count: 3
 *                   status_summary:
 *                     on_time: 10
 *                     late: 2
 *                     not_submitted: 10
 *                     pending: 3
 *                   completion_percentage: 60
 *                   latest_submission:
 *                     id: 10
 *                     status: "terlambat"
 *                     submitted_at: "2025-08-21T07:48:17.000Z"
 *               total: 5
 *               summary:
 *                 total_tasks: 5
 *                 active_tasks: 3
 *                 completed_tasks: 2
 *       401:
 *         description: Unauthorized - Token tidak valid atau tidak ada
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             example:
 *               message: "Token tidak valid"
 *               error: "UNAUTHORIZED"
 *       403:
 *         description: Forbidden - Hanya guru yang dapat mengakses
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             example:
 *               message: "Akses ditolak. Hanya guru yang dapat mengakses endpoint ini"
 *               error: "FORBIDDEN"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *             example:
 *               message: "Terjadi kesalahan server"
 *               error: "INTERNAL_SERVER_ERROR"
 */

// Route untuk mengambil semua tasks milik guru yang login
router.get('/guru', auth, taskController.getTasksForGuru);


/**
 * @swagger
 * /api/tasks/{id}:
 *   get:
 *     summary: Ambil detail task berdasarkan ID
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID task
 *     responses:
 *       200:
 *         description: Detail task berhasil diambil
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                     title:
 *                       type: string
 *                     description:
 *                       type: string
 *                     due_date:
 *                       type: string
 *                       format: date-time
 *                     completed:
 *                       type: string
 *                       format: date-time
 *                     pdf_file:
 *                       type: string
 *                     creator:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: integer
 *                         name:
 *                           type: string
 *                         nip:
 *                           type: string
 *                         role:
 *                           type: string
 *                     submissions:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: integer
 *                           status:
 *                             type: string
 *                           user:
 *                             type: object
 *                             properties:
 *                               id:
 *                                 type: integer
 *                               name:
 *                                 type: string
 *                               nip:
 *                                 type: string
 *                               role:
 *                                 type: string
 *       404:
 *         description: Task tidak ditemukan
 */
router.get("/:id", auth, taskController.getTaskById);

/**
 * @swagger
 * /api/tasks/{id}:
 *   delete:
 *     summary: Hapus task berdasarkan ID
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID task yang akan dihapus
 *     responses:
 *       200:
 *         description: Task dan submissions terkait berhasil dihapus
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *       404:
 *         description: Task tidak ditemukan
 */
router.delete("/:id", auth, taskController.deleteTask);

/**
 * @swagger
 * /api/tasks/{id}/download:
 *   get:
 *     summary: Download file PDF dari task berdasarkan ID
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID task yang memiliki file PDF
 *     responses:
 *       200:
 *         description: File PDF berhasil diunduh
 *         content:
 *           application/pdf:
 *             schema:
 *               type: string
 *               format: binary
 *       404:
 *         description: Task atau file tidak ditemukan
 */
router.get("/:id/download", auth, taskController.downloadTaskPdf);

/**
 * @swagger
 * /api/tasks/{id}/user:
 *   get:
 *     summary: Get task detail with role-based filtering
 *     description: |
 *       Mengambil detail task berdasarkan role user yang login:
 *       - **Guru**: Melihat semua submissions dari semua siswa untuk task tersebut
 *       - **Siswa**: Hanya melihat submission miliknya sendiri untuk task tersebut
 *     tags: [Tasks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: ID dari task yang ingin dilihat
 *         example: 1
 *     responses:
 *       200:
 *         description: Detail task berhasil diambil
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Detail task berhasil diambil"
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: integer
 *                       example: 1
 *                     title:
 *                       type: string
 *                       example: "Tugas Matematika Bab 1"
 *                     description:
 *                       type: string
 *                       example: "Kerjakan soal-soal pada bab 1"
 *                     due_date:
 *                       type: string
 *                       format: date-time
 *                       example: "2024-12-31T23:59:59.000Z"
 *                     target_jurusan:
 *                       type: string
 *                       example: "Teknik Informatika"
 *                     target_kelas:
 *                       type: string
 *                       example: "XII-A"
 *                     created_by:
 *                       type: integer
 *                       example: 2
 *                     created_at:
 *                       type: string
 *                       format: date-time
 *                     updated_at:
 *                       type: string
 *                       format: date-time
 *                     submissions:
 *                       type: array
 *                       description: "Array submissions (guru: semua submissions, siswa: submission sendiri)"
 *                       items:
 *                         type: object
 *                         properties:
 *                           id:
 *                             type: integer
 *                             example: 1
 *                           task_id:
 *                             type: integer
 *                             example: 1
 *                           user_id:
 *                             type: integer
 *                             example: 3
 *                           status:
 *                             type: string
 *                             enum: [pending, submitted]
 *                             example: "submitted"
 *                           pdf_file:
 *                             type: string
 *                             example: "submission_12345.pdf"
 *                           submitted_at:
 *                             type: string
 *                             format: date-time
 *                             example: "2024-08-20T10:30:00.000Z"
 *                           user:
 *                             type: object
 *                             properties:
 *                               id:
 *                                 type: integer
 *                                 example: 3
 *                               name:
 *                                 type: string
 *                                 example: "John Doe"
 *                               nip:
 *                                 type: string
 *                                 example: "123456789"
 *                               role:
 *                                 type: string
 *                                 example: "siswa"
 *                               jurusan:
 *                                 type: string
 *                                 example: "Teknik Informatika"
 *                                 description: "Hanya tampil untuk guru"
 *                               kelas:
 *                                 type: string
 *                                 example: "XII-A"
 *                                 description: "Hanya tampil untuk guru"
 *                     creator:
 *                       type: object
 *                       properties:
 *                         id:
 *                           type: integer
 *                           example: 2
 *                         name:
 *                           type: string
 *                           example: "Jane Smith"
 *                         nip:
 *                           type: string
 *                           example: "987654321"
 *                         role:
 *                           type: string
 *                           example: "guru"
 *                     # Response khusus untuk GURU
 *                     total_submissions:
 *                       type: integer
 *                       description: "Total submissions (hanya untuk guru)"
 *                       example: 5
 *                     submission_summary:
 *                       type: object
 *                       description: "Summary submissions (hanya untuk guru)"
 *                       properties:
 *                         total:
 *                           type: integer
 *                           example: 5
 *                         submitted:
 *                           type: integer
 *                           example: 3
 *                         pending:
 *                           type: integer
 *                           example: 2
 *                     # Response khusus untuk SISWA
 *                     user_submission_status:
 *                       type: string
 *                       enum: [not_submitted, pending, submitted]
 *                       description: "Status submission user (hanya untuk siswa)"
 *                       example: "submitted"
 *                     user_has_submitted:
 *                       type: boolean
 *                       description: "Apakah user sudah submit (hanya untuk siswa)"
 *                       example: true
 *                     user_submission:
 *                       type: object
 *                       nullable: true
 *                       description: "Detail submission user (hanya untuk siswa)"
 *                       properties:
 *                         id:
 *                           type: integer
 *                         status:
 *                           type: string
 *                         pdf_file:
 *                           type: string
 *                         submitted_at:
 *                           type: string
 *                           format: date-time
 *       403:
 *         description: Tidak memiliki akses ke task ini
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Anda tidak memiliki akses untuk melihat task ini"
 *       404:
 *         description: Task tidak ditemukan
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Task tidak ditemukan"
 *       401:
 *         description: Token tidak valid atau tidak ada
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Token tidak valid"
 *       500:
 *         description: Server error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Internal server error"
 */
router.get("/:id/user", auth, taskController.getTaskByIdForUser);


module.exports = router;
