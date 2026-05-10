import 'package:fieldpulse/src/features/auth/providers/auth_provider.dart';
import 'package:fieldpulse/src/features/auth/widgets/auth_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authStateProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(26.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FieldPulse',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            AuthField(
              controller: _emailController,
              hintText: 'Enter your Email Address',
              labelText: 'Email',
              keyboardType: TextInputType.emailAddress,
              obscureText: false,
              prefixIcon: const Icon(Icons.email),
            ),
            const SizedBox(height: 16),
            AuthField(
              controller: _passwordController,
              hintText: 'Enter your Password',
              labelText: 'Password',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock),
              toggleVisibily: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              showPassword: !_obscurePassword,
            ),
            const SizedBox(height: 24),
            if (authState.isLoading)
              const CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 23.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final success = await authNotifier.login(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );
                        if (success && mounted) {
                          context.go('/jobs');
                        } else if (mounted && authState.error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(authState.error!)));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final success = await authNotifier.biometricLogin();
                        if (success && mounted) {
                          context.go('/jobs');
                        } else if (mounted && authState.error != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(authState.error!)));
                        }
                      },
                      icon: const Icon(Icons.fingerprint, size: 28),
                      label: const Text('Login with Biometrics'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 23.0),
              child: Text.rich(
                TextSpan(
                  text: "Don't have an account? ",
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => context.push('/register'),
                    ),
                  ],
                ),
              ),
            ),

            // TextButton(
            //   onPressed: () => Navigator.pushNamed(context, '/register'),
            //   child: const Text(
            //     "Don't have an account? Register",
            //     style: TextStyle(fontSize: 14, color: Colors.black),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
