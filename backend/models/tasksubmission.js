'use strict';
const { Model } = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class TaskSubmission extends Model {
    static associate(models) {
      // Relasi ke Tasks
      TaskSubmission.belongsTo(models.Task, {
        foreignKey: 'task_id',
        as: 'task'
      });

      // Relasi ke Users
      TaskSubmission.belongsTo(models.User, {
        foreignKey: 'user_id',
        as: 'user'
      });
    }
  }

  TaskSubmission.init({
    task_id: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    user_id: {
      type: DataTypes.INTEGER,
      allowNull: true
    },
    pdf_file: {               // ✅ tambahan untuk file tugas siswa
      type: DataTypes.STRING,
      allowNull: true
    },
    submitted_at: {           // ✅ tambahan untuk waktu submit
      type: DataTypes.DATE,
      allowNull: true
    },
    status: {
      type: DataTypes.ENUM('selesai', 'terlambat', 'tidak dikumpulkan'),
      allowNull: false,
      defaultValue: 'tidak dikumpulkan'
    }
  }, {
    sequelize,
    modelName: 'TaskSubmission',
    tableName: 'TaskSubmissions',   // biar match ke migration
  });

  return TaskSubmission;
};
