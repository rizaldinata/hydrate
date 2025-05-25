import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Pastikan path SVG benar

class TimePickerInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const TimePickerInput({
    Key? key,
    required this.label,
    required this.controller,
  }) : super(key: key);

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
            primaryColor: const Color(0xFF00A6FB),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A6FB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2F2E41),
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
            style: const TextStyle(fontSize: 16, color: Color(0xFF2F2E41)),
            onTap: () => _selectTime(context),
            decoration: InputDecoration(
              hintText: widget.label,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2),
                  borderRadius: BorderRadius.circular(50)),
              focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF00A6FB), width: 2),
                  borderRadius: BorderRadius.circular(50)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _selectTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: const BoxDecoration(color: Color(0xFF00A6FB), shape: BoxShape.circle),
            child: SvgPicture.asset('assets/images/clock.svg', height: 24), // Pastikan path asset benar
          ),
        ),
      ],
    );
  }
}