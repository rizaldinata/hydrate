import 'package:flutter/material.dart';
import 'package:hydrate/presentation/screens/profile_screen.dart';

class Navigasi extends StatefulWidget {
  final VoidCallback? onProfileUpdated; //
  const Navigasi({super.key,  this.onProfileUpdated});

  @override
  State<Navigasi> createState() => _NavigasiState();
}

class _NavigasiState extends State<Navigasi> with TickerProviderStateMixin {
  double horizontalPadding = 50.0;
  double horizontalMargin = 20.0;
  int noOfIcons = 3;

  late double position;

  List<String> icons = [
    'assets/images/navigasi/stats.png',
    'assets/images/navigasi/home.png',
    'assets/images/navigasi/user.png',
  ];

  List<Color> colors = [
    const Color.fromARGB(255, 0, 30, 255),
    const Color.fromARGB(255, 0, 30, 255),
    const Color.fromARGB(255, 0, 30, 255),
  ];

  late AnimationController controller;
  late Animation<double> animation;

  int selected = 0;

  @override
  void initState() {
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 375));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    animation = Tween(begin: getEndPosition(0), end: getEndPosition(2)).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    position = getEndPosition(0);
    super.didChangeDependencies();
  }

  double getEndPosition(int index) {
    double totalMargin = 2 * horizontalMargin;
    double totalPadding = 2 * horizontalPadding;
    double valuetoOmit = totalPadding + totalMargin;

    return (((MediaQuery.of(context).size.width - valuetoOmit) / noOfIcons) *
                index +
            horizontalPadding) +
        (((MediaQuery.of(context).size.width - valuetoOmit) / noOfIcons) / 2) -
        70;
  }

  void animateDrop(int index) {
    animation = Tween(begin: position, end: getEndPosition(index)).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    controller.forward().then((value) {
      position = getEndPosition(index);
      controller.dispose();
      controller = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 375));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Positioned.fill(
        //     child: AnimatedContainer(
        //   duration: const Duration(milliseconds: 375),
        //   curve: Curves.easeOut,
        //   color: colors[selected],
        // )),
        Positioned(
          bottom: horizontalMargin,
          left: horizontalMargin,
          child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: AppBarPainter(x: animation.value ?? position),
                  size: Size(
                      MediaQuery.of(context).size.width -
                          (2 * horizontalMargin),
                      80.0),
                  child: SizedBox(
                    height: 120.0,
                    width: MediaQuery.of(context).size.width -
                        (2 * horizontalMargin),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Row(
                        children: icons.map<Widget>((icon) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                animateDrop(icons.indexOf(icon));
                                selected = icons.indexOf(icon);
                              });
                              
                              // Pindah Halaman Profile
                              if (icons.indexOf(icon) == 2){
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()));
                              }

                            },
                            child: AnimatedContainer(
                              duration: const Duration(
                                milliseconds: 375,
                              ),
                              curve: Curves.easeOut,
                              height: 115.0,
                              width: (MediaQuery.of(context).size.width -
                                      (2 * horizontalMargin) -
                                      (2 * horizontalPadding)) /
                                  3,
                              padding:
                                  const EdgeInsets.only(top: 34.0, bottom: 10),
                              alignment: selected == icons.indexOf(icon)
                                  ? Alignment.topCenter
                                  : Alignment.bottomCenter,
                              child: SizedBox(
                                height: 35.0,
                                width: 35.0,
                                child: Center(
                                  child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 375),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeOut,
                                      child: selected == icons.indexOf(icon)
                                          ? Image.asset(
                                              icon,
                                              width: 23.0,
                                              color: Colors.white,
                                            )
                                          : Image.asset(
                                              icon,
                                              width: 23.0,
                                              color: Colors.white,
                                            )),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              }),
        )
      ],
    );
  }
}

class AppBarPainter extends CustomPainter {
  double x;

  AppBarPainter({required this.x});

  double height = 60.0;
  double start = 60.0;
  double end = 120.0;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var paintCircle = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0.0, start);

    double shift = 5.0;

    path.lineTo((x) < 20.0 ? 20.0 : x - shift, start);
    path.quadraticBezierTo(
        20.0 + x - shift, start, 38.0 + x - shift, start + 18.0);
    path.quadraticBezierTo(
        52.0 + x - shift, start + 33.0, 75.0 + x - shift, start + 33.0);
    path.quadraticBezierTo(
        98.0 + x - shift, start + 33.0, 112.0 + x - shift, start + 18.0);
    path.quadraticBezierTo(
        126.0 + x - shift,
        start,
        (144.0 + x - shift) > (size.width - 20.0)
            ? (size.width - 20.0)
            : 144.0 + x - shift,
        start);

    path.lineTo(size.width - 20.0, start);

    path.quadraticBezierTo(size.width, start, size.width, start + 25.0);
    path.lineTo(size.width, end - 25.0);
    path.quadraticBezierTo(size.width, end, size.width - 25.0, end);
    path.lineTo(25.0, end);
    path.quadraticBezierTo(0.0, end, 0.0, end - 25.0);
    path.lineTo(0.0, start + 25.0);
    path.quadraticBezierTo(0.0, start, 20.0, start);
    path.close();

    canvas.drawPath(path, paintCircle);

    canvas.drawCircle(Offset(70 + x, 55.0), 28.0, paintCircle);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
