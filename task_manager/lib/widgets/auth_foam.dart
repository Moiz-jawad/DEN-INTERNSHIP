// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

class AuthFoam extends StatefulWidget {
  final Future<void> Function(
    String email,
    String password,
    String userName,
    bool isLogin,
    BuildContext ctx,
  ) submitFn;
  final bool isLoading;

  const AuthFoam(this.submitFn, this.isLoading, {Key? key}) : super(key: key);

  @override
  State<AuthFoam> createState() => _AuthFoamState();
}

class _AuthFoamState extends State<AuthFoam>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  var _email = '';
  var _password = '';
  var _username = '';
  var _isLogin = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  void _trySubmit() async {
    final isValid = _formKey.currentState!.validate();
    FocusScope.of(context).unfocus();

    if (isValid) {
      _formKey.currentState!.save();
      try {
        await widget.submitFn(
          _email.trim(),
          _password.trim(),
          _username.trim(),
          _isLogin,
          context,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLogin ? 'Logged in successfully!' : 'Signed up successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _controller.reset();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildInput({
    required String label,
    required IconData icon,
    required bool obscureText,
    required String? Function(String?) validator,
    required void Function(String?) onSaved,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white24,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      obscureText: obscureText,
      validator: validator,
      onSaved: onSaved,
      keyboardType: keyboardType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.task_alt,
                            size: 64, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          _isLogin ? 'Welcome Back' : 'Create Account',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 32),
                        if (!_isLogin)
                          _buildInput(
                            label: 'Username',
                            icon: Icons.person,
                            obscureText: false,
                            validator: (value) {
                              if (value == null || value.trim().length < 4) {
                                return 'Username must be at least 4 characters.';
                              }
                              return null;
                            },
                            onSaved: (value) => _username = value!,
                          ),
                        if (!_isLogin) const SizedBox(height: 16),
                        _buildInput(
                          label: 'Email',
                          icon: Icons.email,
                          obscureText: false,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || !value.contains('@')) {
                              return 'Please enter a valid email.';
                            }
                            return null;
                          },
                          onSaved: (value) => _email = value!,
                        ),
                        const SizedBox(height: 16),
                        _buildInput(
                          label: 'Password',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value!,
                        ),
                        const SizedBox(height: 24),
                        widget.isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: Icon(
                                    _isLogin ? Icons.login : Icons.person_add),
                                label: Text(_isLogin ? 'Login' : 'Sign Up'),
                                onPressed: _trySubmit,
                              ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(
                            _isLogin
                                ? 'Don\'t have an account? Sign up'
                                : 'Already have an account? Log in',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
