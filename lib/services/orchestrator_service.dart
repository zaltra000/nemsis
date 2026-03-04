import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ai/cortex_engine.dart';
import '../ai/knowledge_base.dart';
import '../ai/reasoning_engine.dart';
import '../ai/anomaly_detector.dart';
import 'event_bus.dart';
import 'c2_bridge_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ORCHESTRATOR — Autonomous Background Command & Control
/// The living brain that coordinates all NEMESIS subsystems
/// ═══════════════════════════════════════════════════════════════════════════

/// Orchestrator state
enum OrchestratorState { offline, initializing, running, paused, error }

/// The Orchestrator: brings NEMESIS to life
class OrchestratorService extends ChangeNotifier {
  final CortexEngine cortex;
  final KnowledgeBase knowledgeBase;
  final ReasoningEngine reasoning;
  final AnomalyDetector anomalyDetector;
  final EventBus eventBus;
  final C2BridgeService c2;

  OrchestratorState _state = OrchestratorState.offline;
  Timer? _heartbeatTimer;
  int _uptime = 0; // seconds
  int _decisionsCount = 0;

  OrchestratorState get state => _state;
  int get uptime => _uptime;
  int get decisionsCount => _decisionsCount;
  String get uptimeFormatted {
    final h = _uptime ~/ 3600;
    final m = (_uptime % 3600) ~/ 60;
    final s = _uptime % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  OrchestratorService({
    required this.cortex,
    required this.knowledgeBase,
    required this.reasoning,
    required this.anomalyDetector,
    required this.eventBus,
    required this.c2,
  });

  /// Initialize and start the Orchestrator
  Future<void> initialize() async {
    _state = OrchestratorState.initializing;
    notifyListeners();

    try {
      // Phase 1: Initialize Knowledge Base
      eventBus.alert('ORCHESTRATOR', 'Loading knowledge base...', severity: 20);
      await knowledgeBase.initialize();
      eventBus.emit(
        NemesisEvent(
          type: NemesisEventType.moduleStarted,
          source: 'ORCHESTRATOR',
          message:
              'Knowledge base loaded: ${knowledgeBase.totalEntries} entries',
          severity: 30,
        ),
      );

      // Phase 2: Initialize CORTEX
      eventBus.alert(
        'ORCHESTRATOR',
        'Initializing CORTEX engine...',
        severity: 20,
      );
      await cortex.initialize();
      eventBus.emit(
        NemesisEvent(
          type: NemesisEventType.moduleStarted,
          source: 'ORCHESTRATOR',
          message: 'CORTEX engine online',
          severity: 30,
        ),
      );

      // Phase 3: Start Anomaly Detector
      anomalyDetector.start();
      eventBus.emit(
        NemesisEvent(
          type: NemesisEventType.moduleStarted,
          source: 'ORCHESTRATOR',
          message: 'Anomaly detector active',
          severity: 20,
        ),
      );

      // Phase 4: Wire up event handlers
      _wireEventHandlers();

      // Phase 5: Start heartbeat
      _startHeartbeat();

      _state = OrchestratorState.running;
      eventBus.emit(
        NemesisEvent(
          type: NemesisEventType.systemAlert,
          source: 'ORCHESTRATOR',
          message: 'NEMESIS V8 OPERATIONAL. All subsystems online.',
          severity: 50,
        ),
      );
      notifyListeners();
    } catch (e) {
      _state = OrchestratorState.error;
      eventBus.alert('ORCHESTRATOR', 'INIT FAILED: $e', severity: 100);
      notifyListeners();
    }
  }

  /// Wire up cross-module event handlers
  void _wireEventHandlers() {
    // When anomaly detected → feed to CORTEX for analysis
    eventBus.on(NemesisEventType.anomalyDetected, (event) async {
      _decisionsCount++;
      // Auto-analyze the anomaly
      await reasoning.assessThreat(event.message);
      notifyListeners();
    });

    // When threat detected → auto-respond
    eventBus.on(NemesisEventType.threatDetected, (event) {
      _decisionsCount++;
      if (event.severity >= 80) {
        eventBus.alert(
          'CORTEX',
          'HIGH THREAT: Auto-analysis initiated for "${event.message}"',
          severity: 90,
        );
      }
      notifyListeners();
    });

    // When exploit found → log and correlate
    eventBus.on(NemesisEventType.exploitFound, (event) {
      _decisionsCount++;
      notifyListeners();
    });
  }

  /// Heartbeat: tracks uptime and performs periodic checks
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _uptime++;

      // Every 60 seconds: check anomaly detector
      if (_uptime % 60 == 0) {
        final criticals = anomalyDetector.criticalCount;
        if (criticals > 0) {
          eventBus.emit(
            NemesisEvent(
              type: NemesisEventType.anomalyDetected,
              source: 'ORCHESTRATOR',
              message: '$criticals critical anomalies detected',
              severity: 90,
            ),
          );
        }
      }

      // Notify every 5 seconds for UI updates
      if (_uptime % 5 == 0) {
        notifyListeners();

        // Sync to C2 if connected
        if (c2.state == C2State.connected) {
          c2.syncHeartbeat(this);
          c2.syncCortex(cortex);
        }
      }
    });
  }

  /// Pause the orchestrator
  void pause() {
    _state = OrchestratorState.paused;
    anomalyDetector.stop();
    eventBus.alert('ORCHESTRATOR', 'Paused', severity: 30);
    notifyListeners();
  }

  /// Resume the orchestrator
  void resume() {
    _state = OrchestratorState.running;
    anomalyDetector.start();
    eventBus.alert('ORCHESTRATOR', 'Resumed', severity: 30);
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    anomalyDetector.stop();
    super.dispose();
  }
}
