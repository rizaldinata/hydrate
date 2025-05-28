import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrate/presentation/screens/registration/registration2_view.dart';
import 'package:hydrate/presentation/widgets/alertWidgets/alert_widget.dart';

class RegistrationData extends StatefulWidget {
  @override
  _RegistrationDataState createState() => _RegistrationDataState();
}

class _RegistrationDataState extends State<RegistrationData> {
  TextEditingController controllerName = TextEditingController();
  TextEditingController controllerWeight = TextEditingController();
  bool isFormFilled = false;

  // Mengubah ke format yang konsisten dengan database
  String selectedGender = "Perempuan"; // Default gender
  int maxCharacters = 20;
  String remainingText = "0/20 karakter";

  // Validasi input
  // bool _isFormValid() {
  //   final weight = double.tryParse(controllerWeight.text);
  //   return controllerName.text.isNotEmpty &&
  //       selectedGender.isNotEmpty &&
  //       weight != null &&
  //       weight >= 1 &&
  //       weight <= 300;
  // }

  void _checkForm() {
    setState(() {
      isFormFilled =
          controllerName.text.isNotEmpty && controllerWeight.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();

    controllerName.addListener(_checkForm);
    controllerWeight.addListener(_checkForm);

    controllerName.addListener(() {
      setState(() {
        int currentLength = controllerName.text.length;
        remainingText = "$currentLength/$maxCharacters karakter";
      });
    });
  }

  @override
  void dispose() {
    controllerName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Logo HYDRATE
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
                      fontWeight: FontWeight.w800,
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
                  "Isilah sesuai dengan data diri kamu",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF2F2E41),
                  ),
                ),

                const SizedBox(height: 20),

                // Input Nama Lengkap
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: controllerName,
                      cursorColor: const Color(0xFF00A6FB),
                      maxLength: maxCharacters,
                      buildCounter: (
                        BuildContext context, {
                        required int currentLength,
                        required int? maxLength,
                        required bool isFocused,
                      }) =>
                          const SizedBox(), // Sembunyikan counter bawaan
                      decoration: InputDecoration(
                        hintText: "Nama Pengguna",
                        hintStyle: TextStyle(
                            color: const Color(0xFF2F2E41).withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF00A6FB), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Color(0xFF00A6FB), width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                    ),
                    Text(
                      remainingText,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Pilihan Jenis Kelamin - Format konsisten dengan database
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFF00A6FB), width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Background animasi bergerak
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: selectedGender == "Perempuan"
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2 - 20,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF28BAFD),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Tombol Perempuan
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedGender = "Perempuan";
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    selectedGender == "Perempuan"
                                        ? SvgPicture.asset(
                                            'assets/images/women.svg',
                                            height: 22,
                                          )
                                        : SvgPicture.asset(
                                            'assets/images/women.svg',
                                            height: 22,
                                            colorFilter: ColorFilter.mode(
                                                const Color(0xFF2F2E41)
                                                    .withOpacity(0.5),
                                                BlendMode.srcIn),
                                          ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Perempuan",
                                      style: TextStyle(
                                        color: selectedGender == "Perempuan"
                                            ? Colors.white
                                            : const Color(0xFF2F2E41)
                                                .withOpacity(0.5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Tombol Laki-laki
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedGender = "Laki-laki";
                                });
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    selectedGender == "Laki-laki"
                                        ? SvgPicture.asset(
                                            'assets/images/man.svg',
                                            height: 22,
                                          )
                                        : SvgPicture.asset(
                                            'assets/images/man.svg',
                                            height: 22,
                                            colorFilter: ColorFilter.mode(
                                                const Color(0xFF2F2E41)
                                                    .withOpacity(0.5),
                                                BlendMode.srcIn),
                                          ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Laki-laki",
                                      style: TextStyle(
                                        color: selectedGender == "Laki-laki"
                                            ? Colors.white
                                            : const Color(0xFF2F2E41)
                                                .withOpacity(0.5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Input Berat Badan (Only numbers)
                TextField(
                  controller: controllerWeight,
                  keyboardType: TextInputType.number,
                  cursorColor: const Color(0xFF00A6FB),
                  decoration: InputDecoration(
                    hintText: "Berat Badan",
                    suffixText: "kg",
                    suffixStyle:
                        TextStyle(color: const Color(0xFF2F2E41), fontSize: 16),
                    hintStyle: TextStyle(
                        color: const Color(0xFF2F2E41).withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: const Color(0xFF00A6FB), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: const Color(0xFF00A6FB), width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                ),

                const SizedBox(height: 50),

                // Tombol Selanjutnya
                GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 50),
                    height: 55,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isFormFilled
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF4ACCFF),
                                Color(0xFF00A6FB),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isFormFilled
                          ? null
                          : Colors.grey[400], // warna abu-abu saat tidak aktif
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: isFormFilled
                          ? () {
                              String name = controllerName.text.trim();
                              String weightText = controllerWeight.text.trim();
                              double? weight = double.tryParse(weightText);

                              if (weight == null) {
                                showWarningDialog(
                                    context, "Masukkan berat badan yang valid");
                              } else if (weight < 1 || weight > 300) {
                                showWarningDialog(context,
                                    "Berat badan harus antara 1 kg hingga 300 kg.");
                              } else {
                                // Semua valid, lanjut ke halaman berikutnya
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegistrationTime(
                                      name: name,
                                      gender: selectedGender,
                                      weight: weight,
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                      child: Text(
                        "SELANJUTNYA",
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
}
