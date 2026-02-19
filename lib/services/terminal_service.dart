import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/mobile_constants.dart';
import '../utils/responsive.dart';

class SystemStats {
  double cpu;
  double ram;
  int netSent;
  int netRecv;
  SystemStats({this.cpu = 0, this.ram = 0, this.netSent = 0, this.netRecv = 0});
}

class TerminalService extends ChangeNotifier with WidgetsBindingObserver {
  late final Terminal terminal;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;
  bool _isConnected = false;
  bool _isInBackground = false;
  SystemStats stats = SystemStats();
  Timer? _reconnectTimer;
  Timer? _telemetryThrottleTimer;
  DateTime? _lastTelemetryUpdate;
  
  static const Duration _telemetryThrottleDuration = Duration(milliseconds: 500);
  static const Duration _backgroundReconnectDelay = Duration(seconds: 30);

  bool get isConnected => _isConnected;

  TerminalService() {
    WidgetsBinding.instance.addObserver(this);
    _initializeTerminal();
    connect();
  }
  
  void _initializeTerminal() {
    // Get adaptive maxLines based on platform capabilities
    final maxLines = _getAdaptiveMaxLines();
    terminal = Terminal(maxLines: maxLines);
    terminal.onOutput = (data) => sendInput(data);
    terminal.onResize = (rows, cols, width, height) => resize(rows, cols);
  }
  
  int _getAdaptiveMaxLines() {
    // This will be determined at runtime based on device capabilities
    // For now, use conservative values
    if (kIsWeb) return MobileConstants.desktopTerminalMaxLines;
    // For mobile, we'll detect in the widget layer and pass to service
    return MobileConstants.mobileTerminalMaxLines;
  }
  
  void setAdaptiveMaxLines(BuildContext context) {
    final maxLines = ResponsiveUtils.isMobile(context) 
        ? MobileConstants.mobileTerminalMaxLines
        : ResponsiveUtils.isTablet(context)
            ? MobileConstants.tabletTerminalMaxLines
            : MobileConstants.desktopTerminalMaxLines;
    
    // Note: xterm's maxLines is set at creation, 
    // but we can clear buffer if it gets too large
    if (terminal.buffer.height > maxLines) {
      terminal.buffer.clear();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isInBackground = true;
        // Reduce telemetry frequency when in background
        _throttleTelemetry();
        break;
      case AppLifecycleState.resumed:
        _isInBackground = false;
        // Resume normal telemetry and check connection
        if (!_isConnected) {
          _scheduleReconnect(delay: const Duration(seconds: 1));
        }
        break;
      case AppLifecycleState.detached:
        dispose();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state (new in Flutter 3.13+)
        _isInBackground = true;
        break;
    }
  }
  
  void _throttleTelemetry() {
    // Telemetry updates are now throttled in the message handler
    _isInBackground = true;
  }

  void connect() {
    // Cancel any pending reconnect timer
    _reconnectTimer?.cancel();
    _channelSub?.cancel();
    
    // Note: Using localhost for local execution. Use server IP for remote.
    final String url = 'ws://localhost:8080';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _isConnected = true;
      _isInBackground = false;
      notifyListeners();

      _channelSub = _channel!.stream.listen(
        (message) {
          Map<String, dynamic> data;
          try {
            data = jsonDecode(message) as Map<String, dynamic>;
          } catch (_) {
            return;
          }

          if (data['type'] == 'output') {
            final out = data['data'];
            if (out is String) {
              terminal.write(out);
            }
          } else if (data['type'] == 'telemetry') {
            _handleTelemetryUpdate(data);
          }
        },
        onDone: _disconnect,
        onError: (_) => _disconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      _disconnect();
    }
  }
  
  void _handleTelemetryUpdate(Map<String, dynamic> data) {
    // Throttle telemetry updates to improve performance
    final now = DateTime.now();
    if (_lastTelemetryUpdate != null) {
      final elapsed = now.difference(_lastTelemetryUpdate!);
      if (elapsed < _telemetryThrottleDuration) {
        // Skip this update if it's too soon
        return;
      }
    }
    
    _lastTelemetryUpdate = now;
    stats.cpu = data['cpu'].toDouble();
    stats.ram = data['ram'].toDouble();
    stats.netSent = data['net_sent'];
    stats.netRecv = data['net_recv'];
    notifyListeners(); // Update Dashboard
  }

  void _disconnect() {
    _isConnected = false;
    notifyListeners();
    
    // Use adaptive reconnect delay based on app state
    final delay = _isInBackground 
        ? _backgroundReconnectDelay 
        : const Duration(seconds: 5);
    
    _scheduleReconnect(delay: delay);
  }
  
  void _scheduleReconnect({required Duration delay}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isConnected) {
        connect();
      }
    });
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
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _telemetryThrottleTimer?.cancel();
    _channelSub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
