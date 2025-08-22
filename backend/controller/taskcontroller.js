const { Task, TaskSubmission, User } = require("../models");
const moment = require("moment-timezone");
const fs = require("fs");
const path = require("path");


// Fungsi untuk membuat task baru
exports.createTask = async (req, res) => {
  try {
    // pastikan hanya role guru yang bisa membuat task
    if (req.user.role !== "guru") {
      return res.status(403).json({ message: "Hanya guru yang dapat menambahkan task" });
    }

    const { title, description, due_date } = req.body;
    const pdf_file = req.file ? req.file.filename : null;

    // Buat Task baru
    const task = await Task.create({
      title,
      description,
      due_date,
      completed: null,
      pdf_file,
      created_by: req.user.id
    });

    // Ambil semua siswa
    const students = await User.findAll({
      where: { role: 'siswa' }
    });

    // Buat TaskSubmission untuk setiap siswa
    const submissionPromises = students.map(student => 
      TaskSubmission.create({
        task_id: task.id,
        user_id: student.id,
        status: "tidak dikumpulkan"
      })
    );

    await Promise.all(submissionPromises);

    res.status(201).json({
      message: `Task berhasil ditambahkan dengan ${students.length} submissions untuk siswa`,
      data: task
    });
  } catch (error) {
    console.error('Error creating task:', error);
    res.status(500).json({ message: error.message });
  }
};

