'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    // Ubah kolom user_id agar bisa NULL
    await queryInterface.changeColumn('TaskSubmissions', 'user_id', {
      type: Sequelize.INTEGER,
      allowNull: true,   // ubah ke true (boleh kosong)
      references: {
        model: 'Users',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    });
  },

  async down(queryInterface, Sequelize) {
    // Balik lagi ke kondisi sebelumnya (tidak boleh null)
    await queryInterface.changeColumn('TaskSubmissions', 'user_id', {
      type: Sequelize.INTEGER,
      allowNull: false,   // balik ke kondisi awal
      references: {
        model: 'Users',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'CASCADE'
    });
  }
};
