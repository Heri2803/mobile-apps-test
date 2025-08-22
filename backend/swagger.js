const swaggerJsDoc = require("swagger-jsdoc");
const swaggerUi = require("swagger-ui-express");

// Konfigurasi Swagger
const swaggerOptions = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Task Manager API",
      version: "1.0.0",
      description: "Dokumentasi API untuk aplikasi manajemen tugas"
    },
    servers: [
      {
        url: "http://localhost:5000" // sesuaikan dengan port Anda
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT"
        }
      }
    }
  },
  apis: ["./routes/*.js"], // baca anotasi swagger dari route
};

const swaggerDocs = swaggerJsDoc(swaggerOptions);

// Export fungsi agar dipanggil di app.js
module.exports = (app) => {
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerDocs));
};
