import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'event_bus.dart';
import '../ai/cortex_engine.dart';
import 'orchestrator_service.dart';

/// Connection state for the C2 bridge
enum C2State { disconnected, connecting, connected, error }

/// C2BridgeService: WebSocket bridge to the NEMESIS C2 server
class C2BridgeService extends ChangeNotifier {
  WebSocket? _socket;
  C2State _state = C2State.disconnected;
  String _serverUrl = 'ws://localhost:8080';
  final List<String> _log = [];
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  StreamSubscription? _eventSub;

  final EventBus _eventBus;

  C2BridgeService({required EventBus eventBus}) : _eventBus = eventBus;

  C2State get state => _state;
  String get serverUrl => _serverUrl;
  List<String> get log => List.unmodifiable(_log);
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Connect to the NEMESIS C2 server
  Future<void> connect({String? url}) async {
    if (url != null) _serverUrl = url;

    _state = C2State.connecting;
    _addLog('[C2] Connecting to $_serverUrl...');
    notifyListeners();

    try {
      _socket = await WebSocket.connect(_serverUrl);
      _state = C2State.connected;
      _addLog('[C2] CONNECTION ESTABLISHED');
      notifyListeners();

      _socket!.listen(
        (data) {
          try {
            final msg = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(msg);
            _addLog('[C2] << ${msg['type'] ?? 'unknown'}');
          } catch (e) {
            _addLog('[C2] JSON ERROR: $e');
          }
        },
        onDone: () {
          _state = C2State.disconnected;
          _addLog('[C2] Connection closed');
          notifyListeners();
        },
        onError: (e) {
          _state = C2State.error;
          _addLog('[C2] ERROR: $e');
          notifyListeners();
        },
      );

      // Initialize autonomous event syncing after connection
      _initEventSync();
    } catch (e) {
      _state = C2State.error;
      _addLog('[C2] FAILED: $e');
      notifyListeners();
    }
  }

  /// Send a payload to the C2 server
  void sendPayload(Map<String, dynamic> payload) {
    if (_socket == null || _state != C2State.connected) {
      _addLog('[C2] Cannot send - not connected');
      return;
    }
    final msg = jsonEncode(payload);
    _socket!.add(msg);
    _addLog('[C2] >> ${payload['type'] ?? 'unknown'}');
    notifyListeners();
  }

  /// Send a raw command to the C2 server
  void sendCommand(String cmd) {
    sendPayload({'type': 'exec', 'cmd': cmd});
  }

  /// Send an exploit trigger
  void sendExploit(String targetId, {Map<String, dynamic>? options}) {
    sendPayload({
      'type': 'exploit',
      'target_id': targetId,
      if (options != null) ...options,
    });
  }

  /// Send a persistence deployment command
  void sendPersistence(String level) {
    sendPayload({'type': 'persistence', 'level': level});
  }

  /// Send a data siphon command
  void sendSiphon(String mode, {String? path}) {
    sendPayload({
      'type': 'siphon',
      'mode': mode,
      if (path != null) 'path': path,
    });
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
    _state = C2State.disconnected;
    _addLog('[C2] Disconnected');
    notifyListeners();
  }

  void _addLog(String entry) {
    _log.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $entry');
    if (_log.length > 200) _log.removeAt(0);
  }

  void clearLog() {
    _log.clear();
    notifyListeners();
  }

  /// Autonomous Event Syncing Loop
  void _initEventSync() {
    _eventSub?.cancel();
    _eventSub = _eventBus.stream.listen((event) {
      if (_state != C2State.connected) return;

      // Auto-report significant events
      if (event.severity >= 30) {
        sendPayload({
          'type': 'defense_alert',
          'source': event.source,
          'message': event.message,
          'severity': event.severity,
        });
      }
    });
  }

  /// Synchronize CORTEX AI thinking to C2
  void syncCortex(CortexEngine cortex) {
    sendPayload({
      'type': 'cortex_sync',
      'reasoning_chain': cortex.reasoningChain,
      'confidence': cortex.confidence,
    });
  }

  /// Synchronize Orchestrator status
  void syncHeartbeat(OrchestratorService orc) {
    sendPayload({
      'type': 'heartbeat',
      'uptime': orc.uptime,
      'decisions': orc.decisionsCount,
    });
  }

  @override
  void dispose() {
    _socket?.close();
    _eventSub?.cancel();
    _messageController.close();
    super.dispose();
  }
}
