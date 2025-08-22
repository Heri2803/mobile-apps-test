import 'package:flutter/material.dart';
import '../siswa/profile_page.dart';
import '../siswa/detail_task_page.dart';
import '../api_services/api_services.dart'; // Import API service Anda
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String selectedStatus = 'Semua';
  DateTime? selectedDate;
  int currentUserId = 0;

  List<Map<String, dynamic>> userTasks = [];
  bool isLoadingTasks = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserTasks();
    _getCurrentUserId();
  }

  // Function utama - lebih singkat dan fokus
Future<void> _getCurrentUserId() async {
  try {
    final token = await _getStoredToken();
    final payload = _decodeJWT(token);
    
    currentUserId = payload['id'];
    print('✅ Current user ID: $currentUserId');
    
  } catch (e) {
    print('❌ Error getting user ID: $e');
    throw e;
  }
}

// Helper function: Ambil token dari storage
Future<String> _getStoredToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? prefs.getString('token');
  
  if (token == null || token.isEmpty) {
    throw Exception('Token not found');
  }
  
  return token;
}

// Helper function: Decode JWT token
Map<String, dynamic> _decodeJWT(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('Invalid token format');
  }
  
  // Decode payload dengan padding
  String payload = parts[1];
  switch (payload.length % 4) {
    case 1: payload += '==='; break;
    case 2: payload += '=='; break;
    case 3: payload += '='; break;
  }
  
  try {
    final decoded = utf8.decode(base64Url.decode(payload));
    final data = jsonDecode(decoded);
    
    if (!data.containsKey('id')) {
      throw Exception('User ID not found in token');
    }
    
    return data;
  } catch (e) {
    throw Exception('Failed to decode token');
  }
}

  // Fungsi untuk load tasks dari API
  Future<void> _loadUserTasks() async {
    try {
      setState(() {
        isLoadingTasks = true;
      });

      // Panggil API service untuk get all tasks (data mentah)
      final rawTasks = await ApiService.getAllTasks();
      print('📋 Raw tasks received: ${rawTasks.length}');

      List<Map<String, dynamic>> transformedTasks = [];

      // Transform setiap task menggunakan function yang sudah ada
      for (var taskData in rawTasks) {
        Map<String, dynamic>? transformedTask = _transformApiDataToUIFormat(
          taskData,
        );

        // Hanya tambahkan task yang berhasil di-transform (tidak null)
        if (transformedTask != null) {
          transformedTasks.add(transformedTask);
          print('✅ Task ${transformedTask['id']} added to list');
        } else {
          print('⚠️ Task ${taskData['id']} skipped (no user submission)');
        }
      }

      setState(() {
        userTasks = transformedTasks;
        isLoadingTasks = false;
      });

      print('📈 Total tasks loaded for user: ${transformedTasks.length}');
    } catch (e) {
      print('❌ Error loading all tasks: $e');
      setState(() {
        isLoadingTasks = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi untuk transform data dari API ke format UI
  Map<String, dynamic>? _transformApiDataToUIFormat(
    Map<String, dynamic> apiData,
  ) {
    try {
      print('🔄 Transforming API data for task: ${apiData['id']}');
      print('📋 Current user ID: $currentUserId');

      // Cari submission untuk current user
      final submissions = apiData['submissions'] as List;
      print('📝 Submissions found: ${submissions.length}');

      // Debug: print semua submissions
      for (var submission in submissions) {
        print(
          '   Submission: user_id=${submission['user_id']}, status=${submission['status']}',
        );
      }

      // Cek apakah ada user_submission langsung dari API response
      Map<String, dynamic>? userSubmission;

      // Prioritas 1: Cek user_submission dari API response langsung
      if (apiData.containsKey('user_submission') &&
          apiData['user_submission'] != null) {
        userSubmission = apiData['user_submission'];
        print(
          '✅ Found user_submission from API response: ${userSubmission!['status']}',
        );
      }
      // Prioritas 2: Cari di submissions array
      else {
        try {
          userSubmission = submissions.firstWhere(
            (submission) => submission['user_id'] == currentUserId,
          );
          print(
            '✅ Found user_submission from submissions array: ${userSubmission!['status']}',
          );
        } catch (e) {
          print('❌ User submission not found in submissions array');
          userSubmission = null;
        }
      }

      // Jika user tidak ada submission, skip task ini
      if (userSubmission == null) {
        print(
          '⚠️ No submission found for user $currentUserId, skipping task ${apiData['id']}',
        );
        return null;
      }

      // Transform status dari API ke UI
      String uiStatus = _mapApiStatusToUIStatus(userSubmission['status']);
      Color statusColor = _getStatusColor(uiStatus);

      // Parse due date
      DateTime dueDate = DateTime.parse(apiData['due_date']);

      print(
        '✅ Task ${apiData['id']} transformed successfully with status: $uiStatus',
      );

      return {
        'id': apiData['id'],
        'title': apiData['title'],
        'description': apiData['description'],
        'status': uiStatus,
        'date': dueDate,
        'statusColor': statusColor,
        'submissions': submissions,
        'creator': apiData['creator'],
        'current_user': apiData['current_user'],
        'pdf_file': apiData['pdf_file'],
        'created_by': apiData['created_by'],
        'completed': apiData['completed'],
        'user_submission': userSubmission,
        // Tambahan data dari API response
        'user_submission_status': apiData['user_submission_status'],
        'user_has_submitted': apiData['user_has_submitted'],
      };
    } catch (e) {
      print('❌ Error transforming API data: $e');
      print('❌ API Data: $apiData');
      return null;
    }
  }

  // Mapping status dari API ke UI
  String _mapApiStatusToUIStatus(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'selesai':
      case 'dikumpulkan':
        return 'Selesai';
      case 'tidak dikumpulkan':
        return 'Tidak Dikumpulkan';
      case 'terlambat':
        return 'Terlambat';
      default:
        return 'Tidak Dikumpulkan';
    }
  }

  // Mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Tidak Dikumpulkan':
        return Colors.red;
      case 'Terlambat':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get filteredTasks {
    List<Map<String, dynamic>> filtered = userTasks;

    // Filter berdasarkan status
    if (selectedStatus != 'Semua') {
      filtered =
          filtered.where((task) => task['status'] == selectedStatus).toList();
    }

    // Filter berdasarkan tanggal
    if (selectedDate != null) {
      filtered =
          filtered.where((task) {
            DateTime taskDate = task['date'];
            return taskDate.year == selectedDate!.year &&
                taskDate.month == selectedDate!.month &&
                taskDate.day == selectedDate!.day;
          }).toList();
    }

    return filtered;
  }

  // Refresh data
  Future<void> _refreshData() async {
    await _loadUserTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Page'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2196F3),
        elevation: 1,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            color: Colors.white,
            child: const Text(
              'Student Page',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Card dengan gambar dan Task Student
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Pattern background
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80',
                            ),
                            fit: BoxFit.cover,
                            opacity: 0.3,
                          ),
                        ),
                      ),
                    ),
                    // Text overlay
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Task Student',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Filter Status Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showStatusFilter(context);
                    },
                    icon: const Icon(Icons.filter_list, size: 20),
                    label: Text(
                      selectedStatus == 'Semua'
                          ? 'Filter Status'
                          : selectedStatus,
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedStatus == 'Semua'
                              ? Colors.grey[200]
                              : const Color(0xFF2196F3),
                      foregroundColor:
                          selectedStatus == 'Semua'
                              ? Colors.black87
                              : Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Tanggal Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 20),
                    label: Text(
                      selectedDate == null
                          ? 'Filter Tanggal'
                          : _formatDate(selectedDate!),
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedDate == null
                              ? Colors.grey[200]
                              : const Color(0xFF2196F3),
                      foregroundColor:
                          selectedDate == null ? Colors.black87 : Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                // Clear Filter Button
                if (selectedStatus != 'Semua' || selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          selectedStatus = 'Semua';
                          selectedDate = null;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.red),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content Area - Loading, Error, atau List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Button Student Page (current page)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Anda sudah berada di halaman Student'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.school, color: Colors.white, size: 24),
              ),
            ),

            // Button Profile Page
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(25),
              ),
              child: IconButton(
                onPressed: () {
                  // Navigate to Profile Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navigasi ke halaman Profile'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: Icon(Icons.person, color: Colors.grey[600], size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan loading, error, atau data
  Widget _buildContent() {
    if (isLoadingTasks) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
            ),
            SizedBox(height: 16),
            Text('Memuat data tugas...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              userTasks.isEmpty
                  ? 'Belum ada tugas tersedia'
                  : 'Tidak ada tugas sesuai filter',
              style: const TextStyle(fontSize: 16),
            ),
            if (selectedStatus != 'Semua' || selectedDate != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedStatus = 'Semua';
                    selectedDate = null;
                  });
                },
                child: const Text('Reset Filter'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailPage(task: task),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul tugas
                      Text(
                        task['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      // Description (opsional)
                      if (task['description'] != null &&
                          task['description'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Status dan tanggal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: task['statusColor'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: task['statusColor'],
                                width: 1,
                              ),
                            ),
                            child: Text(
                              task['status'],
                              style: TextStyle(
                                color: task['statusColor'],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          // Tanggal
                          Text(
                            _formatDate(task['date']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showStatusFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...['Semua', 'Selesai', 'Tidak Dikumpulkan', 'Terlambat'].map((
                status,
              ) {
                return ListTile(
                  leading: Radio<String>(
                    value: status,
                    groupValue: selectedStatus,
                    onChanged: (String? value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  title: Text(status),
                  onTap: () {
                    setState(() {
                      selectedStatus = status;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
