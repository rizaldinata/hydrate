// app_event_bus.dart
import 'dart:async';

// Event class untuk komunikasi antar halaman
class AppEvent {
  final String type;
  final dynamic data;

  AppEvent(this.type, [this.data]);
}

// Singleton Event Bus untuk komunikasi antar halaman
class AppEventBus {
  // Singleton instance
  static final AppEventBus _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();

  // Stream controller untuk mengelola events
  final StreamController<AppEvent> _controller = StreamController<AppEvent>.broadcast();

  // Mendapatkan stream untuk mendengarkan events
  Stream<AppEvent> get stream => _controller.stream;

  // Memicu event
  void fire(String eventType, [dynamic data]) {
    _controller.sink.add(AppEvent(eventType, data));
  }

  // Menutup stream controller ketika sudah tidak dibutuhkan
  void dispose() {
    _controller.close();
  }
}