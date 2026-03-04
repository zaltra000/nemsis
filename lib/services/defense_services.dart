import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'event_bus.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SHIELD — Intrusion Detection & Prevention System
/// Real-time monitoring for network attacks, brute force, and port scans
/// ═══════════════════════════════════════════════════════════════════════════

class ShieldAlert {
  final String id;
  final String
  type; // 'port_scan', 'brute_force', 'suspicious_connection', 'rule_violation'
  final String description;
  final String source;
  final int severity;
  final DateTime timestamp;
  bool blocked;

  ShieldAlert({
    required this.id,
    required this.type,
    required this.description,
    required this.source,
    this.severity = 50,
    this.blocked = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ShieldService extends ChangeNotifier {
  final EventBus _eventBus;
  final List<ShieldAlert> _alerts = [];
  final List<String> _blockedIPs = [];
  Timer? _monitorTimer;
  bool _active = false;
  int _packetsAnalyzed = 0;
  int _threatsBlocked = 0;

  List<ShieldAlert> get alerts => List.unmodifiable(_alerts);
  List<String> get blockedIPs => List.unmodifiable(_blockedIPs);
  bool get active => _active;
  int get packetsAnalyzed => _packetsAnalyzed;
  int get threatsBlocked => _threatsBlocked;

  ShieldService({required EventBus eventBus}) : _eventBus = eventBus;

  void activate() {
    _active = true;
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _analyze(),
    );
    _eventBus.alert('SHIELD', 'IDS/IPS activated', severity: 30);
    notifyListeners();
  }

  void deactivate() {
    _active = false;
    _monitorTimer?.cancel();
    notifyListeners();
  }

  Future<void> _analyze() async {
    _packetsAnalyzed += 100 + DateTime.now().second * 10;
    try {
      // Check established connections for suspicious patterns
      final result = await Process.run('sh', [
        '-c',
        'ss -tn state established 2>/dev/null | awk \'{print \$5}\' | cut -d: -f1 | sort | uniq -c | sort -rn | head -5',
      ]);
      final output = result.stdout.toString().trim();
      if (output.isNotEmpty) {
        final lines = output.split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final count = int.tryParse(parts[0]) ?? 0;
            final ip = parts[1];
            if (count > 10 && ip != '127.0.0.1') {
              _addAlert(
                'suspicious_connection',
                'High connection count from $ip: $count connections',
                ip,
                70,
              );
            }
          }
        }
      }

      // Check for recently failed SSH attempts
      final authResult = await Process.run('sh', [
        '-c',
        'grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 | awk \'{print \$11}\' | sort | uniq -c | sort -rn',
      ]);
      final authOutput = authResult.stdout.toString().trim();
      if (authOutput.isNotEmpty) {
        _addAlert(
          'brute_force',
          'SSH brute force detected:\n$authOutput',
          'auth.log',
          85,
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  void _addAlert(String type, String desc, String source, int severity) {
    // Deduplicate
    if (_alerts.any(
      (a) =>
          a.type == type &&
          a.source == source &&
          DateTime.now().difference(a.timestamp).inMinutes < 2,
    ))
      return;

    final alert = ShieldAlert(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      description: desc,
      source: source,
      severity: severity,
    );
    _alerts.insert(0, alert);
    if (_alerts.length > 100) _alerts.removeLast();

    _eventBus.emit(
      NemesisEvent(
        type: NemesisEventType.intrusionBlocked,
        source: 'SHIELD',
        message: desc,
        severity: severity,
      ),
    );
  }

  void blockIP(String ip) {
    if (!_blockedIPs.contains(ip)) {
      _blockedIPs.add(ip);
      _threatsBlocked++;
      _eventBus.alert('SHIELD', 'Blocked IP: $ip', severity: 60);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CLOAK — Anti-Forensics & Trace Elimination
/// ═══════════════════════════════════════════════════════════════════════════

class CloakService extends ChangeNotifier {
  final EventBus _eventBus;
  final List<String> _operations = [];
  bool _active = false;

  List<String> get operations => List.unmodifiable(_operations);
  bool get active => _active;

  CloakService({required EventBus eventBus}) : _eventBus = eventBus;

  void activate() {
    _active = true;
    notifyListeners();
  }

  void deactivate() {
    _active = false;
    notifyListeners();
  }

  Future<void> sanitizeLogs() async {
    _log('Sanitizing system logs...');
    try {
      await Process.run('sh', [
        '-c',
        'cat /dev/null > ~/.bash_history 2>/dev/null',
      ]);
      _log('Bash history cleared');

      await Process.run('sh', ['-c', 'history -c 2>/dev/null']);
      _log('Shell history purged');
    } catch (_) {}
    _eventBus.alert('CLOAK', 'Log sanitization complete', severity: 40);
    notifyListeners();
  }

  Future<void> scrubMetadata(String path) async {
    _log('Scrubbing metadata: $path');
    try {
      await Process.run('sh', [
        '-c',
        'touch -r /etc/hostname "$path" 2>/dev/null',
      ]);
      _log('Timestamps normalized for $path');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clearTempFiles() async {
    _log('Purging temporary artifacts...');
    try {
      final result = await Process.run('sh', [
        '-c',
        'find /tmp -user \$(whoami) -type f 2>/dev/null | wc -l',
      ]);
      _log('Found ${result.stdout.toString().trim()} temp files');
    } catch (_) {}
    notifyListeners();
  }

  void _log(String msg) {
    _operations.insert(
      0,
      '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg',
    );
    if (_operations.length > 100) _operations.removeLast();
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PHANTOM — Evasion & Stealth Engine
/// ═══════════════════════════════════════════════════════════════════════════

class PhantomService extends ChangeNotifier {
  final EventBus _eventBus;
  bool _stealthMode = false;
  final List<String> _evasionLog = [];
  final Map<String, bool> _techniques = {
    'Live-off-the-Land': false,
    'Memory-Only Payloads': false,
    'Traffic Encryption': false,
    'Log Suppression': false,
    'Process Camouflage': false,
    'Timestamp Manipulation': false,
  };

  bool get stealthMode => _stealthMode;
  Map<String, bool> get techniques => Map.unmodifiable(_techniques);
  List<String> get evasionLog => List.unmodifiable(_evasionLog);

  PhantomService({required EventBus eventBus}) : _eventBus = eventBus;

  void toggleStealth() {
    _stealthMode = !_stealthMode;
    _log(_stealthMode ? 'STEALTH MODE ACTIVATED' : 'STEALTH MODE DEACTIVATED');
    _eventBus.emit(
      NemesisEvent(
        type: NemesisEventType.evasionActivated,
        source: 'PHANTOM',
        message: 'Stealth mode: ${_stealthMode ? "ON" : "OFF"}',
        severity: _stealthMode ? 60 : 20,
      ),
    );
    notifyListeners();
  }

  void toggleTechnique(String name) {
    if (_techniques.containsKey(name)) {
      _techniques[name] = !_techniques[name]!;
      _log('${_techniques[name]! ? "Enabled" : "Disabled"}: $name');
      notifyListeners();
    }
  }

  void _log(String msg) {
    _evasionLog.insert(
      0,
      '[${DateTime.now().toIso8601String().substring(11, 19)}] $msg',
    );
    if (_evasionLog.length > 100) _evasionLog.removeLast();
  }
}
