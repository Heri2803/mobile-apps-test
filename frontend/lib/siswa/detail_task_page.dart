import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../api_services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class TaskDetailPage extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskDetailPage({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  File? selectedFile;
  String? fileName;
  Uint8List? selectedBytes;

  // Data task yang akan di-update dari API
  Map<String, dynamic>? _detailTaskData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTaskDetail();
  }

  // Re-fetch data task detail dari API
  Future<void> _fetchTaskDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔄 Fetching task detail for ID: ${widget.task['id']}');

      // Panggil API untuk get detail task
      final response = await ApiService.getTaskByIdForUser(widget.task['id']);

      if (response['success']) {
        setState(() {
          _detailTaskData = response['data'];
          _isLoading = false;
        });
        print('✅ Task detail fetched successfully');
        print('📋 Detail data: $_detailTaskData');
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load task detail';
          _isLoading = false;
        });
        print('❌ Failed to fetch task detail: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading task detail: $e';
        _isLoading = false;
      });
      print('💥 Exception in _fetchTaskDetail: $e');
    }
  }

  // Getter menggunakan data detail yang sudah di-fetch, fallback ke data awal
  Map<String, dynamic> get _taskData => _detailTaskData ?? widget.task;

  String get taskTitle => _taskData['title'] ?? 'No Title';
  String get taskDescription => _taskData['description'] ?? 'No Description';
  DateTime get dueDate =>
      _taskData['due_date'] != null
          ? DateTime.parse(_taskData['due_date'])
          : (_taskData['date'] ?? DateTime.now());
  String get status =>
      _taskData['user_submission_status'] ??
      _taskData['status'] ??
      'Tidak Dikumpulkan';
  Color get statusColor => _getStatusColor(status);
  String? get taskPdfFile => _taskData['pdf_file'];

  // Data creator dari API detail (sudah lengkap)
  Map<String, dynamic>? get creator => _taskData['creator'];
  String get createdBy =>
      creator != null ? '${creator!['name']} (${creator!['nip']})' : 'Unknown';

  // Data user submission dari API detail
  Map<String, dynamic>? get userSubmission => _taskData['user_submission'];
  DateTime? get completedDate =>
      userSubmission?['submitted_at'] != null
          ? DateTime.parse(userSubmission!['submitted_at'])
          : null;
  String? get submittedPdfFile => userSubmission?['pdf_file'];

  // Current user data dari API detail (sudah lengkap)
  Map<String, dynamic>? get currentUser => _taskData['current_user'];

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;
      case 'tidak dikumpulkan':
      case 'tidak terkumpul':
        return Colors.red;
      case 'terlambat':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Icons.check_circle;
      case 'tidak dikumpulkan':
      case 'tidak terkumpul':
        return Icons.cancel;
      case 'terlambat':
        return Icons.access_time;
      default:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    String day = dateTime.day.toString().padLeft(2, '0');
    String month = months[dateTime.month];
    String year = dateTime.year.toString();
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year $hour:$minute';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    String day = dateTime.day.toString().padLeft(2, '0');
    String month = months[dateTime.month];
    String year = dateTime.year.toString();

    return '$day $month $year';
  }

  // Tambahkan variable untuk menyimpan bytes
  Uint8List? selectedFileBytes;

  Future<void> _pickFile() async {
    try {
      print('🔍 Starting file picker...');
      print('🔍 Platform: ${kIsWeb ? 'Web' : 'Mobile/Desktop'}');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb, // ✅ Load bytes hanya untuk web
      );

      print('📁 File picker result: ${result != null}');

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('📄 Selected file: ${file.name}');
        print('📏 File size: ${file.size} bytes');

        if (kIsWeb) {
          // ✅ Untuk Web Platform - JANGAN akses file.path!
          print('🌐 Processing for web platform...');
          print('🔍 File bytes available: ${file.bytes != null}');
          print('🔍 File bytes length: ${file.bytes?.length}');

          if (file.bytes != null) {
            setState(() {
              selectedFile = null;
              selectedBytes =
                  file.bytes!; // atau selectedFileBytes jika Anda pakai itu
              fileName = file.name;
            });

            print('✅ File selection successful (Web): ${file.name}');
            print('✅ Bytes stored: ${selectedBytes?.length} bytes');
          } else {
            throw Exception('Web platform: File bytes not available');
          }
        } else {
          // ✅ Untuk Mobile/Desktop Platform - boleh akses file.path
          print('📱 Processing for mobile/desktop platform...');
          print('🔍 File path: ${file.path}');
          print('🔍 File bytes available: ${file.bytes != null}');

          if (file.path != null) {
            final selectedFileObj = File(file.path!);

            if (!await selectedFileObj.exists()) {
              throw Exception('Selected file does not exist');
            }

            setState(() {
              selectedFile = selectedFileObj;
              selectedBytes = null; // atau selectedFileBytes = null
              fileName = file.name;
            });

            print('✅ File selection successful (Mobile): ${file.name}');
            print('✅ File path: ${selectedFile?.path}');
          } else {
            throw Exception('Mobile platform: File path not available');
          }
        }

        // ✅ Debug final state
        print('🎯 Final state after selection:');
        print('  - fileName: $fileName');
        if (kIsWeb) {
          print('  - selectedBytes: ${selectedBytes?.length ?? 'null'}');
          print('  - selectedFile: null (web)');
        } else {
          print('  - selectedFile: ${selectedFile?.path ?? 'null'}');
          print('  - selectedBytes: null (mobile)');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File terpilih: ${file.name} (${(file.size / 1024).toStringAsFixed(1)} KB)',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ No file selected or result is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada file yang dipilih'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('💥 Error in _pickFile: $e');
      print('📋 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih file: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _submitTask() {
    bool hasFile =
        (selectedFile != null) || (selectedBytes != null && fileName != null);

    if (!hasFile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan upload file PDF terlebih dahulu'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Submit'),
          content: Text(
            'Apakah Anda yakin ingin ${submittedPdfFile != null ? "update" : "submit"} tugas ini?\n'
            'File: ${fileName ?? submittedPdfFile ?? "No file"}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleTaskSubmission();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
              ),
              child: Text(
                submittedPdfFile != null ? 'Update' : 'Submit',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTaskSubmission() async {
    try {
      // ✅ Debug: Print nilai-nilai variable sebelum submit
      print('🔍 DEBUG _handleTaskSubmission called:');
      print('  - selectedFile: ${selectedFile?.path ?? 'null'}');
      print('  - fileName: $fileName');
      print('  - selectedBytes: ${selectedBytes?.length ?? 'null'}');
      print('  - taskId: ${_taskData['id']}');

      // Validasi file sebelum submit
      if (selectedFile == null && (selectedBytes == null || fileName == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih file PDF terlebih dahulu'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Uploading...'),
              ],
            ),
          );
        },
      );

      // Get token dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      if (token == null) {
        Navigator.of(context).pop(); // Close loading dialog
        throw Exception('Token not found');
      }

      print('✅ Token found, calling updateSubmission...');

      // Call API untuk update submission dengan parameter lengkap
      final response = await ApiService.updateSubmission(
        taskId: _taskData['id'].toString(),
        pdfFile: selectedFile, // Untuk mobile/desktop
        pdfBytes: selectedBytes, // Untuk web
        fileName: fileName, // Nama file
        token: token,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      print('📨 Response received: ${response['success']}');

      if (response['success'] == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              submittedPdfFile != null
                  ? 'Tugas berhasil di-update!'
                  : 'Tugas berhasil di-submit!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Reset selected file
        setState(() {
          selectedFile = null;
          selectedBytes = null; // Tambahkan reset untuk web bytes
          fileName = null;
        });

        // Re-fetch data untuk update UI
        await _fetchTaskDetail();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal submit tugas'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog jika masih ada
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      print('❌ Error in _handleTaskSubmission: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Method untuk download task file
  void _downloadTaskFile() async {
    if (taskPdfFile == null) return;

    try {
      // Tampilkan loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Mengunduh file soal...'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      print('🔽 Downloading task file for ID: ${widget.task['id']}');

      // Call API service
      final result = await ApiService.downloadTaskPdf(widget.task['id']);

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result['success']) {
        // Berhasil download
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('File soal berhasil diunduh'),
                      Text(
                        'Disimpan: ${result['fileName']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Buka Folder',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Open file manager to downloads folder
                print('🗂️ Open downloads folder');
              },
            ),
          ),
        );
      } else {
        // Gagal download
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('${result['message']}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: () {
                _downloadTaskFile(); // Retry download
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      print('❌ Error downloading task file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Gagal mengunduh file: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: () {
              _downloadTaskFile(); // Retry download
            },
          ),
        ),
      );
    }
  }

  // Method untuk menampilkan task file section
  Widget _buildTaskFileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task File (Soal)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  taskPdfFile!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              _downloadTaskFile();
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Detail Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Refresh button
          IconButton(
            onPressed: _fetchTaskDetail,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading task detail...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTaskDetail,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Main content
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with task ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Task',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2196F3)),
                ),
                child: Text(
                  'ID: ${_taskData['id'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main task detail card
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
                  // Title
                  _buildDetailItem(
                    label: 'Title',
                    value: taskTitle,
                    icon: Icons.assignment,
                    isTitle: true,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildDetailItem(
                    label: 'Description',
                    value: taskDescription,
                    icon: Icons.description,
                    isDescription: true,
                  ),
                  const SizedBox(height: 16),

                  // Due Date
                  _buildDetailItem(
                    label: 'Due Date',
                    value: _formatDateTime(dueDate),
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),

                  // Completed Date (if exists)
                  if (completedDate != null) ...[
                    _buildDetailItem(
                      label: 'Submitted At',
                      value: _formatDateTime(completedDate!),
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Task PDF File (if exists)
                  if (taskPdfFile != null) ...[
                    _buildTaskFileSection(),
                    const SizedBox(height: 16),
                  ],

                  // Status
                  _buildStatusItem(),
                  const SizedBox(height: 20),

                  // Current submitted file (if exists)
                  if (submittedPdfFile != null) ...[
                    _buildSubmittedFileSection(),
                    const SizedBox(height: 20),
                  ],

                  // Upload section
                  _buildUploadSection(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Creator and Current User info cards
          Row(
            children: [
              // Creator card
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildDetailItem(
                      label: 'Created By',
                      value: createdBy,
                      icon: Icons.person,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Current user card
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildDetailItem(
                      label: 'Student',
                      value:
                          currentUser != null
                              ? '${currentUser!['name']}\n${currentUser!['nip']}\n${currentUser!['kelas'] ?? 'N/A'}'
                              : 'Unknown Student',
                      icon: Icons.school,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Submit button
          Center(
            child: SizedBox(
              width: 150,
              height: 45,
              child: ElevatedButton(
                onPressed: _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  submittedPdfFile != null ? 'Update' : 'Submit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
    bool isTitle = false,
    bool isDescription = false,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: isTitle ? 16 : (isDescription ? 14 : 15),
              fontWeight: isTitle ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
              height: isDescription ? 1.4 : 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getStatusIcon(status),
              color: const Color(0xFF2196F3),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(status),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmittedFileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.file_present, color: Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Submitted File',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
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
                  submittedPdfFile!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: _downloadTaskFile,
                icon: const Icon(
                  Icons.download,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
                tooltip: 'Download File',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    bool canUpload =
        status.toLowerCase() != 'selesai' || submittedPdfFile != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.upload_file, color: Color(0xFF2196F3), size: 20),
            const SizedBox(width: 8),
            Text(
              submittedPdfFile != null ? 'Update File' : 'Upload File',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (fileName != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedFile = null;
                      fileName = null;
                    });
                  },
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
            onPressed: canUpload ? _pickFile : null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: canUpload ? const Color(0xFF2196F3) : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              Icons.upload_file,
              color: canUpload ? const Color(0xFF2196F3) : Colors.grey,
              size: 18,
            ),
            label: Text(
              fileName != null
                  ? 'Change PDF File'
                  : (submittedPdfFile != null
                      ? 'Upload New PDF'
                      : 'Upload PDF File'),
              style: TextStyle(
                color: canUpload ? const Color(0xFF2196F3) : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        if (!canUpload) ...[
          const SizedBox(height: 8),
          const Text(
            '* Task sudah selesai dan tidak bisa diubah',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
