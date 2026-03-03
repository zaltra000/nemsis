import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Represents the status of an offensive operation
enum OpStatus { idle, running, success, failed }

/// A single offensive operation result
class OpResult {
  final String module;
  final String tool;
  final String output;
  final OpStatus status;
  final DateTime timestamp;

  OpResult({
    required this.module,
    required this.tool,
    required this.output,
    required this.status,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// WarfareService: Manages offensive operations, history, and tool execution
class WarfareService extends ChangeNotifier {
  final List<OpResult> _history = [];
  OpStatus _currentStatus = OpStatus.idle;
  String _currentModule = '';
  String _currentTool = '';

  List<OpResult> get history => List.unmodifiable(_history);
  OpStatus get currentStatus => _currentStatus;
  String get currentModule => _currentModule;
  String get currentTool => _currentTool;

  /// Execute a shell command and return the result
  Future<OpResult> executeShellTool({
    required String module,
    required String tool,
    required String command,
  }) async {
    _currentStatus = OpStatus.running;
    _currentModule = module;
    _currentTool = tool;
    notifyListeners();

    try {
      final result = await Process.run('sh', ['-c', command]);
      final output = result.stdout.toString().trim();
      final error = result.stderr.toString().trim();

      final op = OpResult(
        module: module,
        tool: tool,
        output: output.isNotEmpty
            ? output
            : (error.isNotEmpty ? error : '[No output]'),
        status: result.exitCode == 0 ? OpStatus.success : OpStatus.failed,
      );

      _history.insert(0, op);
      _currentStatus = op.status;
      notifyListeners();
      return op;
    } catch (e) {
      final op = OpResult(
        module: module,
        tool: tool,
        output: 'ERROR: $e',
        status: OpStatus.failed,
      );
      _history.insert(0, op);
      _currentStatus = OpStatus.failed;
      notifyListeners();
      return op;
    }
  }

  /// Execute a tool that sends output directly to the terminal
  void executeTerminalTool({
    required String module,
    required String tool,
    required String command,
    required void Function(String) sendCommand,
  }) {
    _currentStatus = OpStatus.running;
    _currentModule = module;
    _currentTool = tool;
    notifyListeners();

    sendCommand(command);

    final op = OpResult(
      module: module,
      tool: tool,
      output: '[Sent to terminal] $command',
      status: OpStatus.success,
    );
    _history.insert(0, op);
    _currentStatus = OpStatus.success;
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
