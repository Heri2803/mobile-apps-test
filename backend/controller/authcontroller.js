const { User } = require("../models");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

// REGISTER USER
exports.register = async (req, res) => {
  try {
    const { name, nip, password, role, jurusan, kelas } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    const foto = req.file ? req.file.filename : null; // ambil nama file

    const user = await User.create({
      name,
      nip,
      password: hashedPassword,
      role,
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


// LOGIN USER
exports.login = async (req, res) => {
  try {
    const { nip, password } = req.body;

    const user = await User.findOne({ where: { nip } });
    if (!user) {
      return res.status(404).json({ message: "User tidak ditemukan" });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ message: "Password salah" });
    }

    // generate token JWT
    const token = jwt.sign(
      { id: user.id, nip: user.nip, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    res.json({
      message: "Login berhasil",
      name: user.name,   // ✅ tambahkan
      role: user.role,    // ✅ tambahkan
      token
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// UPDATE PASSWORD by NIP
exports.updatePassword = async (req, res) => {
  try {
    const { nip, newPassword } = req.body;

    // cek apakah nip dan newPassword diisi
    if (!nip || !newPassword) {
      return res.status(400).json({ message: "NIP dan password baru wajib diisi" });
    }

    // cari user berdasarkan nip
    const user = await User.findOne({ where: { nip } });

    if (!user) {
      return res.status(404).json({ message: "User dengan NIP tersebut tidak ditemukan" });
    }

    // hash password baru
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // update password user
    user.password = hashedPassword;
    await user.save();

    res.status(200).json({
      message: "Password berhasil diperbarui"
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

