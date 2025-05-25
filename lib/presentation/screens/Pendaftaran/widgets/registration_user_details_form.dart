import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/presentation/controllers/registration_user_details_controller.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/registration_sleep_schedule_screen.dart'; // Ini akan menjadi registration_sleep_time_screen.dart
import 'package:hydrate/presentation/widgets/alert_widget.dart';

class RegistrationUserDetailsForm extends StatefulWidget {
  final String email;
  final String password;

  const RegistrationUserDetailsForm({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<RegistrationUserDetailsForm> createState() => _RegistrationUserDetailsFormState();
}

class _RegistrationUserDetailsFormState extends State<RegistrationUserDetailsForm> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = "Perempuan"; // Default
  bool _isFormFilled = false;
  final int _maxNameCharacters = 20;
  String _remainingNameText = "0/20 karakter";

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_checkForm);
    _weightController.addListener(_checkForm);
    _nameController.addListener(() {
      setState(() {
        _remainingNameText = "${_nameController.text.length}/$_maxNameCharacters karakter";
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _checkForm() {
    setState(() {
      _isFormFilled = _nameController.text.isNotEmpty && _weightController.text.isNotEmpty;
    });
  }

  void _handleNextButton() {
    final controller = context.read<RegistrationUserDetailsController>();
    final name = _nameController.text.trim();
    final weightText = _weightController.text.trim();

    final validationError = controller.validateDetails(name, weightText);

    if (mounted) {
      if (validationError == null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationSleepScheduleScreen(
              email: widget.email,
              password: widget.password,
              name: name,
              gender: _selectedGender,
              weight: double.parse(weightText), // Sudah divalidasi jadi aman di-parse
            ),
          ),
        );
      } else {
        showWarningDialog(context, validationError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsController = context.watch<RegistrationUserDetailsController>();

    return Column(
      children: [
        // Input Nama Lengkap
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TextField(
              controller: _nameController,
              cursorColor: const Color(0xFF00A6FB),
              maxLength: _maxNameCharacters,
              buildCounter: (_, {required currentLength, required maxLength, required isFocused}) => const SizedBox(),
              decoration: InputDecoration(hintText: "Nama Pengguna", /* ... sisa style ... */),
            ),
            Text(_remainingNameText, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 10),
        // Pilihan Jenis Kelamin
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00A6FB), width: 2)),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: _selectedGender == "Perempuan" ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: MediaQuery.of(context).size.width / 2 - 20, // Sesuaikan
                  height: 50,
                  decoration: BoxDecoration(
                      color: const Color(0xFF28BAFD), borderRadius: BorderRadius.circular(14)),
                ),
              ),
              Row(
                children: ["Perempuan", "Laki-laki"].map((gender) {
                  bool isSelected = _selectedGender == gender;
                  String iconAsset = gender == "Perempuan" ? 'assets/images/women.svg' : 'assets/images/man.svg';
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = gender),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(iconAsset, height: 22,
                                colorFilter: ColorFilter.mode(
                                    isSelected ? Colors.white : const Color(0xFF2F2E41).withOpacity(0.5),
                                    BlendMode.srcIn)),
                            const SizedBox(width: 10),
                            Text(gender, style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF2F2E41).withOpacity(0.5),
                                fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Input Berat Badan
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          cursorColor: const Color(0xFF00A6FB),
          decoration: InputDecoration(hintText: "Berat Badan", suffixText: "kg", /* ... sisa style ... */),
        ),
        const SizedBox(height: 50),
        // Tombol Selanjutnya
        GestureDetector(
          onTap: (_isFormFilled && !userDetailsController.isLoading) ? _handleNextButton : null,
          child: Container(
            height: 55,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: (_isFormFilled && !userDetailsController.isLoading)
                  ? const LinearGradient(colors: [Color(0xFF4ACCFF), Color(0xFF00A6FB)])
                  : null,
              color: (_isFormFilled && !userDetailsController.isLoading) ? null : Colors.grey[400],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: userDetailsController.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("SELANJUTNYA", style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}