// Fungsi untuk memperbarui task
exports.updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, due_date } = req.body;
    const newPdfFile = req.file ? req.file.filename : null;

    // Cari task berdasarkan id
    const task = await Task.findByPk(id);
    if (!task) {
      return res.status(404).json({ message: "Task tidak ditemukan" });
    }

    // update kolom teks
    task.title = title || task.title;
    task.description = description || task.description;
    task.due_date = due_date || task.due_date;

    // jika ada pdf baru
    if (newPdfFile) {
      // hapus pdf lama jika ada
      if (task.pdf_file) {
        const oldPath = path.join(__dirname, "../uploads", task.pdf_file);
        if (fs.existsSync(oldPath)) {
          fs.unlinkSync(oldPath);
        }
      }
      // simpan nama file baru
      task.pdf_file = newPdfFile;
    }

    // set completed ke waktu sekarang (WIB)
    const now = moment().tz("Asia/Jakarta").format("YYYY-MM-DD HH:mm:ss");
    task.completed = now;

    await task.save();

    // cek status submissions
    let status = "selesai";
    if (moment(now).isAfter(moment(task.due_date))) {
      status = "terlambat";
    }

    await TaskSubmission.update(
      { status },
      { where: { task_id: task.id } }
    );

    res.status(200).json({
      message: "Task berhasil diperbarui",
      data: task,
      status_submission: status
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Fungsi untuk mengirimkan tugas (TaskSubmission)
exports.updateSubmission = async (req, res) => {
  try {
    const { id } = req.params; // ini sekarang adalah task_id
    const userId = req.user ? req.user.id : null;
    
    console.log('=== UPDATE SUBMISSION DEBUG ===');
    console.log('Requested Task ID:', id);
    console.log('User ID from JWT:', userId);
    console.log('Request method:', req.method);
    console.log('Request URL:', req.url);

    // Cek apakah ada data sama sekali di tabel
    const allSubmissions = await TaskSubmission.findAll();
    console.log('Total submissions in database:', allSubmissions.length);
    console.log('All submission task_ids:', allSubmissions.map(s => ({ id: s.id, task_id: s.task_id, user_id: s.user_id })));

    // Cari submission berdasarkan task_id DAN user_id (untuk security)
    const submission = await TaskSubmission.findOne({
      where: { 
        task_id: id,      // mencari berdasarkan task_id
        user_id: userId   // pastikan milik user yang login
      },
      include: [{ model: Task, as: "task" }]
    });

    console.log('Found submission:', submission ? 'YES' : 'NO');
    
    if (submission) {
      console.log('Submission details:', {
        id: submission.id,
        task_id: submission.task_id,
        user_id: submission.user_id,
        status: submission.status
      });
    }

    if (!submission) {
      console.log('=== SUBMISSION NOT FOUND ===');
      console.log(`No submission found for task_id: ${id} and user_id: ${userId}`);
      return res.status(404).json({ message: "Submission tidak ditemukan" });
    }

    // Sisa kode tetap sama...
    const newPdfFile = req.file ? req.file.filename : null;

    if (newPdfFile) {
      if (submission.pdf_file) {
        const oldPath = path.join(__dirname, "../uploads", submission.pdf_file);
        if (fs.existsSync(oldPath)) {
          fs.unlinkSync(oldPath);
        }
      }
      submission.pdf_file = newPdfFile;
    }

    const now = moment().tz("Asia/Jakarta").format("YYYY-MM-DD HH:mm:ss");
    submission.submitted_at = now;

    let status = "selesai";
    if (moment(now).isAfter(moment(submission.task.due_date))) {
      status = "terlambat";
    }
    submission.status = status;

    await submission.save();

    console.log('=== SUBMISSION UPDATED SUCCESSFULLY ===');
    res.status(200).json({
      message: "Submission berhasil diperbarui",
      data: submission
    });

  } catch (error) {
    console.error('=== ERROR IN UPDATE SUBMISSION ===');
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({ message: error.message });
  }
};

// Fungsi untuk mengambil semua task
exports.getAllTasks = async (req, res) => {
  try {
    const tasks = await Task.findAll({
      include: [
        {
          model: TaskSubmission,
          as: "submissions",
          attributes: ["id", "status", "user_id"],
          include: [
            {
              model: User,
              as: "user",
              attributes: ["id", "name", "nip", "role"]
            }
          ]
        }
      ],
      order: [["createdAt", "DESC"]]
    });

    res.status(200).json({
      message: "Data semua task berhasil diambil",
      data: tasks
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Fungsi untuk mengambil detail task berdasarkan ID
exports.getTaskById = async (req, res) => {
  try {
    const { id } = req.params;

    const task = await Task.findByPk(id, {
      include: [
        {
          model: TaskSubmission,
          as: "submissions",
          attributes: ["id", "status", "user_id"],
          include: [
            {
              model: User,
              as: "user",
              attributes: ["id", "name", "nip", "role"]
            }
          ]
        },
        {
          model: User,
          as: "creator",
          attributes: ["id", "name", "nip", "role"]
        }
      ]
    });

    if (!task) {
      return res.status(404).json({ message: "Task tidak ditemukan" });
    }

    res.status(200).json({
      message: "Detail task berhasil diambil",
      data: task
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Fungsi untuk menghapus task
exports.deleteTask = async (req, res) => {
  try {
    const { id } = req.params;

    // Cari task berdasarkan id
    const task = await Task.findByPk(id);

    if (!task) {
      return res.status(404).json({ message: "Task tidak ditemukan" });
    }

    // Hapus semua submissions terkait
    await TaskSubmission.destroy({
      where: { task_id: id }
    });

    // Hapus file pdf dari folder uploads jika ada
    if (task.pdf_file) {
      const filePath = path.join(__dirname, "..", "uploads", task.pdf_file);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        console.log(`File ${task.pdf_file} berhasil dihapus dari uploads`);
      }
    }

    // Hapus task
    await task.destroy();

    res.status(200).json({
      message: "Task dan submissions terkait berhasil dihapus"
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// DOWNLOAD PDF FILE
exports.downloadTaskPdf = async (req, res) => {
  try {
    const { id } = req.params;

    // Cari task berdasarkan ID
    const task = await Task.findByPk(id);

    if (!task) {
      return res.status(404).json({ message: "Task tidak ditemukan" });
    }

    if (!task.pdf_file) {
      return res.status(404).json({ message: "File PDF tidak tersedia untuk task ini" });
    }

    // Path file di folder uploads
    const filePath = path.join(__dirname, "..", "uploads", task.pdf_file);

    // Cek apakah file ada di folder
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ message: "File PDF tidak ditemukan di server" });
    }

    // Download file
    res.download(filePath, task.pdf_file, (err) => {
      if (err) {
        console.error("Error saat mengunduh file:", err);
        res.status(500).json({ message: "Gagal mengunduh file PDF" });
      }
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Controller baru untuk mendapatkan task berdasarkan ID dengan filter user login
exports.getTaskByIdForUser = async (req, res) => {
  try {
    const { Task, TaskSubmission, User } = require("../models");
    
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;
    const userJurusan = req.user.jurusan;
    const userKelas = req.user.kelas;
    
    // DEBUG: Log semua parameter
    console.log("=== DEBUG INFO ===");
    console.log("Task ID from params:", id);
    console.log("User ID from token:", userId);
    console.log("User Role:", userRole);
    console.log("User Jurusan:", userJurusan);
    console.log("User Kelas:", userKelas);
    
    // STEP 1: Cek apakah task dengan ID tersebut ada di database
    const taskExists = await Task.findByPk(id);
    console.log("Task exists?", taskExists ? "YES" : "NO");
    
    if (taskExists) {
      console.log("Task found:", {
        id: taskExists.id,
        title: taskExists.title,
        // Hapus referensi jurusan dan kelas jika tidak ada di database
        created_by: taskExists.created_by
      });
    } else {
      console.log("Task with ID", id, "not found in database");
      
      // DEBUG: Tampilkan semua tasks yang ada (tanpa kolom jurusan dan kelas)
      const allTasks = await Task.findAll({
        attributes: ["id", "title", "description"] // Gunakan kolom yang ada
      });
      console.log("Available tasks:", allTasks.map(t => ({
        id: t.id,
        title: t.title,
        description: t.description
      })));
      
      return res.status(404).json({ 
        message: "Task tidak ditemukan",
        debug: {
          requested_id: id,
          available_tasks: allTasks.map(t => t.id)
        }
      });
    }
    
    // STEP 2: Ambil data lengkap user yang login
    const currentUser = await User.findByPk(userId, {
      attributes: ["id", "name", "nip", "role", "jurusan", "kelas"]
    });
    
    console.log("Current user:", currentUser ? currentUser.toJSON() : "NOT FOUND");
    
    if (!currentUser) {
      return res.status(401).json({ message: "User tidak valid" });
    }
    
    let task;
    
    if (userRole === 'guru') {
      console.log("Processing as GURU...");
      
      task = await Task.findByPk(id, {
        include: [
          {
            model: TaskSubmission,
            as: "submissions",
            attributes: ["id", "task_id", "user_id", "status", "pdf_file", "submitted_at"],
            required: false, // LEFT JOIN
            include: [
              {
                model: User,
                as: "user",
                attributes: ["id", "name", "nip", "role", "jurusan", "kelas"]
              }
            ]
          },
          {
            model: User,
            as: "creator",
            attributes: ["id", "name", "nip", "role", "jurusan", "kelas"]
          }
        ]
      });
      
      if (!task) {
        return res.status(404).json({ message: "Task tidak ditemukan dengan include" });
      }
      
      console.log("Task with includes found for GURU");
      
      // Sederhanakan akses kontrol untuk guru - hanya cek apakah dia yang membuat task
      const hasAccess = (task.created_by === userId);
      
      console.log("Access check for GURU:", {
        created_by: task.created_by,
        userId: userId,
        hasAccess: hasAccess
      });
      
      if (!hasAccess) {
        return res.status(403).json({ 
          message: "Anda tidak memiliki akses untuk melihat task ini",
          debug: {
            created_by: task.created_by,
            userId: userId
          }
        });
      }
      
      const responseData = {
        ...task.toJSON(),
        current_user: currentUser,
        total_submissions: task.submissions ? task.submissions.length : 0,
        submission_summary: task.submissions ? {
          total: task.submissions.length,
          submitted: task.submissions.filter(sub => sub.status === 'submitted').length,
          pending: task.submissions.filter(sub => sub.status === 'pending').length
        } : { total: 0, submitted: 0, pending: 0 }
      };
      
      return res.status(200).json({
        message: "Detail task berhasil diambil",
        data: responseData
      });
      
    } else if (userRole === 'siswa') {
      console.log("Processing as SISWA...");
      
      task = await Task.findByPk(id, {
        include: [
          {
            model: TaskSubmission,
            as: "submissions",
            attributes: ["id", "task_id", "user_id", "status", "pdf_file", "submitted_at"],
            where: { user_id: userId },
            required: false, // LEFT JOIN
            include: [
              {
                model: User,
                as: "user",
                attributes: ["id", "name", "nip", "role", "jurusan", "kelas"]
              }
            ]
          },
          {
            model: User,
            as: "creator",
            attributes: ["id", "name", "nip", "role", "jurusan", "kelas"]
          }
        ]
      });
      
      if (!task) {
        return res.status(404).json({ message: "Task tidak ditemukan dengan include untuk siswa" });
      }
      
      console.log("Task with includes found for SISWA");
      
      // Sederhanakan akses kontrol untuk siswa - untuk sementara izinkan semua siswa mengakses
      // Atau Anda bisa menambahkan logika lain sesuai kebutuhan
      console.log("Access granted for SISWA - all students can access tasks");
      
      const responseData = {
        ...task.toJSON(),
        current_user: currentUser,
        user_submission_status: task.submissions && task.submissions.length > 0 ? task.submissions[0].status : 'not_submitted',
        user_has_submitted: task.submissions && task.submissions.length > 0,
        user_submission: task.submissions && task.submissions.length > 0 ? task.submissions[0] : null
      };
      
      return res.status(200).json({
        message: "Detail task berhasil diambil",
        data: responseData
      });
      
    } else {
      return res.status(403).json({ message: "Role tidak dikenali" });
    }

  } catch (error) {
    console.error('Error in getTaskByIdForUser:', error);
    res.status(500).json({ 
      message: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Fungsi untuk mendapatkan daftar task yang dibuat oleh guru
exports.getTasksForGuru = async (req, res) => {
  try {
    
    const userId = req.user.id;
    const userRole = req.user.role;
    
    // DEBUG: Log info
    console.log("=== GET TASKS FOR GURU ===");
    console.log("User ID:", userId);
    console.log("User Role:", userRole);
    
    // Validasi role - hanya guru yang bisa mengakses
    if (userRole !== 'guru') {
      return res.status(403).json({ 
        message: "Akses ditolak. Hanya guru yang dapat mengakses endpoint ini",
        error: "FORBIDDEN"
      });
    }
    
    // Ambil semua tasks yang dibuat oleh guru ini
    const tasks = await Task.findAll({
      where: { created_by: userId },
      include: [
        {
          model: TaskSubmission,
          as: "submissions",
          attributes: ["id", "status", "submitted_at"],
          required: false, // LEFT JOIN untuk tetap tampil meski belum ada submission
          include: [
            {
              model: User,
              as: "user",
              attributes: ["id", "name", "nip", "role", "jurusan", "kelas"]
            }
          ]
        },
        {
          model: User,
          as: "creator",
          attributes: ["id", "name", "nip", "role", "jurusan", "kelas"]
        }
      ],
      order: [['createdAt', 'DESC']] // Urutkan berdasarkan yang terbaru
    });
    
    console.log(`Found ${tasks.length} tasks for guru ID: ${userId}`);
    
    // Transform data untuk response yang lebih informatif
    const transformedTasks = tasks.map(task => {
      const submissions = task.submissions || [];
      
      // Hitung statistik submissions berdasarkan status: selesai, terlambat, tidak dikumpulkan
      const totalSubmissions = submissions.length;
      const selesaiCount = submissions.filter(sub => sub.status === 'selesai').length;
      const terlambatCount = submissions.filter(sub => sub.status === 'terlambat').length;
      
      // Hitung total siswa yang seharusnya submit (bisa disesuaikan dengan logika bisnis)
      // Untuk sementara, kita asumsikan total siswa = total submissions + yang belum submit
      // Atau bisa diambil dari jumlah siswa di kelas yang sama
      const totalStudents = totalSubmissions; // Sesuaikan dengan kebutuhan
      const tidakDikumpulkanCount = totalStudents - selesaiCount - terlambatCount;
      
      return {
        id: task.id,
        title: task.title,
        description: task.description,
        due_date: task.due_date,
        completed: task.completed,
        pdf_file: task.pdf_file,
        created_at: task.createdAt,
        updated_at: task.updatedAt,
        creator: task.creator,
        
        // Statistik submissions
        total_students: totalStudents,
        total_submissions: totalSubmissions,
        selesai_count: selesaiCount,
        terlambat_count: terlambatCount,
        
        // Status breakdown
        status_summary: {
          selesai: selesaiCount,
          terlambat: terlambatCount,
          tidak_dikumpulkan: tidakDikumpulkanCount
        },
        
        // Progress percentage
        completion_percentage: totalStudents > 0 ? Math.round(((selesaiCount + terlambatCount) / totalStudents) * 100) : 0,
        
        // Latest submission info
        latest_submission: submissions.length > 0 ? submissions.reduce((latest, current) => {
          return new Date(current.submitted_at) > new Date(latest.submitted_at) ? current : latest;
        }) : null
      };
    });
    
    // Response sukses
    return res.status(200).json({
      message: "Daftar tasks berhasil diambil",
      data: transformedTasks,
      total: transformedTasks.length,
      summary: {
        total_tasks: transformedTasks.length,
        active_tasks: transformedTasks.filter(task => !task.completed).length,
        completed_tasks: transformedTasks.filter(task => task.completed).length
      }
    });
    
  } catch (error) {
    console.error('Error in getTasksForGuru:', error);
    return res.status(500).json({ 
      message: "Terjadi kesalahan server",
      error: "INTERNAL_SERVER_ERROR",
      debug: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};


