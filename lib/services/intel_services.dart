import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'event_bus.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SIGINT — Signals Intelligence Service
/// WiFi, Bluetooth, Network traffic pattern analysis
/// ═══════════════════════════════════════════════════════════════════════════

class SignalEntry {
  final String type; // 'wifi', 'bluetooth', 'network'
  final String identifier;
  final String details;
  final int strength;
  final DateTime timestamp;

  SignalEntry({
    required this.type,
    required this.identifier,
    required this.details,
    this.strength = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SigintService extends ChangeNotifier {
  final EventBus eventBus;
  final List<SignalEntry> _signals = [];
  Timer? _scanTimer;
  bool _scanning = false;
  int _scanCount = 0;

  List<SignalEntry> get signals => List.unmodifiable(_signals);
  bool get scanning => _scanning;
  int get scanCount => _scanCount;

  SigintService({required EventBus eventBus}) : eventBus = eventBus;

  void startScan() {
    _scanning = true;
    _scanTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _collectSignals(),
    );
    _collectSignals();
    notifyListeners();
  }

  void stopScan() {
    _scanning = false;
    _scanTimer?.cancel();
    notifyListeners();
  }

  Future<void> _collectSignals() async {
    _scanCount++;
    try {
      // Network interfaces
      final ifResult = await Process.run('sh', [
        '-c',
        'ip -o link show 2>/dev/null | awk \'{print \$2}\'',
      ]);
      final interfaces = ifResult.stdout.toString().trim().split('\n');
      for (final iface in interfaces) {
        if (iface.isNotEmpty) {
          _addSignal(
            'network',
            iface.replaceAll(':', ''),
            'Network interface detected',
          );
        }
      }

      // Active connections with destinations
      final connResult = await Process.run('sh', [
        '-c',
        'ss -tn state established 2>/dev/null | awk \'NR>1{print \$5}\' | sort -u | head -10',
      ]);
      final dests = connResult.stdout.toString().trim().split('\n');
      for (final dest in dests) {
        if (dest.isNotEmpty) {
          _addSignal('network', dest, 'Active connection endpoint');
        }
      }
    } catch (_) {}
    notifyListeners();
  }

  void _addSignal(String type, String id, String details) {
    if (_signals.any((s) => s.identifier == id && s.type == type)) return;
    _signals.insert(
      0,
      SignalEntry(type: type, identifier: id, details: details),
    );
    if (_signals.length > 200) _signals.removeLast();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// OSINT — Open Source Intelligence Service
/// Domain recon, WHOIS, DNS, subdomain discovery
/// ═══════════════════════════════════════════════════════════════════════════

class OsintResult {
  final String type; // 'dns', 'whois', 'subdomain', 'port', 'email'
  final String target;
  final String data;
  final DateTime timestamp;

  OsintResult({
    required this.type,
    required this.target,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class OsintService extends ChangeNotifier {
  final EventBus _eventBus;
  final List<OsintResult> _results = [];
  bool _scanning = false;

  List<OsintResult> get results => List.unmodifiable(_results);
  bool get scanning => _scanning;

  OsintService({required EventBus eventBus}) : _eventBus = eventBus;

  Future<void> investigateTarget(String target) async {
    _scanning = true;
    notifyListeners();

    try {
      // DNS lookup
      final dnsResult = await Process.run('sh', [
        '-c',
        'host $target 2>/dev/null || nslookup $target 2>/dev/null',
      ]);
      _addResult('dns', target, dnsResult.stdout.toString().trim());

      // Reverse DNS
      final revResult = await Process.run('sh', [
        '-c',
        'host $target 2>/dev/null',
      ]);
      _addResult('reverse_dns', target, revResult.stdout.toString().trim());

      // WHOIS (if available)
      final whoisResult = await Process.run('sh', [
        '-c',
        'whois $target 2>/dev/null | head -30',
      ]);
      if (whoisResult.stdout.toString().trim().isNotEmpty) {
        _addResult('whois', target, whoisResult.stdout.toString().trim());
      }

      // Port check on common ports
      final portResult = await Process.run('sh', [
        '-c',
        'for port in 22 80 443 8080 3306 5432; do (echo > /dev/tcp/$target/\$port) 2>/dev/null && echo "Port \$port: OPEN"; done',
      ]);
      if (portResult.stdout.toString().trim().isNotEmpty) {
        _addResult('port', target, portResult.stdout.toString().trim());
      }
    } catch (_) {}

    _scanning = false;
    _eventBus.emit(
      NemesisEvent(
        type: NemesisEventType.scanComplete,
        source: 'OSINT',
        message:
            'OSINT scan complete for $target: ${_results.where((r) => r.target == target).length} findings',
        severity: 40,
      ),
    );
    notifyListeners();
  }

  void _addResult(String type, String target, String data) {
    if (data.isEmpty) return;
    _results.insert(0, OsintResult(type: type, target: target, data: data));
    if (_results.length > 200) _results.removeLast();
  }

  void clearResults() {
    _results.clear();
    notifyListeners();
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// HUMINT — Social Engineering Intelligence Engine
/// AI-driven pretext generation, target profiling
/// ═══════════════════════════════════════════════════════════════════════════

class HumintProfile {
  final String target;
  final Map<String, String> attributes;
  final List<String> attackVectors;
  final DateTime created;

  HumintProfile({
    required this.target,
    required this.attributes,
    required this.attackVectors,
    DateTime? created,
  }) : created = created ?? DateTime.now();
}

class HumintService extends ChangeNotifier {
  final EventBus _eventBus;
  final List<HumintProfile> _profiles = [];
  final List<String> _pretexts = [];

  List<HumintProfile> get profiles => List.unmodifiable(_profiles);
  List<String> get pretexts => List.unmodifiable(_pretexts);

  HumintService({required EventBus eventBus}) : _eventBus = eventBus;

  /// Generate a target profile
  HumintProfile profileTarget(
    String name, {
    String? role,
    String? org,
    String? email,
  }) {
    final profile = HumintProfile(
      target: name,
      attributes: {
        if (role != null) 'role': role,
        if (org != null) 'organization': org,
        if (email != null) 'email': email,
      },
      attackVectors: _suggestVectors(role, org),
    );
    _profiles.insert(0, profile);
    _eventBus.emit(
      NemesisEvent(
        type: NemesisEventType.targetProfiled,
        source: 'HUMINT',
        message: 'Target profiled: $name',
        severity: 50,
      ),
    );
    notifyListeners();
    return profile;
  }

  /// Generate pretext based on target info
  String generatePretext(String type, HumintProfile profile) {
    final templates = {
      'it_support':
          'Hello ${profile.target}, this is IT Support. We detected an issue with your account and need to verify your credentials for security purposes.',
      'password_reset':
          'URGENT: Your ${profile.attributes['organization'] ?? 'company'} password will expire in 24 hours. Click the link below to update it immediately.',
      'delivery':
          'Your package delivery for ${profile.attributes['organization'] ?? 'your organization'} requires signature verification. Click to confirm your details.',
      'executive':
          'Hi ${profile.target}, I need you to handle an urgent wire transfer. CEO ${profile.attributes['organization'] ?? 'Corp'} approved it. Details attached.',
      'vendor':
          'Dear ${profile.target}, our invoice #INV-2024-${DateTime.now().millisecondsSinceEpoch % 10000} is overdue. Please update payment information at the link below.',
    };

    final pretext = templates[type] ?? templates['it_support']!;
    _pretexts.insert(0, '[${type.toUpperCase()}] $pretext');
    notifyListeners();
    return pretext;
  }

  List<String> _suggestVectors(String? role, String? org) {
    final vectors = <String>['Email phishing', 'Phone vishing'];
    if (role != null) {
      if (role.toLowerCase().contains('admin') ||
          role.toLowerCase().contains('it')) {
        vectors.addAll([
          'Credential phishing via IT pretext',
          'MFA bypass via callback',
        ]);
      }
      if (role.toLowerCase().contains('exec') ||
          role.toLowerCase().contains('ceo')) {
        vectors.addAll(['BEC wire transfer', 'Executive impersonation']);
      }
      if (role.toLowerCase().contains('finance') ||
          role.toLowerCase().contains('account')) {
        vectors.addAll(['Invoice fraud', 'Payment redirect']);
      }
    }
    vectors.add('USB baiting');
    return vectors;
  }
}
