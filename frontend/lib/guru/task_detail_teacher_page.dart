import 'package:flutter/material.dart';
import '../guru/teacher_page.dart';
import '../api_services/api_services.dart'; // Import your API service
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';


class TaskDetailTeacherPage extends StatefulWidget {
  final int taskId; // Changed from Task to taskId
  final Task? task; // Keep optional for backward compatibility

  const TaskDetailTeacherPage({Key? key, required this.taskId, this.task})
    : super(key: key);

  @override
  State<TaskDetailTeacherPage> createState() => _TaskDetailTeacherPageState();
}

class _TaskDetailTeacherPageState extends State<TaskDetailTeacherPage> {
  File? selectedFile;
  bool _fileChanged = false;
  Uint8List? selectedFileBytes; // Untuk web
  String? selectedFileName; // Nama file
  DateTime? selectedFilterDate;
  String selectedStatus = 'Semua';

  // Changed to nullable and will be loaded from API
  TaskDetail? taskDetail;
  List<StudentSubmission> allSubmissions = [];
  List<StudentSubmission> filteredSubmissions = [];

  bool isLoading = true;
  String? errorMessage;
  bool _isEditing = false; // ✅ State untuk mode editing
  

  final List<String> statusOptions = [
    'Semua',
    'submitted', // sesuai dengan API response
    'terlambat',
    'pending',
  ];

  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController dueDateController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    dueDateController = TextEditingController();
    _loadTaskDetail();
  }

  @override
  void dispose() {
    // ✅ jangan lupa dispose biar tidak memory leak
    titleController.dispose();
    descriptionController.dispose();
    dueDateController.dispose();
    super.dispose();
  }

  Future<void> _loadTaskDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getTaskByIdForUser(widget.taskId);

      if (response['success']) {
        final data = response['data'];
        final detail = _parseTaskDetailFromAPI(data);

        setState(() {
          taskDetail = detail;
          titleController.text = detail.title;
          descriptionController.text = detail.description;
          dueDateController.text = detail.dueDate.toString().substring(0, 10);
          isLoading = false;
        });
        _parseTaskDetailFromAPI(data);
      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Failed to load task detail';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading task detail: $e';
        isLoading = false;
      });
    }
  }

  // ✅ Function untuk toggle editing mode
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        // Reset controllers dengan data terbaru saat mulai edit
        titleController.text = taskDetail?.title ?? '';
        descriptionController.text = taskDetail?.description ?? '';
        dueDateController.text =
            taskDetail?.dueDate.toString().substring(0, 10) ?? '';
      }
    });
  }

  Future<void> _pickPdfFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          // Untuk web platform
          selectedFileBytes = result.files.single.bytes;
          selectedFileName = result.files.single.name;
          selectedFile = null;
        } else {
          // Untuk mobile platform
          selectedFile = File(result.files.single.path!);
          selectedFileName = result.files.single.name;
          selectedFileBytes = null;
        }
        _fileChanged = true;
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error selecting file: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
} 

void _removeSelectedFile() {
  setState(() {
    selectedFile = null;
    selectedFileBytes = null;
    selectedFileName = null;
    _fileChanged = true;
  });
}

