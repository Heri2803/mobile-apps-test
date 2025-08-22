'use strict';
const { Model } = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Task extends Model {
    static associate(models) {
      // Relasi Task -> User (pembuat task)
      Task.belongsTo(models.User, { 
        foreignKey: 'created_by',
        as: 'creator'
      });

      // Relasi Task -> TaskSubmission (1 task bisa banyak submissions)
      Task.hasMany(models.TaskSubmission, {
        foreignKey: 'task_id',
        as: 'submissions'
      });
    }
  }
  Task.init({
    title: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true
    },
    due_date: {
      type: DataTypes.DATE,   // datetime
      allowNull: true
    },
    completed: {
      type: DataTypes.DATE,   // datetime kapan selesai
      allowNull: true
    },
    pdf_file: {
      type: DataTypes.STRING,
      allowNull: true
    },
    created_by: {
      type: DataTypes.INTEGER,
      allowNull: false
    }
  }, {
    sequelize,
    modelName: 'Task',
  });
  return Task;
};
