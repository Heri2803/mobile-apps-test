import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';

// Model minimal untuk API Response
class ApiResult {
  final bool success;
  final String message;
  final dynamic data;
  final int? statusCode;

  ApiResult.success(this.message, {this.data})
    : success = true,
      statusCode = null;

  ApiResult.error(this.message, {this.statusCode})
    : success = false,
      data = null;
}

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // Token management
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Login function dengan ApiResult
  static Future<ApiResult> login({
    required String nip,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: json.encode({'nip': nip, 'password': password}),
          )
          .timeout(timeoutDuration);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Simpan token
        await saveToken(data['token']);
        return ApiResult.success(
          data['message'],
          data: {'token': data['token']},
        );
      } else {
        return ApiResult.error(
          data['message'] ?? 'Login gagal',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResult.error('Koneksi gagal: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    await removeToken();
  }

  // Get user profile dengan endpoint /api/users/{id}
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Token tidak ditemukan, silakan login kembali');
      }

      // Decode JWT token untuk mendapatkan userId
      final userId = _getUserIdFromToken(token);

      if (userId == null) {
        throw Exception('User ID tidak ditemukan dalam token');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // Token expired atau invalid
        await prefs.remove('auth_token');
        await prefs.remove('user_id');
        throw Exception('Session expired, silakan login kembali');
      } else if (response.statusCode == 404) {
        print('User profile tidak ditemukan');
        return null;
      } else {
        throw Exception('Failed to load profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting user profile: $e');
      throw Exception('Error getting user profile: $e');
    }
  }

  // Helper function untuk decode JWT token dan extract userId
  static int? _getUserIdFromToken(String token) {
    try {
      // Split JWT token (header.payload.signature)
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      // Decode payload (bagian kedua)
      String payload = parts[1];

      // Add padding if needed untuk base64 decode
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decodedBytes = base64Url.decode(payload);
      final decodedString = utf8.decode(decodedBytes);
      final payloadMap = json.decode(decodedString) as Map<String, dynamic>;

      // Berdasarkan JWT payload Anda, struktur adalah:
      // {"id": 2, "nip": "654321", "role": "siswa", "iat": 1755703875, "exp": 1755790275}
      return payloadMap['id'];
    } catch (e) {
      print('Error decoding JWT token: $e');
      return null;
    }
  }

  static Future<ApiResult> updateUserProfile({
    required int userId,
    String? name,
    String? nip,
    String? password,
    String? jurusan,
    String? kelas,
    XFile? xFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        return ApiResult.error('Token tidak ditemukan, silakan login kembali');
      }

      // Multipart request
      var uri = Uri.parse('$baseUrl/users/userUpdate/$userId');
      var request = http.MultipartRequest('PUT', uri);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Fields
      if (name != null) request.fields['name'] = name;
      if (nip != null) request.fields['nip'] = nip;
      if (password != null) request.fields['password'] = password;
      if (jurusan != null) request.fields['jurusan'] = jurusan;
      if (kelas != null) request.fields['kelas'] = kelas;

      // File
      if (xFile != null) {
        Uint8List fileBytes = await xFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto', // field backend
            fileBytes,
            filename: xFile.name,
          ),
        );
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResult.success(data['message'], data: data['data']);
      } else {
        return ApiResult.error(
          data['message'] ?? 'Update gagal',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResult.error('Koneksi gagal: ${e.toString()}');
    }
  }

  static String getProfileImageUrl(String? foto) {
    if (foto == null || foto.isEmpty) return '';

    // Gunakan base URL tanpa /api untuk static files
    String baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
    String fullUrl = '$baseUrlWithoutApi/uploadFoto/$foto';

    print('Base URL (without api): $baseUrlWithoutApi');
    print('Foto name: $foto');
    print('Full URL: $fullUrl');

    return fullUrl;
  }

  /// Ambil detail task berdasarkan taskId
  static Future<Map<String, dynamic>> getTaskById(int taskId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']; // Mengembalikan object task
      } else if (response.statusCode == 404) {
        throw Exception('Task tidak ditemukan');
      } else {
        throw Exception('Gagal mengambil detail task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  // Headers with token
  static Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> getTaskByIdForUser(int taskId) async {
    try {
      print('Fetching task detail for ID: $taskId');

      final headers = await _getHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/tasks/$taskId/user'), headers: headers)
          .timeout(timeoutDuration);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final Map<String, dynamic> jsonData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Success',
          'data': jsonData['data'],
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Task not found',
          'error': 'NOT_FOUND',
          'debug': jsonData['debug'],
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Access denied',
          'error': 'FORBIDDEN',
          'debug': jsonData['debug'],
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Unauthorized',
          'error': 'UNAUTHORIZED',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Server error',
          'error': 'SERVER_ERROR',
          'statusCode': response.statusCode,
        };
      }
    } on SocketException catch (e) {
      print('SocketException: $e');
      return {
        'success': false,
        'message': 'No internet connection',
        'error': 'NETWORK_ERROR',
        'exception': e.toString(),
      };
    } on HttpException catch (e) {
      print('HttpException: $e');
      return {
        'success': false,
        'message': 'Server connection error',
        'error': 'HTTP_ERROR',
        'exception': e.toString(),
      };
    } on FormatException catch (e) {
      print('FormatException: $e');
      return {
        'success': false,
        'message': 'Invalid response format',
        'error': 'FORMAT_ERROR',
        'exception': e.toString(),
      };
    } catch (e) {
      print('Unexpected error in getTaskByIdForUser: $e');
      return {
        'success': false,
        'message': 'Unexpected error occurred',
        'error': 'UNKNOWN_ERROR',
        'exception': e.toString(),
      };
    }
  }

  // Get all tasks - dibuat static supaya bisa dipanggil langsung
  static Future<List<Map<String, dynamic>>> getAllTasks() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('User token not found. Please login.');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['data'] != null
            ? responseData['data'].cast<Map<String, dynamic>>()
            : [];
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching all tasks: $e');
    }
  }

  /// Update submission dengan upload file PDF
  static Future<Map<String, dynamic>> updateSubmission({
    required String taskId,
    File? pdfFile,
    Uint8List? pdfBytes,
    String? fileName,
    required String token,
  }) async {
    try {
      Dio dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: timeoutDuration,
          receiveTimeout: timeoutDuration,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      FormData formData = FormData();

      // Validasi: pastikan minimal ada satu file yang diberikan
      if (pdfFile == null && (pdfBytes == null || fileName == null)) {
        return {'success': false, 'message': 'File PDF harus disediakan'};
      }

      // Handle file untuk mobile (menggunakan File)
      if (pdfFile != null) {
        // Validasi file exists dan readable
        if (!await pdfFile.exists()) {
          return {'success': false, 'message': 'File tidak ditemukan'};
        }

        String fileName = pdfFile.path.split('/').last;

        // Validasi ekstensi file
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          return {'success': false, 'message': 'File harus berformat PDF'};
        }

        try {
          formData.files.add(
            MapEntry(
              "pdf_file",
              await MultipartFile.fromFile(
                pdfFile.path,
                filename: fileName,
                contentType: MediaType('application', 'pdf'),
              ),
            ),
          );
        } catch (fileError) {
          print('Error reading file: $fileError');
          return {
            'success': false,
            'message': 'Gagal membaca file: ${fileError.toString()}',
          };
        }
      }
      // Handle file untuk web (menggunakan bytes)
      else if (pdfBytes != null && fileName != null) {
        // Validasi ekstensi file
        if (!fileName.toLowerCase().endsWith('.pdf')) {
          return {'success': false, 'message': 'File harus berformat PDF'};
        }

        // Validasi ukuran file (contoh: maksimal 10MB)
        if (pdfBytes.length > 10 * 1024 * 1024) {
          return {
            'success': false,
            'message': 'Ukuran file terlalu besar (maksimal 10MB)',
          };
        }

        formData.files.add(
          MapEntry(
            "pdf_file",
            MultipartFile.fromBytes(
              pdfBytes,
              filename: fileName,
              contentType: MediaType('application', 'pdf'),
            ),
          ),
        );
      }

      print('📤 Sending update submission for task: $taskId');
      print('📄 File info: ${pdfFile?.path ?? fileName}');

      Response response = await dio.put(
        '/task-submissions/$taskId',
        data: formData,
        options: Options(
          validateStatus: (status) {
            return status! < 500; // Accept all status codes below 500
          },
        ),
      );

      print('📨 Response status: ${response.statusCode}');
      print('📨 Response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
          'message': response.data['message'] ?? 'Submission berhasil diupdate',
        };
      } else if (response.statusCode == 400) {
        // Handle validation errors
        String errorMessage = 'Gagal update submission';
        if (response.data != null && response.data['message'] != null) {
          errorMessage = response.data['message'];
        } else if (response.data != null && response.data['errors'] != null) {
          errorMessage = response.data['errors'].toString();
        }
        return {'success': false, 'message': errorMessage};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Token tidak valid, silakan login ulang',
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Task submission tidak ditemukan'};
      } else if (response.statusCode == 413) {
        return {'success': false, 'message': 'File terlalu besar'};
      } else {
        return {
          'success': false,
          'message':
              'Error ${response.statusCode}: ${response.data?.toString() ?? 'Unknown error'}',
        };
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.type}');
      print('❌ DioException message: ${e.message}');
      print('❌ DioException response: ${e.response?.data}');

      String errorMessage = 'Terjadi kesalahan jaringan';

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMessage = 'Koneksi timeout, coba lagi';
          break;
        case DioExceptionType.sendTimeout:
          errorMessage = 'Timeout saat mengirim data';
          break;
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Timeout saat menerima data';
          break;
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 413) {
            errorMessage = 'File terlalu besar';
          } else {
            errorMessage =
                e.response?.data?['message'] ??
                'Server error: ${e.response?.statusCode}';
          }
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request dibatalkan';
          break;
        case DioExceptionType.connectionError:
          errorMessage = 'Tidak dapat terhubung ke server';
          break;
        default:
          errorMessage = e.message ?? 'Kesalahan tidak diketahui';
      }

      return {'success': false, 'message': errorMessage};
    } catch (e) {
      print('❌ Unexpected error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  /// Download PDF file dari task berdasarkan ID
  static Future<Map<String, dynamic>> downloadTaskPdf(int taskId) async {
    try {
      print('🔽 Starting download for task ID: $taskId');

      // Ambil token
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      dio.options.headers['Accept'] = 'application/pdf';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'task_${taskId}_soal_$timestamp.pdf';

      if (kIsWeb) {
        // Web: download langsung via blob
        final response = await dio.get<List<int>>(
          '$baseUrl/tasks/$taskId/download',
          options: Options(responseType: ResponseType.bytes),
        );

        final blob = html.Blob([Uint8List.fromList(response.data!)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement;
        anchor.href = url;
        anchor.download = fileName;
        anchor.click();
        html.Url.revokeObjectUrl(url);

        return {
          'success': true,
          'message': 'File berhasil diunduh (Web)',
          'fileName': fileName,
        };
      } else {
        // Mobile/Desktop: simpan di path_provider
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';

        await dio.download('$baseUrl/tasks/$taskId/download', filePath);

        return {
          'success': true,
          'message': 'File berhasil diunduh',
          'filePath': filePath,
          'fileName': fileName,
        };
      }
    } catch (e) {
      print('💥 General Exception: $e');
      return {'success': false, 'message': 'Error tidak terduga: $e'};
    }
  }


  /// Mengambil daftar tugas yang dibuat oleh guru
  static Future<Map<String, dynamic>> getTasksForGuru() async {
  try {
    print('Fetching tasks for guru...');

    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl/tasks/guru'), headers: headers)
        .timeout(timeoutDuration);

    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final Map<String, dynamic> jsonData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': jsonData['message'] ?? 'Success',
        'data': jsonData['data'],
        'total': jsonData['total'],
        'summary': jsonData['summary'],
        'statusCode': response.statusCode,
      };
    } else if (response.statusCode == 404) {
      return {
        'success': false,
        'message': jsonData['message'] ?? 'Tasks not found',
        'error': 'NOT_FOUND',
        'debug': jsonData['debug'],
        'statusCode': response.statusCode,
      };
    } else if (response.statusCode == 403) {
      return {
        'success': false,
        'message': jsonData['message'] ?? 'Access denied',
        'error': 'FORBIDDEN',
        'debug': jsonData['debug'],
        'statusCode': response.statusCode,
      };
    } else if (response.statusCode == 401) {
      return {
        'success': false,
        'message': jsonData['message'] ?? 'Unauthorized',
        'error': 'UNAUTHORIZED',
        'statusCode': response.statusCode,
      };
    } else {
      return {
        'success': false,
        'message': jsonData['message'] ?? 'Server error',
        'error': 'SERVER_ERROR',
        'statusCode': response.statusCode,
      };
    }
  } on SocketException catch (e) {
    print('SocketException: $e');
    return {
      'success': false,
      'message': 'No internet connection',
      'error': 'NETWORK_ERROR',
      'exception': e.toString(),
    };
  } on HttpException catch (e) {
    print('HttpException: $e');
    return {
      'success': false,
      'message': 'Server connection error',
      'error': 'HTTP_ERROR',
      'exception': e.toString(),
    };
  } on FormatException catch (e) {
    print('FormatException: $e');
    return {
      'success': false,
      'message': 'Invalid response format',
      'error': 'FORMAT_ERROR',
      'exception': e.toString(),
    };
  } catch (e) {
    print('Unexpected error in getTasksForGuru: $e');
    return {
      'success': false,
      'message': 'Unexpected error occurred',
      'error': 'UNKNOWN_ERROR',
      'exception': e.toString(),
    };
  }
}

/// Fungsi untuk membuat task baru dengan HTTP multipart request
static Future<Map<String, dynamic>> createTaskWithHttp({
  required String token,
  required String title,
  required String description,
  required String dueDate,
  File? pdfFile,            // untuk mobile
  Uint8List? pdfBytes,      // untuk web
  String? fileName,
}) async {
  try {
    var uri = Uri.parse('$baseUrl/tasks');
    var request = http.MultipartRequest('POST', uri);

    // Headers
    request.headers.addAll({
      'accept': '*/*',
      'Authorization': 'Bearer $token',
    });

    // Form fields
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['due_date'] = dueDate;

    // File attachment
    if (pdfFile != null) {
      // ✅ Mobile
      var multipartFile = await http.MultipartFile.fromPath(
        'pdf_file',
        pdfFile.path,
        filename: fileName ?? pdfFile.path.split('/').last,
      );
      request.files.add(multipartFile);
    } else if (pdfBytes != null) {
      // ✅ Web
      var multipartFile = http.MultipartFile.fromBytes(
        'pdf_file',
        pdfBytes,
        filename: fileName ?? 'upload.pdf',
      );
      request.files.add(multipartFile);
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create task: ${response.body}');
    }
  } catch (e) {
    throw Exception('Error creating task: $e');
  }
}


/// Fungsi untuk menghapus task berdasarkan ID
static Future<Map<String, dynamic>> deleteTask(int id) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {"success": false, "message": "Token tidak ditemukan"};
      }

      final response = await http
          .delete(
            Uri.parse("$baseUrl/tasks/$id"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"success": true, "message": data["message"] ?? "Task berhasil dihapus"};
      } else {
        final data = jsonDecode(response.body);
        return {"success": false, "message": data["message"] ?? "Gagal menghapus task"};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateTask(
  int taskId,
  String title,
  String description,
  String dueDate,
  {File? pdfFile, Uint8List? pdfBytes, String? fileName}
) async {
  try {
    final url = Uri.parse('$baseUrl/tasks/$taskId');
    
    var request = http.MultipartRequest('PUT', url);
    
    String? token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['due_date'] = dueDate;
    
    // Handle file upload for both web and mobile
    if (pdfFile != null) {
      // Mobile platform
      var multipartFile = await http.MultipartFile.fromPath(
        'pdf_file',
        pdfFile.path,
      );
      request.files.add(multipartFile);
    } else if (pdfBytes != null && fileName != null) {
      // Web platform
      var multipartFile = http.MultipartFile.fromBytes(
        'pdf_file',
        pdfBytes,
        filename: fileName,
      );
      request.files.add(multipartFile);
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    final responseData = json.decode(response.body);
    
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
        'status_submission': responseData['status_submission']
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Update task failed'
      };
    }
    
  } catch (e) {
    return {
      'success': false,
      'message': 'Error: $e'
    };
  }
}


}