Widget _buildFileItem({
  required String label,
  required String fileName,
  required IconData icon,
}) {
  // Determine display file name
  String displayFileName;
  if (selectedFileName != null) {
    displayFileName = selectedFileName!;
  } else {
    displayFileName = fileName;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 18),
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
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayFileName,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedFileName != null ? Colors.green[700] : Colors.black87,
                  fontWeight: selectedFileName != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            if (_isEditing) ...[
              IconButton(
                onPressed: _pickPdfFile,
                icon: const Icon(
                  Icons.folder,
                  size: 18,
                  color: Color(0xFF2196F3),
                ),
                tooltip: 'Select PDF File',
              ),
              if (selectedFileName != null)
                IconButton(
                  onPressed: _removeSelectedFile,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.red,
                  ),
                  tooltip: 'Remove File',
                ),
            ] else ...[
              if (displayFileName != 'No file')
                IconButton(
                  onPressed: () {
                    // Handle file download/view
                  },
                  icon: const Icon(
                    Icons.download,
                    size: 18,
                    color: Color(0xFF2196F3),
                  ),
                  tooltip: 'Download File',
                ),
            ],
          ],
        ),
      ),
    ],
  );
}


  // ✅ Function untuk save changes
  Future<void> _saveChanges() async {
  if (taskDetail == null) return;

  setState(() {
    isLoading = true;
  });

  try {
    final response = await ApiService.updateTask(
      widget.taskId,
      titleController.text,
      descriptionController.text,
      dueDateController.text,
      pdfFile: selectedFile, // Mobile
      pdfBytes: selectedFileBytes, // Web
      fileName: selectedFileName, // Nama file
    );

    if (response['success']) {
      setState(() {
        _isEditing = false;
        isLoading = false;
        _fileChanged = false; // Reset file change flag
      });

      // Reload data dari server untuk dapat data terbaru
      _loadTaskDetail();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error updating task: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  // ✅ Function untuk cancel editing
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      // Reset controllers ke data asli
      titleController.text = taskDetail?.title ?? '';
      descriptionController.text = taskDetail?.description ?? '';
      dueDateController.text =
          taskDetail?.dueDate.toString().substring(0, 10) ?? '';
    });
  }

  TaskDetail _parseTaskDetailFromAPI(Map<String, dynamic> data) {
    final parsedTask = TaskDetail(
      id: data['id'].toString(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: DateTime.parse(data['due_date']),
      completedDate:
          data['completed'] != null ? DateTime.parse(data['completed']) : null,
      teacherFile: data['pdf_file'],
      creator: UserInfo(
        id: data['creator']['id'],
        name: data['creator']['name'],
        nip: data['creator']['nip'],
        role: data['creator']['role'],
        jurusan: data['creator']['jurusan'],
        kelas: data['creator']['kelas'],
      ),
      currentUser: UserInfo(
        id: data['current_user']['id'],
        name: data['current_user']['name'],
        nip: data['current_user']['nip'],
        role: data['current_user']['role'],
        jurusan: data['current_user']['jurusan'],
        kelas: data['current_user']['kelas'],
      ),
      totalSubmissions: data['total_submissions'],
      submissionSummary: SubmissionSummary(
        total: data['submission_summary']['total'],
        submitted: data['submission_summary']['submitted'],
        pending: data['submission_summary']['pending'],
      ),
    );

    // parse submissions
    allSubmissions =
        (data['submissions'] as List).map((submission) {
          return StudentSubmission(
            id: submission['id'].toString(),
            studentName: submission['user']['name'],
            studentInfo: UserInfo(
              id: submission['user']['id'],
              name: submission['user']['name'],
              nip: submission['user']['nip'],
              role: submission['user']['role'],
              jurusan: submission['user']['jurusan'],
              kelas: submission['user']['kelas'],
            ),
            completedDate:
                submission['submitted_at'] != null
                    ? DateTime.parse(submission['submitted_at'])
                    : null,
            status: submission['status'],
            submittedFile: submission['pdf_file'],
          );
        }).toList();

    filteredSubmissions = List.from(allSubmissions);

    return parsedTask;
  }

  // Keep existing filter methods unchanged...
  Future<void> _selectFilterDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedFilterDate ?? DateTime.now(),
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

    if (picked != null && picked != selectedFilterDate) {
      setState(() {
        selectedFilterDate = picked;
        _applyFilters();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      selectedFilterDate = null;
      selectedStatus = 'Semua';
      filteredSubmissions = List.from(allSubmissions);
    });
  }

  void _applyFilters() {
    setState(() {
      filteredSubmissions =
          allSubmissions.where((submission) {
            bool matchesDate =
                selectedFilterDate == null ||
                (submission.completedDate != null &&
                    _isSameDate(
                      submission.completedDate!,
                      selectedFilterDate!,
                    ));

            bool matchesStatus =
                selectedStatus == 'Semua' ||
                submission.status == selectedStatus;

            return matchesDate && matchesStatus;
          }).toList();
    });
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.green;
      case 'terlambat':
        return Colors.orange;
      case 'pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.check_circle;
      case 'terlambat':
        return Icons.access_time;
      case 'pending':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'submitted':
        return 'Selesai';
      case 'terlambat':
        return 'Terlambat';
      case 'pending':
        return 'Belum Dikumpulkan';
      default:
        return status;
    }
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
                    const Expanded(
                      child: Text(
                        'Detail Task Teacher',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Refresh button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: _loadTaskDetail,
                        icon: const Icon(Icons.refresh, color: Colors.white),
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
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
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

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTaskDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (taskDetail == null) {
      return const Center(child: Text('No task data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Task detail card
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
                  // ✅ Header with Edit/Save buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Task Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      // ✅ Edit/Save/Cancel buttons
                      Row(
                        children: [
                          if (!_isEditing) ...[
                            // Edit button
                            IconButton(
                              onPressed: _toggleEditMode,
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF2196F3),
                              ),
                              tooltip: 'Edit Task',
                            ),
                          ] else ...[
                            // Save button
                            IconButton(
                              onPressed: _saveChanges,
                              icon: const Icon(Icons.save, color: Colors.green),
                              tooltip: 'Save Changes',
                            ),
                            const SizedBox(width: 8),
                            // Cancel button
                            IconButton(
                              onPressed: _cancelEdit,
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Cancel Edit',
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTaskDetailItem(
                    label: 'Title',
                    value: taskDetail?.title ?? 'No title',
                    icon: Icons.title,
                    controller: titleController,
                    readOnly: !_isEditing, // ✅ sekarang bisa toggle
                  ),
                  const SizedBox(height: 16),

                  _buildTaskDetailItem(
                    label: 'Description',
                    value: taskDetail?.description ?? 'No description',
                    icon: Icons.description,
                    controller: descriptionController,
                    readOnly: !_isEditing, // ✅ sekarang bisa toggle
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  _buildTaskDetailItem(
                    label: 'Due Date',
                    value:
                        taskDetail?.dueDate != null
                            ? _formatDate(taskDetail!.dueDate)
                            : 'No due date',
                    icon: Icons.calendar_today,
                    controller: dueDateController,
                    readOnly: !_isEditing, // ✅ sekarang bisa toggle
                    isDate: true,
                  ),
                  const SizedBox(height: 16),

                  _buildTaskDetailItem(
                    label: 'Created By',
                    value:
                        taskDetail?.creator != null
                            ? '${taskDetail!.creator!.name} (${taskDetail!.creator!.nip})'
                            : 'Unknown',
                    icon: Icons.person,
                    readOnly: true, // ✅ ini tetap readonly
                  ),
                  const SizedBox(height: 16),

                  _buildFileItem(
                    label: 'Task File',
                    fileName: selectedFile?.path.split('/').last ?? taskDetail?.teacherFile ?? 'No file',
                    icon: Icons.attach_file,
                  ),

                  const SizedBox(height: 16),

                  // Submission summary
                  _buildSubmissionSummaryCard(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Filter section (keep existing code)
          _buildFilterSection(),

          const SizedBox(height: 16),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Menampilkan ${filteredSubmissions.length} dari ${allSubmissions.length} submission',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Student submissions
          filteredSubmissions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSubmissions.length,
                itemBuilder: (context, index) {
                  final submission = filteredSubmissions[index];
                  return _buildSubmissionCard(submission);
                },
              ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSubmissionSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Submission Summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total',
                  taskDetail!.submissionSummary!.total.toString(),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Submitted',
                  taskDetail!.submissionSummary!.submitted.toString(),
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  taskDetail!.submissionSummary!.pending.toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // ✅ Enhanced _buildTaskDetailItem with better editing support
  Widget _buildTaskDetailItem({
    required String label,
    required IconData icon,
    String? value,
    TextEditingController? controller,
    bool readOnly = true,
    int maxLines = 1,
    bool isDate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 18),
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
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: readOnly ? Colors.grey[300]! : const Color(0xFF2196F3),
              width: readOnly ? 1 : 2,
            ),
          ),
          child:
              readOnly
                  ? Text(
                    value ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                  )
                  : TextField(
                    controller: controller,
                    maxLines: maxLines,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      suffixIcon:
                          isDate
                              ? IconButton(
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        DateTime.tryParse(
                                          controller?.text ?? '',
                                        ) ??
                                        DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    controller?.text = picked
                                        .toString()
                                        .substring(0, 10);
                                  }
                                },
                              )
                              : null,
                    ),
                    readOnly: isDate,
                    onTap:
                        isDate
                            ? () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    DateTime.tryParse(controller?.text ?? '') ??
                                    DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                controller?.text = picked.toString().substring(
                                  0,
                                  10,
                                );
                              }
                            }
                            : null,
                  ),
        ),
      ],
    );
  }

  // Widget _buildFileItem({
  //   required String label,
  //   required String? fileName,
  //   required IconData icon,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(icon, color: const Color(0xFF2196F3), size: 18),
  //           const SizedBox(width: 8),
  //           Text(
  //             label,
  //             style: const TextStyle(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w600,
  //               color: Colors.grey,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 6),
  //       if (fileName != null)
  //         Container(
  //           width: double.infinity,
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Colors.blue[50],
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.blue[200]!),
  //           ),
  //           child: Row(
  //             children: [
  //               const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(
  //                   fileName,
  //                   style: const TextStyle(
  //                     fontSize: 14,
  //                     color: Colors.black87,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ),
  //               IconButton(
  //                 onPressed: () {
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     SnackBar(
  //                       content: Text('Download: $fileName'),
  //                       duration: const Duration(seconds: 1),
  //                     ),
  //                   );
  //                 },
  //                 icon: const Icon(
  //                   Icons.download,
  //                   color: Color(0xFF2196F3),
  //                   size: 18,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         )
  //       else
  //         Container(
  //           width: double.infinity,
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Colors.grey[100],
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.grey[300]!),
  //           ),
  //           child: const Text(
  //             'No file attached',
  //             style: TextStyle(
  //               fontSize: 14,
  //               color: Colors.grey,
  //               fontStyle: FontStyle.italic,
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter Submissions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Date filter
                Expanded(
                  child: InkWell(
                    onTap: _selectFilterDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              selectedFilterDate != null
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color:
                            selectedFilterDate != null
                                ? const Color(0xFF2196F3).withOpacity(0.1)
                                : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 16,
                            color:
                                selectedFilterDate != null
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedFilterDate != null
                                  ? _formatDate(selectedFilterDate!)
                                  : 'Filter Tanggal',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    selectedFilterDate != null
                                        ? const Color(0xFF2196F3)
                                        : Colors.grey[600],
                                fontWeight:
                                    selectedFilterDate != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Status filter
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items:
                            statusOptions.map((String status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  status == 'Semua'
                                      ? status
                                      : _getStatusDisplayText(status),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedStatus = newValue;
                              _applyFilters();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Clear filter button
                if (selectedFilterDate != null || selectedStatus != 'Semua')
                  IconButton(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                    tooltip: 'Clear Filters',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(StudentSubmission submission) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Color(0xFF2196F3),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              submission.studentName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (submission.studentInfo != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${submission.studentInfo!.nip} • ${submission.studentInfo!.kelas ?? 'No Class'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(submission.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _getStatusColor(
                        submission.status,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(submission.status),
                        color: _getStatusColor(submission.status),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusDisplayText(submission.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(submission.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Submitted date
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color:
                      submission.completedDate != null
                          ? Colors.green[600]
                          : Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Submitted At:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  submission.completedDate != null
                      ? _formatDate(submission.completedDate!)
                      : 'Not submitted',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        submission.completedDate != null
                            ? Colors.green[600]
                            : Colors.grey[400],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Submitted file
            if (submission.submittedFile != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        submission.submittedFile!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Download: ${submission.submittedFile}',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.download,
                        color: Color(0xFF2196F3),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: const Text(
                  'No file submitted',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada submission yang sesuai dengan filter',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah filter atau hapus filter',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetail {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? completedDate;
  final String? teacherFile;
  final UserInfo creator;
  final UserInfo currentUser;
  final int totalSubmissions;
  final SubmissionSummary submissionSummary;

  TaskDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.completedDate,
    this.teacherFile,
    required this.creator,
    required this.currentUser,
    required this.totalSubmissions,
    required this.submissionSummary,
  });
}

class UserInfo {
  final int id;
  final String name;
  final String nip;
  final String role;
  final String? jurusan;
  final String? kelas;

  UserInfo({
    required this.id,
    required this.name,
    required this.nip,
    required this.role,
    this.jurusan,
    this.kelas,
  });
}

class SubmissionSummary {
  final int total;
  final int submitted;
  final int pending;

  SubmissionSummary({
    required this.total,
    required this.submitted,
    required this.pending,
  });
}

class StudentSubmission {
  final String id;
  final String studentName;
  final UserInfo studentInfo;
  final DateTime? completedDate;
  final String status;
  final String? submittedFile;

  StudentSubmission({
    required this.id,
    required this.studentName,
    required this.studentInfo,
    this.completedDate,
    required this.status,
    this.submittedFile,
  });
}
