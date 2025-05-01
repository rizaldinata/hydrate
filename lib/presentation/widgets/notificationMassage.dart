import 'dart:math';

class HydrationMessages {
  static final List<String> messages = [
    "Minum dulu, ya! Tubuhmu butuh cairan sekarang 💧",
    "🚰 Saatnya minum air! Biar tetap segar & fokus 💪",
    "Jangan tunggu haus 🕒 Yuk, minum air sekarang juga! ",
    "Segelas air bisa bikin kamu lebih semangat! Minum, ya 💦",
    "🧊 Air putih = energi alami! Ayo minum dulu ✨",
    "📣 Reminder: Hidrasi itu penting. Yuk minum air dulu!",
    "🌿 Minum air sekarang, tubuhmu sedang butuh cairan!",
    "Rehat sejenak dan minum air untuk tubuh dan pikiran yang lebih baik 😌",
    "⚡ Butuh energi? Mulai dari segelas air dulu, yuk!",
  ];

  static String getRandomMessage() {
    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
}
