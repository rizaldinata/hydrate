import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/screens/home_screen1.dart';

class RegistrationTime extends StatefulWidget {
  final String name;
  final String gender;
  final String weight;

  const RegistrationTime({
    Key? key,
    required this.name,
    required this.gender,
    required this.weight,
  }) : super(key: key);

  @override
  _RegistrationTimeState createState() => _RegistrationTimeState();
}

class _RegistrationTimeState extends State<RegistrationTime> {
  TextEditingController controllerWakeUpTime = TextEditingController();
  TextEditingController controllerSleepTime = TextEditingController();
  TextEditingController timeController = TextEditingController();

  Future<void> _selectTime(
      BuildContext context, TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        controller.text = picked.format(context);
      });
    }
  }

  bool _isFormValid() {
    return controllerWakeUpTime.text.isNotEmpty &&
        controllerSleepTime
            .text.isNotEmpty; // Validasi jam bangun dan jam tidur
  }

  // Alert dialog jika belum mengisi
  Future<void> _showWarningDialog() async {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Jangan bisa menutup modal dengan klik di luar
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: AnimatedScale(
            duration: Duration(milliseconds: 300),
            scale: 1.0,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: const Color(0XFFFFB830),
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Harap isi jam bangun dan jam tidur terlebih dahulu!",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F2E41),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0XFFFFB830), // Background color
                        foregroundColor: Colors.white, // Text color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Menutup modal
                      },
                      child: Text(
                        "Kembali",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo HYDRATE
                const SizedBox(
                  height: 20.0,
                ),
                Text(
                  "HYDRATE",
                  style: GoogleFonts.gluten(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00A6FB),
                  ),
                ),

                // Slogan
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Text(
                    "Hidrasi Tepat, Hidup Sehat",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F2E41),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Gambar
                SvgPicture.asset(
                  'assets/images/registrasi2.svg',
                  width: 250,
                ),

                const SizedBox(height: 20),

                // Teks "DAFTAR"
                Text(
                  "DAFTAR",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2F2E41),
                  ),
                ),

                // Sub-judul
                Text(
                  "Isilah waktu yang sesuai sama kamu",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF2F2E41),
                  ),
                ),

                const SizedBox(height: 20),

                TimePickerInput(
                    label: "Jam Bangun", controller: controllerWakeUpTime),
                const SizedBox(height: 20),
                TimePickerInput(
                    label: "Jam Tidur", controller: controllerSleepTime),

                // Tambahan dan gk keliatan biar layoutnya rapi
                Opacity(
                  opacity: 0.0,
                  child: IgnorePointer(
                    child: TimePickerInput(
                      label: "Jam Tidur",
                      controller: timeController, 
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4ACCFF),
                          Color(0xFF00A6FB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF00A6FB).withOpacity(0.25),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        if (_isFormValid()) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreens(
                                  name: widget.name,
                                  // gender: widget.gender,
                                  // weight: widget.weight,
                                  // wakeUpTime: controllerWakeUpTime.text,
                                  // sleepTime: controllerSleepTime.text,
                                ),
                              ));
                        } else {
                          _showWarningDialog();
                        }
                      },
                      child: Text(
                        "DAFTAR",
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInput(String hint, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xFF00A6FB), width: 2),
                borderRadius: BorderRadius.circular(50),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xFF00A6FB), width: 2),
                borderRadius: BorderRadius.circular(50),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _selectTime(context, controller),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF00A6FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}

class TimePickerInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const TimePickerInput(
      {Key? key, required this.label, required this.controller})
      : super(key: key);

  @override
  _TimePickerInputState createState() => _TimePickerInputState();
}

class _TimePickerInputState extends State<TimePickerInput> {
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            primaryColor: const Color(0xFF00A6FB), // Warna utama biru
            hintColor: const Color(0xFF00A6FB),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A6FB), // Warna utama
              onPrimary: Colors.white, // Warna teks di atas warna utama
              onSurface: const Color(0xFF2F2E41), // Warna teks utama
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                      ? const Color(0xFF00A6FB)
                      : const Color(0xFFE8F7FF)),
              hourMinuteTextColor: MaterialStateColor.resolveWith((states) =>
                  states.contains(MaterialState.selected)
                      ? Colors.white
                      : const Color(0xFF2F2E41)),
              dialHandColor: const Color(0xFF00A6FB),
              dialBackgroundColor: const Color(0xFFE8F7FF),
              entryModeIconColor: const Color(0xFF00A6FB),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        widget.controller.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            readOnly: true,
            textAlign: TextAlign.left,
            style:
                const TextStyle(fontSize: 16, color: const Color(0xFF2F2E41)),
            onTap: () =>
                _selectTime(context), // Tambahkan ini agar TextBox bisa diklik
            decoration: InputDecoration(
              hintText: widget.label,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xFF00A6FB), width: 2),
                borderRadius: BorderRadius.circular(50),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color(0xFF00A6FB), width: 2),
                borderRadius: BorderRadius.circular(50),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            // color: Color(0xFF00A6FB),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF00A6FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}
