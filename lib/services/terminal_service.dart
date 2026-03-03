import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_pty/flutter_pty.dart';

class TerminalService extends ChangeNotifier {
  late final Terminal terminal;
  late final Pty _pty;

  TerminalService() {
    terminal = Terminal(maxLines: 10000);

    // Platform-adaptive shell
    final shell = Platform.isAndroid
        ? '/system/bin/sh'
        : (Platform.environment['SHELL'] ?? 'bash');

    _pty = Pty.start(
      shell,
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
    );

    // PTY output → Terminal display
    _pty.output.cast<List<int>>().transform(const Utf8Decoder()).listen((data) {
      terminal.write(data);
    });

    // Terminal user input → PTY stdin
    terminal.onOutput = (data) {
      _pty.write(const Utf8Encoder().convert(data));
    };

    // Terminal resize → PTY resize
    terminal.onResize = (newWidth, newHeight, pixelWidth, pixelHeight) {
      _pty.resize(newHeight, newWidth);
    };

    // Handle PTY exit
    _pty.exitCode.then((code) {
      terminal.write(
        '\r\n\x1B[1;31m[NEMESIS] Shell exited with code $code\x1B[0m\r\n',
      );
      notifyListeners();
    });

    notifyListeners();
  }

  void sendCommand(String cmd) {
    _pty.write(const Utf8Encoder().convert('$cmd\n'));
  }

  void sendRaw(String jsonMsg) {
    // In a full implementation, this would send over the WebSocket to the NEMESIS server.
    // For the current nuclear synthesis, we bridge it through the PTY to trigger backend logic.
    // Use a special prefix that the backend/bridge can intercept.
    _pty.write(const Utf8Encoder().convert('###NEMESIS_BRIDGE###$jsonMsg\n'));
  }

  @override
  void dispose() {
    _pty.kill();
    super.dispose();
  }
}
