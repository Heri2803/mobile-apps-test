import 'package:flutter/material.dart';
import '../guru/create_task_page.dart';
import '../guru/task_detail_teacher_page.dart';
import '../api_services/api_services.dart'; // Sesuaikan dengan path API service Anda

class TeacherPage extends StatefulWidget {
  const TeacherPage({Key? key}) : super(key: key);

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  DateTime? selectedDate;
  List<Task> allTasks = [];
  List<Task> filteredTasks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasksFromAPI();
  }

  Future<void> _loadTasksFromAPI() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getTasksForGuru();

      if (result['success']) {
        final List<dynamic> tasksData = result['data'] ?? [];

        setState(() {
          allTasks =
              tasksData.map((taskJson) => Task.fromJson(taskJson)).toList();
          filteredTasks = List.from(allTasks);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Failed to load tasks';
          isLoading = false;
        });

        _showErrorSnackBar(result['message'] ?? 'Failed to load tasks');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading tasks: $e';
        isLoading = false;
      });

      _showErrorSnackBar('Error loading tasks');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _refreshTasks() async {
    await _loadTasksFromAPI();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
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

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _filterTasks();
      });
    }
  }

  void _filterTasks() {
    if (selectedDate == null) {
      setState(() {
        filteredTasks = List.from(allTasks);
      });
      return;
    }

    setState(() {
      filteredTasks =
          allTasks.where((task) {
            return _isSameDate(task.dueDate, selectedDate!);
          }).toList();
    });
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _clearFilter() {
    setState(() {
      selectedDate = null;
      filteredTasks = List.from(allTasks);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _confirmDeleteTask(BuildContext context, Task task, int index) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Konfirmasi"),
      content: const Text("Apakah Anda yakin ingin menghapus task ini?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Batal"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Hapus"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final result = await ApiService.deleteTask(task.id); // hasil Map
    final success = result["success"] as bool; // ambil bool
    final message = result["message"] as String; // ambil pesan

    if (success) {
      setState(() {
        allTasks.removeAt(index);
        filteredTasks.removeAt(index);
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            colors: [
              Color(0xFF2196F3), // Biru
              Color(0xFFE3F2FD), // Biru muda
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.5],
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
                    // Tombol Back
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),

                    const SizedBox(width: 12),

                    // Judul halaman
                    const Text(
                      'Teacher Page',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const Spacer(),

                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: isLoading ? null : _refreshTasks,
                      tooltip: 'Refresh Tasks',
                    ),
                  ],
                ),
              ),

              // Content section with white background
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Action buttons row (filter & create task)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Create task button
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const CreateTaskPage(),
                                    ),
                                  );

                                  // Refresh tasks jika ada perubahan
                                  if (result == true) {
                                    _refreshTasks();
                                  }
                                },
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                tooltip: 'Create Task',
                              ),
                            ),

                            // Filter buttons
                            Row(
                              children: [
                                // Date filter button
                                Container(
                                  decoration: BoxDecoration(
                                    color:
                                        selectedDate != null
                                            ? const Color(0xFF2196F3)
                                            : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: _selectDate,
                                    icon: Icon(
                                      Icons.date_range,
                                      color:
                                          selectedDate != null
                                              ? Colors.white
                                              : Colors.grey[600],
                                      size: 20,
                                    ),
                                    tooltip:
                                        selectedDate != null
                                            ? 'Filter: ${_formatDate(selectedDate!)}'
                                            : 'Filter Tanggal',
                                  ),
                                ),

                                // Clear filter button
                                if (selectedDate != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red[400],
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      onPressed: _clearFilter,
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      tooltip: 'Clear Filter',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Results info
                      if (selectedDate != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          margin: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Menampilkan ${filteredTasks.length} tugas untuk tanggal ${_formatDate(selectedDate!)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      // Content area
                      Expanded(
                        child:
                            isLoading
                                ? _buildLoadingState()
                                : errorMessage != null
                                ? _buildErrorState()
                                : filteredTasks.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                  onRefresh: _refreshTasks,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filteredTasks.length,
                                    itemBuilder: (context, index) {
                                      final task = filteredTasks[index];
                                      return _buildTaskCard(task, index);
                                    },
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading tasks...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load tasks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Unknown error occurred',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshTasks,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TaskDetailTeacherPage(
                      taskId: task.id, // <-- WAJIB diisi
                      task: task,
                    ),
              ),
            );

            // Refresh jika ada perubahan
            if (result == true) {
              _refreshTasks();
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Completion percentage badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCompletionColor(task.completionPercentage),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${task.completionPercentage}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Due Date
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Due Date:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(task.dueDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Submissions Statistics
                Row(
                  children: [
                    Icon(Icons.people, size: 18, color: Colors.blue[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Students:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.totalSubmissions}/${task.totalStudents}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Status breakdown
                Row(
                  children: [
                    // Selesai
                    _buildStatusChip(
                      'Selesai: ${task.selesaiCount}',
                      Colors.green,
                      Icons.check_circle,
                    ),
                    const SizedBox(width: 8),
                    // Terlambat
                    _buildStatusChip(
                      'Terlambat: ${task.terlambatCount}',
                      Colors.orange,
                      Icons.schedule,
                    ),
                    const SizedBox(width: 8),
                    // Tidak dikumpulkan
                    _buildStatusChip(
                      'Belum: ${task.statusSummary['tidak_dikumpulkan'] ?? 0}',
                      Colors.red,
                      Icons.pending,
                    ),
                  ],
                ),

                // Progress bar
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: task.completionPercentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCompletionColor(task.completionPercentage),
                  ),
                  minHeight: 6,
                ),

                // Delete icon button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _confirmDeleteTask(context, task, index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompletionColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            selectedDate != null
                ? 'Tidak ada tugas pada tanggal ini'
                : 'Tidak ada tugas tersedia',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedDate != null
                ? 'Coba pilih tanggal lain'
                : 'Belum ada tugas yang dibuat',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          if (selectedDate == null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateTaskPage(),
                  ),
                );

                if (result == true) {
                  _refreshTasks();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create First Task'),
            ),
          ],
        ],
      ),
    );
  }
}

class Task {
  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? completed;
  final String? pdfFile;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> creator;
  final int totalStudents;
  final int totalSubmissions;
  final int selesaiCount;
  final int terlambatCount;
  final Map<String, dynamic> statusSummary;
  final int completionPercentage;
  final Map<String, dynamic>? latestSubmission;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.completed,
    this.pdfFile,
    required this.createdAt,
    required this.updatedAt,
    required this.creator,
    required this.totalStudents,
    required this.totalSubmissions,
    required this.selesaiCount,
    required this.terlambatCount,
    required this.statusSummary,
    required this.completionPercentage,
    this.latestSubmission,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['due_date']),
      completed:
          json['completed'] != null ? DateTime.parse(json['completed']) : null,
      pdfFile: json['pdf_file'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      creator: json['creator'] ?? {},
      totalStudents: json['total_students'] ?? 0,
      totalSubmissions: json['total_submissions'] ?? 0,
      selesaiCount: json['selesai_count'] ?? 0,
      terlambatCount: json['terlambat_count'] ?? 0,
      statusSummary: json['status_summary'] ?? {},
      completionPercentage: json['completion_percentage'] ?? 0,
      latestSubmission: json['latest_submission'],
    );
  }
}
