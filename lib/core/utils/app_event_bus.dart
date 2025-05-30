// app_event_bus.dart
import 'dart:async';

class AppEvent {
  final String type;
  final dynamic data;

  AppEvent(this.type, [this.data]);
}

class AppEventBus {
  static final AppEventBus _instance = AppEventBus._internal();
  factory AppEventBus() => _instance;
  AppEventBus._internal();

  final StreamController<AppEvent> _controller = StreamController<AppEvent>.broadcast();

  Stream<AppEvent> get stream => _controller.stream;

  void fire(String eventType, [dynamic data]) {
    _controller.sink.add(AppEvent(eventType, data));
  }

  void dispose() {
    _controller.close();
  }
}