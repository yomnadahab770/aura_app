import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../core/user_session.dart';
import '../theme/theme_selection_screen.dart';

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ThemeSelectionScreen(onThemeChanged: widget.onThemeChanged),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_person_outlined,
                      size: 60,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Welcome to AURA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'Login to control your smart ecosystem',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white70
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'name@example.com',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty
                      ? 'Please enter your email'
                      : null,
                ),
                const SizedBox(height: 20),
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white70
                        : Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      color: Colors.grey,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                  validator: (val) => val == null || val.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
