import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:climb_track/UI/widgets/login_widget.dart';
import 'package:climb_track/logic/auth_logic.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _usernamecontroller = TextEditingController();
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  final _confirmPasswordcontroller = TextEditingController();
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernamecontroller.dispose();
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    _confirmPasswordcontroller.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    await register(
      context: context,
      ref: ref,
      email: _emailcontroller.text,
      password: _passwordcontroller.text,
      confirmPassword: _confirmPasswordcontroller.text,
      username: _usernamecontroller.text,
      setLoading: (loading) => setState(() => _isLoading = loading),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordObscure = !_isPasswordObscure;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: LoginWidget(
        subtitle: "Register",
        children: [
          TextField(
            controller: _usernamecontroller,
            enabled: !_isLoading,
            decoration: InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _emailcontroller,
            enabled: !_isLoading,
            decoration: InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordcontroller,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordObscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            obscureText: _isPasswordObscure,
          ),
          TextField(
            controller: _confirmPasswordcontroller,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordObscure
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: _toggleConfirmPasswordVisibility,
              ),
            ),
            obscureText: _isConfirmPasswordObscure,
          ),
          FilledButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading ? CircularProgressIndicator() : Text('Register'),
          ),
        ],
      ),
    );
  }
}
