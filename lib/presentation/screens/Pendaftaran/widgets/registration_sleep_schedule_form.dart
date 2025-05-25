import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/widgets/time_picker_input.dart';
import 'package:provider/provider.dart';
import 'package:hydrate/presentation/controllers/registration_sleep_schedule_controller.dart';
import 'package:hydrate/presentation/screens/main_screen.dart';


class RegistrationSleepScheduleForm extends StatefulWidget {
  final String name;
  final String gender;
  final double weight;
  final String email;
  final String password;

  const RegistrationSleepScheduleForm({
    super.key,
    required this.name,
    required this.gender,
    required this.weight,
    required this.email,
    required this.password,
  });

  @override
  State<RegistrationSleepScheduleForm> createState() => _RegistrationSleepScheduleFormState();
}

class _RegistrationSleepScheduleFormState extends State<RegistrationSleepScheduleForm> {
  final _wakeUpTimeController = TextEditingController();
  final _sleepTimeController = TextEditingController();

  @override
  void dispose() {
    _wakeUpTimeController.dispose();
    _sleepTimeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    final controller = context.read<RegistrationSleepScheduleController>();

    bool success = await controller.completeRegistration(
      email: widget.email,
      password: widget.password,
      name: widget.name,
      gender: widget.gender,
      weight: widget.weight,
      wakeUpTime: _wakeUpTimeController.text.trim(),
      sleepTime: _sleepTimeController.text.trim(),
    );

    if (mounted) {
      if (success) {
        _showSuccessDialog(); // Panggil dialog sukses Anda
      } else {
        // Tampilkan error dari controller
        _showErrorDialog(controller.errorMessage ?? "Terjadi kesalahan tidak diketahui.");
      }
    }
  }

  // --- Helper Dialogs (bisa juga diekstrak ke file utilitas) ---
  Future<void> _showSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) { // Ganti nama context agar tidak bentrok
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 60),
                const SizedBox(height: 20),
                Text("Registrasi Berhasil!", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("Akun Anda telah berhasil dibuat.", textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Tutup dialog
                    Navigator.pushAndRemoveUntil(
                      context, // Gunakan context dari State
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Text("Lanjutkan", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog(
       context: context,
       builder: (BuildContext dialogContext) { // Ganti nama context agar tidak bentrok
        return Dialog(
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
           child: Padding(
             padding: const EdgeInsets.all(20.0),
             child: Column(
               mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF5722), size: 60),
                  const SizedBox(height: 20),
                  Text("Registrasi Gagal", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text("Coba Lagi", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
             ),
           ),
         );
       },
    );
  }
  // --- Akhir Helper Dialogs ---


  @override
  Widget build(BuildContext context) {
    final regController = context.watch<RegistrationSleepScheduleController>();

    return Column(
      children: [
        TimePickerInput(label: "Jam Bangun", controller: _wakeUpTimeController),
        const SizedBox(height: 20),
        TimePickerInput(label: "Jam Tidur", controller: _sleepTimeController),
        const SizedBox(height: 50),
        // Tombol Daftar
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 50),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF4ACCFF), Color(0xFF00A6FB)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00A6FB).withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(vertical: 15)),
            onPressed: regController.isLoading ? null : _handleRegistration,
            child: regController.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("DAFTAR", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}