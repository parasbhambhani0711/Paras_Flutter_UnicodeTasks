// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_theme.dart';
import 'signup_screen.dart';
import '../layout/main_layout_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/icon.png',
                    height: 90,
                    errorBuilder: (_, __, ___) => const Icon(Icons.school,
                        size: 80, color: AppTheme.brandRed)),
                const SizedBox(height: 16),
                const Text(
                  'STUDY BRAHMASTRA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/gemini_logo.png', height: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'AI Powered Study App',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                    controller: _email,
                    decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 16),
                TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          try {
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                    email: _email.text.trim(),
                                    password: _pass.text.trim());
                            if (!mounted) return;
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MainLayoutScreen()));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Login Failed: $e')));
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Log In'),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text("Don't have an account? Sign Up",
                      style: TextStyle(color: AppTheme.primaryNavy)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
