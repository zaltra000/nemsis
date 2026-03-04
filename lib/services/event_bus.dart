import 'dart:async';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT BUS — Publish/Subscribe Communication System
/// All modules communicate through typed events
/// ═══════════════════════════════════════════════════════════════════════════

/// Event types in the NEMESIS system
enum NemesisEventType {
  threatDetected,
  exploitFound,
  dataExfiltrated,
  intrusionBlocked,
  aiDecision,
  systemAlert,
  anomalyDetected,
  moduleStarted,
  moduleStopped,
  commandExecuted,
  scanComplete,
  persistenceDeployed,
  evasionActivated,
  targetProfiled,
}

/// A single event in the NEMESIS system
class NemesisEvent {
  final NemesisEventType type;
  final String source;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int severity; // 0-100

  NemesisEvent({
    required this.type,
    required this.source,
    required this.message,
    this.data = const {},
    this.severity = 50,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// The EventBus: central nervous system of NEMESIS
class EventBus extends ChangeNotifier {
  final Map<NemesisEventType, List<void Function(NemesisEvent)>> _listeners =
      {};
  final List<NemesisEvent> _eventLog = [];
  final StreamController<NemesisEvent> _streamController =
      StreamController.broadcast();

  static const int _maxLogSize = 500;

  List<NemesisEvent> get eventLog => List.unmodifiable(_eventLog);
  Stream<NemesisEvent> get stream => _streamController.stream;
  int get totalEvents => _eventLog.length;

  /// Subscribe to a specific event type
  void on(NemesisEventType type, void Function(NemesisEvent) callback) {
    _listeners.putIfAbsent(type, () => []);
    _listeners[type]!.add(callback);
  }

  /// Emit an event
  void emit(NemesisEvent event) {
    _eventLog.insert(0, event);
    if (_eventLog.length > _maxLogSize) _eventLog.removeLast();

    // Notify type-specific listeners
    final typeListeners = _listeners[event.type];
    if (typeListeners != null) {
      for (final listener in typeListeners) {
        listener(event);
      }
    }

    // Broadcast to stream
    _streamController.add(event);
    notifyListeners();
  }

  /// Emit a quick alert
  void alert(String source, String message, {int severity = 50}) {
    emit(
      NemesisEvent(
        type: NemesisEventType.systemAlert,
        source: source,
        message: message,
        severity: severity,
      ),
    );
  }

  /// Get events by type
  List<NemesisEvent> getByType(NemesisEventType type) {
    return _eventLog.where((e) => e.type == type).toList();
  }

  /// Get events by severity threshold
  List<NemesisEvent> getBySeverity(int minSeverity) {
    return _eventLog.where((e) => e.severity >= minSeverity).toList();
  }

  void clearLog() {
    _eventLog.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }
}
