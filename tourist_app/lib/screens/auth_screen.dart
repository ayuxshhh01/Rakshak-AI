import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart'; // Ensure this path is correct

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();

  void _submit() {
    FocusScope.of(context).unfocus(); // Hide keyboard
    if (!_formKey.currentState!.validate()) return;

    if (_isLogin) {
      context.read<AuthBloc>().add(LoginRequested(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      ));
    } else {
      context.read<AuthBloc>().add(RegisterRequested(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
      ));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
          }
          if (state is AuthUnauthenticated && state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message!),
                  backgroundColor: const Color(0xFF006B5E),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            setState(() => _isLogin = true);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF006B5E), Color(0xFF004D47)],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.0, 60.0, 24.0, MediaQuery.of(context).viewInsets.bottom + 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogoAndTitle(),
                    const SizedBox(height: 40),
                    _buildUsernameField(),
                    const SizedBox(height: 18),
                    _buildPasswordField(),
                    _buildRegistrationFields(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                    _buildAuthToggle(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for a cleaner build method ---

  Widget _buildLogoAndTitle() {
    return Column(
      children: [
        Icon(Icons.explore_rounded, size: 64, color: const Color(0xFF006B5E), weight: 300),
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Text(
            _isLogin ? 'Welcome Back!' : 'Begin Your Journey',
            key: ValueKey<bool>(_isLogin),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1F36),
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _isLogin ? 'Continue exploring with confidence' : 'Create your traveler profile',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: _inputDecoration(
        labelText: 'Username',
        suffixIcon: Icons.person_outline,
      ),
      validator: (v) => v!.trim().isEmpty ? 'Username is required' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: _inputDecoration(
        labelText: 'Password',
        suffixIcon: Icons.lock_outline,
      ),
      obscureText: true,
      validator: (v) => v!.trim().length < 6
          ? 'Password must be at least 6 characters'
          : null,
    );
  }

  Widget _buildRegistrationFields() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          if (!_isLogin) ...[
            const SizedBox(height: 18),
            TextFormField(
              controller: _phoneController,
              decoration: _inputDecoration(
                labelText: 'Phone Number',
                suffixIcon: Icons.phone_outlined,
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty ? 'Phone number is required' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emergencyContactController,
              decoration: _inputDecoration(
                labelText: 'Emergency Contact',
                suffixIcon: Icons.contacts_outlined,
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.trim().isEmpty ? 'Emergency contact is required' : null,
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        bool isLoading = state is AuthLoading;
        return ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006B5E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            shadowColor: const Color(0xFF006B5E).withOpacity(0.4),
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Text(
            _isLogin ? 'Login' : 'Register',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthToggle() {
    return GestureDetector(
      onTap: () {
        _formKey.currentState?.reset();
        setState(() {
          _isLogin = !_isLogin;
          _usernameController.clear();
          _passwordController.clear();
          _phoneController.clear();
          _emergencyContactController.clear();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: _isLogin ? 'New to travel safety? ' : 'Already registered? ',
            style: const TextStyle(color: Color(0xFF757575), fontSize: 14, fontWeight: FontWeight.w500),
            children: [
              TextSpan(
                text: _isLogin ? 'Sign up now' : 'Login here',
                style: const TextStyle(
                  color: Color(0xFF006B5E),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Color(0xFF006B5E), fontWeight: FontWeight.w600, fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: const Color(0xFF006B5E), size: 20)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF006B5E), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}