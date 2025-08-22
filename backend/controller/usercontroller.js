const { User, TaskSubmission } = require("../models");
const bcrypt = require("bcrypt");
const fs = require("fs");
const path = require("path");

// GET all users
exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.findAll({
      attributes: { exclude: ["password"] } // jangan tampilkan password
    });

    res.status(200).json({
      message: "Daftar semua user",
      data: users,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// GET user by ID
exports.getUserById = async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findByPk(id, {
      attributes: { exclude: ["password"] } // jangan tampilkan password
    });

    if (!user) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    res.status(200).json({
      message: "Detail user",
      data: user,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


// Register user with photo upload
exports.userRegister = async (req, res) => {
  try {
    const { name, nip, password, jurusan, kelas } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    const foto = req.file ? req.file.filename : null; // ambil nama file

    const user = await User.create({
      name,
      nip,
      password: hashedPassword,
      role: "siswa",
      foto,
      jurusan,
      kelas
    });

    res.status(201).json({
      message: "User berhasil didaftarkan",
      data: user
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


// Update user by ID
exports.userUpdate = async (req, res) => {
  try {
    const { id } = req.params; // ambil id user dari URL parameter
    const { name, nip, password, jurusan, kelas } = req.body;

    // Cari user berdasarkan id
    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    // Hash password jika ada perubahan
    let hashedPassword = user.password; // default tetap password lama
    if (password) {
      hashedPassword = await bcrypt.hash(password, 10);
    }

    // Ambil foto jika ada
    const foto = req.file ? req.file.filename : user.foto; // jika tidak ada, tetap foto lama

    // Update user
    await user.update({
      name: name || user.name,
      nip: nip || user.nip,
      password: hashedPassword,
      foto,
      jurusan: jurusan || user.jurusan,
      kelas: kelas || user.kelas
    });

    res.status(200).json({
      message: "User berhasil diperbarui",
      data: user
    });
  } catch (error) {
    console.error(error);
    if (error.errors) {
      return res.status(500).json({ 
        message: "Validation error", 
        details: error.errors.map(e => ({ field: e.path, error: e.message })) 
      });
    }
    res.status(500).json({ message: error.message });
  }
};

// Delete user by ID
exports.userDelete = async (req, res) => {
  try {
    const { id } = req.params;

    // Cari user berdasarkan id
    const user = await User.findByPk(id);
    if (!user) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    // Cek apakah ada task submissions terkait
    const submissions = await TaskSubmission.findAll({ where: { user_id: id } });
    if (submissions.length > 0) {
      return res.status(400).json({ 
        message: "User tidak bisa dihapus karena masih memiliki task submissions terkait" 
      });
    }

    // Hapus record user
    await user.destroy();

    // Hapus file foto jika ada
    if (user.foto) {
      const fotoPath = path.join(__dirname, "..", "uploadFoto", user.foto);
      fs.unlink(fotoPath, (err) => {
        if (err) console.error("Gagal hapus file foto:", err.message);
      });
    }

    res.status(200).json({ message: "User berhasil dihapus" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message });
  }
};