import 'package:e_thursina_iibs/api_services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // <-- supaya kIsWeb dikenali

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({Key? key}) : super(key: key);

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Date variables
  DateTime? _dueDate;
  DateTime? _completedDate;

  // File variables
  File? _selectedFile;
  String? _fileName;
  Uint8List? _selectedFileBytes;

  // Loading state
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token'); // atau key yang Anda gunakan
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Method untuk format DateTime ke ISO 8601 dengan jam
  String _formatDateTimeToISO(DateTime dateTime) {
    // Set jam default ke 23:59 jika tidak ada jam yang dipilih
    DateTime finalDateTime = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      23, // jam
      59, // menit
      0, // detik
    );
    return finalDateTime.toUtc().toIso8601String();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2025, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectCompletedDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _completedDate ?? DateTime.now(),
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2025, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2196F3),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _completedDate) {
      setState(() {
        _completedDate = picked;
      });
    }
  }

  Future _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true, // ⬅️ penting untuk ambil bytes di web
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;

        if (kIsWeb) {
          // ✅ Untuk web: gunakan bytes, bukan path
          if (file.bytes != null) {
            setState(() {
              _selectedFileBytes = file.bytes;
              _fileName = file.name;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File terpilih: ${file.name}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('File bytes tidak tersedia di web');
          }
        } else {
          // ✅ Untuk Android/iOS: gunakan path
          if (file.path != null) {
            File selectedFile = File(file.path!);

            if (await selectedFile.exists()) {
              setState(() {
                _selectedFile = selectedFile;
                _fileName = file.name;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File terpilih: ${file.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              throw Exception('File tidak ditemukan di path: ${file.path}');
            }
          } else {
            throw Exception('Path file tidak tersedia');
          }
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memilih file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submitTask() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi due date
    if (_dueDate == null) {
      _showErrorSnackBar('Due Date harus dipilih');
      return;
    }

    // Set loading state
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Ambil token dari SharedPreferences
      String? token = await _getToken();

      if (token == null || token.isEmpty) {
        _showErrorSnackBar('Token tidak ditemukan. Silakan login kembali.');
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Siapkan data
      String title = _titleController.text.trim();
      String description = _descriptionController.text.trim();
      String formattedDueDate = _formatDateTimeToISO(_dueDate!);

      // Panggil API service
      Map<String, dynamic> response = await ApiService.createTaskWithHttp(
        token: token,
        title: title,
        description: description,
        dueDate: formattedDueDate,
        pdfFile: kIsWeb ? null : _selectedFile, // mobile
        pdfBytes: kIsWeb ? _selectedFileBytes : null, // web
        fileName: _fileName,
      );

      // Jika berhasil
      _showSuccessSnackBar(response['message'] ?? 'Task berhasil dibuat!');

      // Clear form
      _clearForm();

      // Kembali ke halaman sebelumnya dengan result
      Navigator.pop(context, true); // true menandakan berhasil create task
    } on SocketException {
      _showErrorSnackBar(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on FormatException {
      _showErrorSnackBar('Response format tidak valid dari server');
    } catch (e) {
      String errorMessage = e.toString();

      // Handle specific error messages
      if (errorMessage.contains('Unauthorized')) {
        _showErrorSnackBar('Token expired. Silakan login kembali.');
        // Optional: Navigate to login page
        // Navigator.pushReplacementNamed(context, '/login');
      } else if (errorMessage.contains('Forbidden')) {
        _showErrorSnackBar('Anda tidak memiliki akses untuk membuat task.');
      } else if (errorMessage.contains('Bad Request')) {
        _showErrorSnackBar(
          'Data yang dikirim tidak valid. Periksa kembali form Anda.',
        );
      } else {
        // Clean up error message
        String cleanError = errorMessage.replaceAll('Exception: ', '');
        _showErrorSnackBar('Error: $cleanError');
      }

      print('Error creating task: $e'); // For debugging
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Helper methods untuk cleaner code
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _dueDate = null;
      _completedDate = null;
      _selectedFile = null;
      _fileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xFF2196F3), Colors.white],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section with gradient background
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Create Task',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Content section with white background
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(color: Colors.white),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Main card with form fields
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title field
                                  _buildTextFormField(
                                    controller: _titleController,
                                    label: 'Title',
                                    icon: Icons.title,
                                    hintText: 'Masukkan judul tugas',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Title tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Description field
                                  _buildTextFormField(
                                    controller: _descriptionController,
                                    label: 'Description',
                                    icon: Icons.description,
                                    hintText: 'Masukkan deskripsi tugas',
                                    maxLines: 4,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Description tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Due Date field
                                  _buildDateField(
                                    label: 'Due Date',
                                    icon: Icons.calendar_today,
                                    selectedDate: _dueDate,
                                    onTap: _selectDueDate,
                                    isRequired: true,
                                  ),
                                  const SizedBox(height: 20),

                                  // Completed Date field
                                  _buildDateField(
                                    label: 'Completed Date',
                                    icon: Icons.check_circle_outline,
                                    selectedDate: _completedDate,
                                    onTap: _selectCompletedDate,
                                    isRequired: false,
                                  ),
                                  const SizedBox(height: 20),

                                  // Upload PDF section
                                  _buildUploadSection(),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitTask,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child:
                                  _isSubmitting
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text(
                                        'Submit Task',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2196F3)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? _formatDate(selectedDate)
                      : 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        selectedDate != null
                            ? Colors.black87
                            : Colors.grey[400],
                  ),
                ),
                Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.upload_file, color: Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Upload PDF',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_fileName != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _removeFile,
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                ),
              ],
            ),
          ),
        ],

        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton.icon(
            onPressed: _pickFile,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2196F3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(
              Icons.upload_file,
              color: Color(0xFF2196F3),
              size: 18,
            ),
            label: Text(
              _fileName != null ? 'Ganti File PDF' : 'Pilih File PDF',
              style: const TextStyle(
                color: Color(0xFF2196F3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
