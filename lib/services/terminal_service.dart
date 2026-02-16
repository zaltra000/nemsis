import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SystemStats {
  double cpu;
  double ram;
  int netSent;
  int netRecv;
  SystemStats({this.cpu = 0, this.ram = 0, this.netSent = 0, this.netRecv = 0});
}

class TerminalService extends ChangeNotifier {
  late final Terminal terminal;
  WebSocketChannel? _channel;
  bool _isConnected = false;
  SystemStats stats = SystemStats();

  bool get isConnected => _isConnected;

  TerminalService() {
    terminal = Terminal(maxLines: 10000);
    terminal.onOutput = (data) => sendInput(data);
    terminal.onResize = (rows, cols, width, height) => resize(rows, cols);
    connect();
  }

  void connect() {
    // Note: Using localhost for local execution. Use server IP for remote.
    final String url = 'ws://localhost:8080';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);

          if (data['type'] == 'output') {
            terminal.write(data['data']);
          } else if (data['type'] == 'telemetry') {
            stats.cpu = data['cpu'].toDouble();
            stats.ram = data['ram'].toDouble();
            stats.netSent = data['net_sent'];
            stats.netRecv = data['net_recv'];
            notifyListeners(); // Update Dashboard
          }
        },
        onDone: _disconnect,
        onError: (e) => _disconnect(),
      );
    } catch (e) {
      _disconnect();
    }
  }

  void _disconnect() {
    _isConnected = false;
    notifyListeners();
    // Reconnect after 5 seconds
    Timer(const Duration(seconds: 5), () => connect());
  }

  void sendInput(String input) {
    if (_isConnected) {
      _channel!.sink.add(jsonEncode({'type': 'input', 'data': input}));
    }
  }

  void sendCommand(String cmd) {
    if (_isConnected) {
      _channel!.sink.add(jsonEncode({'type': 'exec', 'cmd': cmd}));
    }
  }

  void resize(int rows, int cols) {
    if (_isConnected) {
      _channel!.sink.add(
        jsonEncode({'type': 'resize', 'rows': rows, 'cols': cols}),
      );
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
