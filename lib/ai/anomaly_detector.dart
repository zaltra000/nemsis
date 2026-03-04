import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ANOMALY DETECTOR — Real-time Behavioral Analysis Engine
/// Detects suspicious activity across network, process, and filesystem
/// ═══════════════════════════════════════════════════════════════════════════

/// Types of anomalies detected
enum AnomalyType {
  networkSpike, // Unusual network traffic
  processAnomaly, // Suspicious process activity
  fileChange, // Unauthorized file modifications
  authFailure, // Authentication anomalies
  portScan, // Port scanning detected
  privEscAttempt, // Privilege escalation attempt
  dataExfil, // Data exfiltration pattern
  resourceAbuse, // CPU/RAM/Disk abuse
}

/// Severity levels
enum AnomalySeverity { info, low, medium, high, critical }

/// A detected anomaly
class Anomaly {
  final String id;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String description;
  final String details;
  final DateTime timestamp;
  bool acknowledged;

  Anomaly({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.details,
    this.acknowledged = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  int get severityScore {
    switch (severity) {
      case AnomalySeverity.critical:
        return 100;
      case AnomalySeverity.high:
        return 80;
      case AnomalySeverity.medium:
        return 50;
      case AnomalySeverity.low:
        return 25;
      case AnomalySeverity.info:
        return 10;
    }
  }
}

/// Baseline statistics for anomaly detection
class _Baseline {
  double avgCpu = 0;
  double avgRam = 0;
  int avgConnections = 0;
  int avgProcesses = 0;
  int sampleCount = 0;

  void update(double cpu, double ram, int connections, int processes) {
    sampleCount++;
    avgCpu = (avgCpu * (sampleCount - 1) + cpu) / sampleCount;
    avgRam = (avgRam * (sampleCount - 1) + ram) / sampleCount;
    avgConnections =
        ((avgConnections * (sampleCount - 1) + connections) / sampleCount)
            .round();
    avgProcesses =
        ((avgProcesses * (sampleCount - 1) + processes) / sampleCount).round();
  }
}

/// The Anomaly Detector: AI-driven threat detection
class AnomalyDetector extends ChangeNotifier {
  final List<Anomaly> _anomalies = [];
  final _Baseline _baseline = _Baseline();
  Timer? _monitorTimer;
  bool _running = false;
  int _scanCount = 0;

  // Thresholds
  static const double _connThreshold = 3.0; // 3x baseline connections

  List<Anomaly> get anomalies => List.unmodifiable(_anomalies);
  List<Anomaly> get unacknowledged =>
      _anomalies.where((a) => !a.acknowledged).toList();
  bool get running => _running;
  int get scanCount => _scanCount;
  int get criticalCount => _anomalies
      .where((a) => a.severity == AnomalySeverity.critical && !a.acknowledged)
      .length;

  /// Start the anomaly detection engine
  void start({Duration interval = const Duration(seconds: 10)}) {
    if (_running) return;
    _running = true;
    notifyListeners();

    _monitorTimer = Timer.periodic(interval, (_) => _scan());
  }

  /// Stop the detection engine
  void stop() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _running = false;
    notifyListeners();
  }

  /// Run a single scan cycle
  Future<void> _scan() async {
    _scanCount++;

    try {
      await Future.wait([
        _checkNetworkActivity(),
        _checkProcesses(),
        _checkAuthLogs(),
        _checkListeningPorts(),
      ]);
    } catch (_) {}

    notifyListeners();
  }

  /// Check network activity for anomalies
  Future<void> _checkNetworkActivity() async {
    try {
      final result = await Process.run('sh', [
        '-c',
        'ss -tn state established 2>/dev/null | wc -l',
      ]);
      final connections = int.tryParse(result.stdout.toString().trim()) ?? 0;

      // Update baseline
      _baseline.update(0, 0, connections, 0);

      // Check for anomalies
      if (_baseline.sampleCount > 5 &&
          connections > _baseline.avgConnections * _connThreshold) {
        _addAnomaly(
          AnomalyType.networkSpike,
          AnomalySeverity.high,
          'Network connection spike: $connections active (baseline: ${_baseline.avgConnections})',
          'Established connections surged to ${(connections / max(_baseline.avgConnections, 1) * 100).toStringAsFixed(0)}% of baseline',
        );
      }
    } catch (_) {}
  }

  /// Check for suspicious processes
  Future<void> _checkProcesses() async {
    try {
      // Check for common attack tools
      final suspiciousProcs = [
        'nmap',
        'hydra',
        'john',
        'hashcat',
        'msfconsole',
        'aircrack',
        'ettercap',
        'tcpdump',
        'wireshark',
        'netcat',
      ];

      final result = await Process.run('sh', ['-c', 'ps aux 2>/dev/null']);
      final output = result.stdout.toString().toLowerCase();

      for (final proc in suspiciousProcs) {
        if (output.contains(proc)) {
          _addAnomaly(
            AnomalyType.processAnomaly,
            AnomalySeverity.medium,
            'Suspicious process detected: $proc',
            'Security tool "$proc" is running. This may indicate active reconnaissance or attack.',
          );
        }
      }

      // Check for high CPU processes
      final cpuResult = await Process.run('sh', [
        '-c',
        'ps aux --sort=-%cpu 2>/dev/null | awk \'NR>1 && \$3>80{print \$11, \$3}\' | head -3',
      ]);
      final highCpu = cpuResult.stdout.toString().trim();
      if (highCpu.isNotEmpty) {
        _addAnomaly(
          AnomalyType.resourceAbuse,
          AnomalySeverity.medium,
          'High CPU usage detected',
          'Processes consuming >80% CPU:\n$highCpu',
        );
      }
    } catch (_) {}
  }

  /// Check authentication logs
  Future<void> _checkAuthLogs() async {
    try {
      final result = await Process.run('sh', [
        '-c',
        'grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0"',
      ]);
      final failures = int.tryParse(result.stdout.toString().trim()) ?? 0;

      if (failures > 10) {
        _addAnomaly(
          AnomalyType.authFailure,
          failures > 50 ? AnomalySeverity.critical : AnomalySeverity.high,
          'Authentication failures detected: $failures',
          'Multiple failed login attempts detected in auth.log. Possible brute force attack.',
        );
      }
    } catch (_) {}
  }

  /// Check for suspicious listening ports
  Future<void> _checkListeningPorts() async {
    try {
      final result = await Process.run('sh', [
        '-c',
        'ss -tlnp 2>/dev/null | grep -v "127.0.0.1" | tail -n +2',
      ]);
      final output = result.stdout.toString().trim();
      final lines = output.split('\n').where((l) => l.isNotEmpty);

      // Check for common backdoor ports
      final suspiciousPorts = [
        4444,
        5555,
        1337,
        31337,
        6666,
        6667,
        9999,
        12345,
      ];
      for (final line in lines) {
        for (final port in suspiciousPorts) {
          if (line.contains(':$port ')) {
            _addAnomaly(
              AnomalyType.portScan,
              AnomalySeverity.high,
              'Suspicious port $port is listening',
              'Port $port is commonly associated with backdoors/RATs.\nDetails: $line',
            );
          }
        }
      }
    } catch (_) {}
  }

  /// Add a new anomaly (deduplicated)
  void _addAnomaly(
    AnomalyType type,
    AnomalySeverity severity,
    String desc,
    String details,
  ) {
    // Deduplicate: don't add if same type+description already exists within 5 minutes
    final existing = _anomalies.any(
      (a) =>
          a.type == type &&
          a.description == desc &&
          DateTime.now().difference(a.timestamp).inMinutes < 5,
    );
    if (existing) return;

    _anomalies.insert(
      0,
      Anomaly(
        id: '${DateTime.now().millisecondsSinceEpoch}_${type.name}',
        type: type,
        severity: severity,
        description: desc,
        details: details,
      ),
    );

    // Cap at 200 entries
    while (_anomalies.length > 200) {
      _anomalies.removeLast();
    }
  }

  void acknowledgeAll() {
    for (final a in _anomalies) {
      a.acknowledged = true;
    }
    notifyListeners();
  }

  void clearAll() {
    _anomalies.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }
}
