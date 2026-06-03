import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/user_session.dart';
import '../../widgets/painters/starfield_painter.dart';
import '../../widgets/painters/glow_logo.dart';
import '../home/main_screen.dart'; // <-- تعديل: بدل theme_selection_screen

class LoginScreen extends StatefulWidget {
  final Function(ThemeMode, Color) onThemeChanged;
  const LoginScreen({super.key, required this.onThemeChanged});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const _primaryCyan = Color(0xFF00D4FF);
  static const _primaryBlue = Color(0xFF0088FF);
  static const _inputBg = Color(0xFF0A1428);
  static const _textGrey = Color(0xFFA0AAB5);

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      FirebaseDatabase.instance
          .ref('aura/users')
          .orderByChild('email')
          .equalTo(email)
          .once()
          .then((event) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            if (event.snapshot.value == null) {
              _showError();
              return;
            }
            final raw = event.snapshot.value;
            if (raw is! Map) {
              _showError();
              return;
            }
            final users = Map<String, dynamic>.from(raw);
            Map<String, dynamic>? foundUser;
            String? foundKey;
            for (final entry in users.entries) {
              if (entry.value is! Map) continue;
              final u = Map<String, dynamic>.from(entry.value as Map);
              if (u['password']?.toString() == password) {
                foundUser = u;
                foundKey = entry.key;
                break;
              }
            }
            if (foundUser == null) {
              _showError();
              return;
            }
            UserSession.uid = foundKey ?? '';
            UserSession.role = foundUser['role'] ?? 'Guest';
            UserSession.name = foundUser['name'] ?? 'User';
            UserSession.email = email;
            UserSession.houseName = foundUser['houseName'] ?? 'My Home';
            _navigateToThemes();
          })
          .catchError((e) {
            if (!mounted) return;
            setState(() => _isLoading = false);
            _showError();
          });
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Invalid email or password!'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _navigateToThemes() {
    // تعديل: نروح على MainScreen مباشرة بدل ThemeSelectionScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(onThemeChanged: widget.onThemeChanged),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1F),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: StarfieldPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  const GlowLogo(),
                  const SizedBox(height: 24),
                  const Text(
                    'AURA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'AI SAFETY MONITORING SYSTEM',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 10.5,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please sign in to continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration(
                            'Email Address',
                            Icons.email_outlined,
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please enter your email'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration:
                              _inputDecoration(
                                'Password',
                                Icons.lock_outlined,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _textGrey,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: _primaryCyan,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                              shadowColor: _primaryBlue.withOpacity(0.5),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don’t have an account?",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          "Sign Up",
                          style: TextStyle(
                            color: _primaryCyan,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      prefixIcon: Icon(icon, color: _textGrey),
      filled: true,
      fillColor: _inputBg.withOpacity(0.8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: _primaryCyan.withOpacity(0.3),
          width: 0.8,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _primaryCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
