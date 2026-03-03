import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SystemStats {
  double cpu;
  double ram;
  double ramUsedGB;
  double ramTotalGB;
  int netSent;
  int netRecv;

  SystemStats({
    this.cpu = 0,
    this.ram = 0,
    this.ramUsedGB = 0,
    this.ramTotalGB = 0,
    this.netSent = 0,
    this.netRecv = 0,
  });
}

class SystemMonitorService extends ChangeNotifier {
  SystemStats stats = SystemStats();
  Timer? _timer;

  // For Linux /proc delta calculation
  int _prevIdle = 0;
  int _prevTotal = 0;
  int _prevNetSent = 0;
  int _prevNetRecv = 0;

  // For Android TrafficStats delta
  int _prevAndroidRx = 0;
  int _prevAndroidTx = 0;

  static const _channel = MethodChannel('nemesis/stats');

  SystemMonitorService() {
    _pollStats();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _pollStats());
  }

  Future<void> _pollStats() async {
    try {
      if (Platform.isAndroid) {
        await _readAndroidStats();
      } else {
        await Future.wait([
          _readLinuxCpu(),
          _readLinuxRam(),
          _readLinuxNetwork(),
        ]);
      }
      notifyListeners();
    } catch (_) {}
  }

  // ─── Android: MethodChannel ────────────────────────────────────────────────
  Future<void> _readAndroidStats() async {
    try {
      final result = await _channel.invokeMethod('getStats');
      if (result is Map) {
        // RAM
        final totalMem = (result['ramTotal'] as num?)?.toDouble() ?? 0;
        final availMem = (result['ramAvailable'] as num?)?.toDouble() ?? 0;
        if (totalMem > 0) {
          final usedMem = totalMem - availMem;
          stats.ram = (usedMem / totalMem) * 100;
          stats.ramUsedGB = usedMem / 1024 / 1024 / 1024;
          stats.ramTotalGB = totalMem / 1024 / 1024 / 1024;
        }

        // CPU
        stats.cpu = (result['cpu'] as num?)?.toDouble() ?? 0;

        // Network (TrafficStats total bytes → rate)
        final rx = (result['netRx'] as num?)?.toInt() ?? 0;
        final tx = (result['netTx'] as num?)?.toInt() ?? 0;
        if (_prevAndroidRx > 0) {
          stats.netRecv = ((rx - _prevAndroidRx) / 2).round().abs();
          stats.netSent = ((tx - _prevAndroidTx) / 2).round().abs();
        }
        _prevAndroidRx = rx;
        _prevAndroidTx = tx;
      }
    } catch (_) {}
  }

  // ─── Linux: /proc filesystem ───────────────────────────────────────────────
  Future<void> _readLinuxCpu() async {
    try {
      final content = await File('/proc/stat').readAsString();
      final firstLine = content.split('\n').first;
      final parts = firstLine
          .split(RegExp(r'\s+'))
          .skip(1)
          .map(int.parse)
          .toList();

      final idle = parts[3];
      final total = parts.fold<int>(0, (a, b) => a + b);

      if (_prevTotal > 0) {
        final deltaTotal = total - _prevTotal;
        final deltaIdle = idle - _prevIdle;
        stats.cpu = deltaTotal > 0
            ? ((deltaTotal - deltaIdle) / deltaTotal * 100)
            : 0;
      }

      _prevIdle = idle;
      _prevTotal = total;
    } catch (_) {}
  }

  Future<void> _readLinuxRam() async {
    try {
      final content = await File('/proc/meminfo').readAsString();
      final lines = content.split('\n');

      int memTotal = 0, memAvailable = 0;
      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          memTotal = int.parse(line.split(RegExp(r'\s+'))[1]);
        } else if (line.startsWith('MemAvailable:')) {
          memAvailable = int.parse(line.split(RegExp(r'\s+'))[1]);
        }
      }

      if (memTotal > 0) {
        final used = memTotal - memAvailable;
        stats.ram = (used / memTotal) * 100;
        stats.ramUsedGB = used / 1024 / 1024;
        stats.ramTotalGB = memTotal / 1024 / 1024;
      }
    } catch (_) {}
  }

  Future<void> _readLinuxNetwork() async {
    try {
      final content = await File('/proc/net/dev').readAsString();
      final lines = content.split('\n').skip(2);

      int totalRecv = 0, totalSent = 0;
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('lo:')) continue;
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 10) {
          totalRecv += int.tryParse(parts[1]) ?? 0;
          totalSent += int.tryParse(parts[9]) ?? 0;
        }
      }

      if (_prevNetRecv > 0) {
        stats.netRecv = ((totalRecv - _prevNetRecv) / 2).round();
        stats.netSent = ((totalSent - _prevNetSent) / 2).round();
      }

      _prevNetRecv = totalRecv;
      _prevNetSent = totalSent;
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
