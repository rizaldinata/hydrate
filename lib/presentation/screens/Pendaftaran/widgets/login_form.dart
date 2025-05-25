import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/presentation/controllers/login_controller.dart';
import 'package:hydrate/presentation/screens/main_screen.dart';
import 'package:hydrate/presentation/widgets/alert_widget.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isFormFilled = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkForm);
    _passwordController.addListener(_checkForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkForm() {
    setState(() {
      _isFormFilled = _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;
    });
  }

  Future<void> _submitLogin() async {
    // Dapatkan controller dari context, jangan dengarkan perubahan
    final controller = context.read<LoginController>();
    
    final success = await controller.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // Tampilkan error dari controller
        showWarningDialog(context, controller.errorMessage ?? "Terjadi kesalahan");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan perubahan pada controller untuk mengupdate UI (misal, tombol loading)
    final loginController = context.watch<LoginController>();

    return Column(
      children: [
        // Input Email
        TextField(
          controller: _emailController,
          cursorColor: const Color(0xFF00A6FB),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "Masukkan Alamat Email",
            // ... sisa dekorasi Anda
          ),
        ),
        const SizedBox(height: 20),
        // Input Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          cursorColor: const Color(0xFF00A6FB),
          decoration: InputDecoration(
            hintText: "Masukkan Kata Sandi",
            // ... sisa dekorasi Anda
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 50),
        // Tombol Login
        GestureDetector(
          onTap: (_isFormFilled && !loginController.isLoading) ? _submitLogin : null,
          child: Container(
            height: 55,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: (_isFormFilled && !loginController.isLoading)
                  ? const LinearGradient(colors: [Color(0xFF4ACCFF), Color(0xFF00A6FB)])
                  : null,
              color: (_isFormFilled && !loginController.isLoading) ? null : Colors.grey[400],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: loginController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "MASUK",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}