import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/presentation/controllers/registration_controller.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/registration_user_details_screen.dart';
import 'package:hydrate/presentation/widgets/alert_widget.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isFormFilled = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_checkForm);
    _passwordController.addListener(_checkForm);
    _confirmPasswordController.addListener(_checkForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkForm() {
    setState(() {
      _isFormFilled = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  void _handleNextButton() {
    final controller = context.read<RegistrationController>();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    final validationError = controller.validateInputs(email, password, confirmPassword);

    if (mounted) {
      if (validationError == null) {
        // Jika tidak ada error, navigasi ke halaman berikutnya
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationUserDetailsScreen(
              email: email,
              password: password,
            ),
          ),
        );
      } else {
        // Jika ada error, tampilkan dialog
        showWarningDialog(context, validationError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final registrationController = context.watch<RegistrationController>();

    return Column(
      children: [
        // Input Email
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(hintText: "Masukkan Alamat Email", /* ... sisa style ... */),
        ),
        const SizedBox(height: 20),
        // Input Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: "Masukkan Kata Sandi",
            // ... sisa style ...
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Input Konfirmasi Password
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: "Konfirmasi Kata Sandi",
            // ... sisa style ...
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 50),
        // Tombol Selanjutnya
        GestureDetector(
          onTap: (_isFormFilled && !registrationController.isLoading) ? _handleNextButton : null,
          child: Container(
            height: 55,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: (_isFormFilled && !registrationController.isLoading)
                  ? const LinearGradient(colors: [Color(0xFF4ACCFF), Color(0xFF00A6FB)])
                  : null,
              color: (_isFormFilled && !registrationController.isLoading) ? null : Colors.grey[400],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: registrationController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "SELANJUTNYA",
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}