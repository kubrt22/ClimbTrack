import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:climb_track/UI/widgets/login_widget.dart';
import 'package:climb_track/logic/auth_logic.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailcontroller = TextEditingController();
  final _passwordcontroller = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    await signIn(
      context: context,
      ref: ref,
      email: _emailcontroller.text,
      password: _passwordcontroller.text,
      setLoading: (loading) => setState(() => _isLoading = loading),
    );
  }

  Future<void> _resetPassword() async {
    await resetPassword(
      context: context,
      ref: ref,
      email: _emailcontroller.text,
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isObscure = !_isObscure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(),
      body: LoginWidget(
        subtitle: "Sign in",
        children: [
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
                  _isObscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            obscureText: _isObscure,
          ),
          TextButton(
            onPressed: _isLoading ? null : _resetPassword,
            child: Text('Forgot password?'),
          ),
          FilledButton(
            onPressed: _isLoading ? null : _signIn,
            child: _isLoading ? CircularProgressIndicator() : Text('Sign In'),
          ),
        ],
      ),
    );
  }
}
