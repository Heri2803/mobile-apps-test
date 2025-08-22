'use strict';
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('TaskSubmissions', 'pdf_file', {
      type: Sequelize.STRING,
      allowNull: true
    });
    await queryInterface.addColumn('TaskSubmissions', 'submitted_at', {
      type: Sequelize.DATE,
      allowNull: true
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('TaskSubmissions', 'pdf_file');
    await queryInterface.removeColumn('TaskSubmissions', 'submitted_at');
  }
};
