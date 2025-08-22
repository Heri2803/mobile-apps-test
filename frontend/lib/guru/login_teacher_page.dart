import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'teacher_page.dart';
import '../api_services/api_services.dart';

/// Provider untuk state Login
class LoginProvider extends ChangeNotifier {
  final nipController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

    void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loginWithModels(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      setLoading(true);

      try {
        final result = await ApiService.login(
          nip: nipController.text.trim(),
          password: passwordController.text,
        );

        setLoading(false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TeacherPage()),
        );
          nipController.clear();
          passwordController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

    Future<void> login(BuildContext context) async {
    // Pilih salah satu:
    await loginWithModels(context); // atau loginWithoutModels(context)
  }

  void navigateToHome(BuildContext context) {
    // Navigator.pushNamed(context, '/home');
    // Atau jika menggunakan Navigator.push:
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TeacherPage()),
    );
  }

  @override
  void dispose() {
    nipController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class LoginTeacherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Consumer<LoginProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            body: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.blue.shade400,
                    Colors.blue.shade200,
                    Colors.white,
                    Colors.white,
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SizedBox(height: 40),

                      // Tombol Back di kiri atas
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => provider.navigateToHome(context),
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black26,
                            padding: EdgeInsets.all(12),
                            shape: CircleBorder(),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Judul Login
                      Text(
                        'Login Teacher',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 60),

                      // Card dengan form login
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Form(
                            key: provider.formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Text Field NIP
                                TextFormField(
                                  controller: provider.nipController,
                                  decoration: InputDecoration(
                                    labelText: 'NIP',
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'NIP tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20),

                                // Text Field Password
                                TextFormField(
                                  controller: provider.passwordController,
                                  obscureText: provider.obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        provider.obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        provider.togglePasswordVisibility();
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.blue.shade400,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            print('Navigate to Forgot Password page');
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Button Login
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => provider.login(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Create Account
                      // TextButton(
                      //   onPressed: () {
                      //     print('Navigate to Create Account page');
                      //   },
                      //   child: Text(
                      //     'Create Account',
                      //     style: TextStyle(
                      //       color: Colors.blue.shade600,
                      //       fontSize: 16,
                      //       fontWeight: FontWeight.w500,
                      //     ),
                      //   ),
                      // ),

                      SizedBox(height: 40),
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
}