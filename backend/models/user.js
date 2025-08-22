module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define("User", {
    name: {
      type: DataTypes.STRING,
      allowNull: false
    },
    nip: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false
    },
    role: {
      type: DataTypes.ENUM("siswa", "guru"),
      allowNull: false
    },
    foto: {
      type: DataTypes.STRING,  // simpan path/url foto
      allowNull: true
    },
    jurusan: {
      type: DataTypes.STRING,
      allowNull: true
    },
    kelas: {
      type: DataTypes.STRING,
      allowNull: true
    }
  });
  return User;
};
