import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AddWaterModalContent extends StatefulWidget {
  final int selectedWater;
  final int? idPengguna;
  final Function(int) onWaterAdded;

  const AddWaterModalContent({
    required this.selectedWater,
    required this.idPengguna,
    required this.onWaterAdded,
  });

  @override
  AddWaterModalContentState createState() => AddWaterModalContentState();
}

class AddWaterModalContentState extends State<AddWaterModalContent> {
  late int tempSelectedWater;
  bool isCustomMode = false;
  late FixedExtentScrollController _scrollController;
  TextEditingController customWaterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tempSelectedWater = widget.selectedWater;
    _scrollController = FixedExtentScrollController(
      initialItem: (widget.selectedWater ~/ 50) - 1,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    customWaterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Tinggi modal: normal 420, saat keyboard muncul jadi setengahnya (210)
    double modalHeight = keyboardVisible ? 210 : 420;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      height: modalHeight,
      padding: EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and edit/close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Placeholder untuk balance layout
                SizedBox(width: 40),
                Text(
                  "Pilih Ukuran Air",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isCustomMode) {
                        isCustomMode = false;

                        if (tempSelectedWater % 50 == 0 &&
                            tempSelectedWater >= 50 &&
                            tempSelectedWater <= 1000) {
                          int targetIndex = (tempSelectedWater ~/ 50) - 1;

                          // TUNDA scroll sampai frame berikutnya
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.jumpToItem(targetIndex);
                          });
                        } else {
                          tempSelectedWater = 250;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.jumpToItem((250 ~/ 50) - 1);
                          });
                        }

                        customWaterController.clear();
                      } else {
                        isCustomMode = true;
                        customWaterController.text =
                            tempSelectedWater.toString();
                      }
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF00A6FB).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isCustomMode ? Icons.close : Icons.edit,
                      color: const Color(0xFF00A6FB),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              color: Colors.blue,
              thickness: 1,
              height: 20,
            ),
            SizedBox(
                height: keyboardVisible
                    ? 10
                    : 20), // Spacing lebih kecil saat keyboard muncul

            // Content area - either scroll wheel or custom input
            Expanded(
              child: isCustomMode
                  ? _buildCustomInputMode(context, keyboardVisible)
                  : _buildScrollWheelMode(context, keyboardVisible),
            ),

            // Spacing dan button hanya muncul saat keyboard tidak ada
            if (!keyboardVisible) ...[
              SizedBox(height: 20),
              SizedBox(
                width: MediaQuery.of(context).size.width - 100,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleAddWater();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Tambah Air",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  // Widget for scroll wheel mode dengan ukuran adaptif
  Widget _buildScrollWheelMode(BuildContext context, bool isCompact) {
    double wheelHeight =
        isCompact ? 100 : 200; // Setengah tinggi saat keyboard muncul

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: wheelHeight,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50, // Item lebih kecil saat compact
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: FixedExtentScrollPhysics(),
            controller: _scrollController,

            onSelectedItemChanged: (index) {
              setState(() {
                tempSelectedWater = (index + 1) * 50;
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 20,
              builder: (context, index) {
                int waterValue = (index + 1) * 50;
                return Center(
                  child: Text(
                    "$waterValue",
                    style: TextStyle(
                      fontSize: 40, // Font lebih kecil saat compact
                      fontWeight: FontWeight.bold,
                      color: tempSelectedWater == waterValue
                          ? const Color(0xFF00A6FB)
                          : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        IgnorePointer(
          child: Container(
            height: 50, // Container highlight lebih kecil
            width: MediaQuery.of(context).size.width - 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00A6FB).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        IgnorePointer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SvgPicture.asset(
                'assets/images/glass2.svg',
                width: 32, // Icon lebih kecil saat compact
                height: 32,
              ),
              Text(
                "mL",
                style: TextStyle(
                  fontSize: 24, // Text lebih kecil saat compact
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2F2E41),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddWater() async {
    // Validate custom input if in custom mode
    if (isCustomMode) {
      int? customValue = int.tryParse(customWaterController.text);
      if (customValue == null || customValue <= 0 || customValue > 2000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Masukkan nilai antara 1-2000 mL"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      tempSelectedWater = customValue;
    }

    if (widget.idPengguna == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User tidak teridentifikasi!")),
      );
      return;
    }

    await widget.onWaterAdded(tempSelectedWater);
  }

  // Widget for custom input mode dengan ukuran adaptif
  Widget _buildCustomInputMode(BuildContext context, bool isCompact) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Input container sesuai dengan design
        Container(
          child: Row(
            children: [
              // Left spacer untuk centering
              Expanded(flex: 1, child: Container()),

              // Input field
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A6FB).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: customWaterController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 40, // Font lebih kecil saat compact
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00A6FB),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "250",
                      hintStyle: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                    onChanged: (value) {
                      int? intValue = int.tryParse(value);
                      if (intValue != null) {
                        setState(() {
                          tempSelectedWater = intValue;
                        });
                      }
                    },
                    onSubmitted: (value) {
                      // Handle input selesai saat user tekan enter/done
                      if (isCustomMode) {
                        int? customValue = int.tryParse(value);
                        if (customValue != null &&
                            customValue > 0 &&
                            customValue <= 2000) {
                          // Auto submit jika nilai valid
                          _handleAddWater();
                        }
                      }
                    },
                  ),
                ),
              ),

              // mL text
              Expanded(
                flex: 1,
                child: Text(
                  "mL",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24, // Text lebih kecil saat compact
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2F2E41),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (!isCompact) ...[
          SizedBox(height: 20),
          Text(
            "Masukkan jumlah air (1-2000 mL)",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
