import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import '../constants/mobile_constants.dart';
import '../utils/responsive.dart';

class MobileOptimizedTerminal extends StatefulWidget {
  final Terminal terminal;
  final VoidCallback? onKeyboardToggle;
  final VoidCallback? onClearScreen;

  const MobileOptimizedTerminal({
    super.key,
    required this.terminal,
    this.onKeyboardToggle,
    this.onClearScreen,
  });

  @override
  State<MobileOptimizedTerminal> createState() => _MobileOptimizedTerminalState();
}

class _MobileOptimizedTerminalState extends State<MobileOptimizedTerminal> {
  double _fontSize = 13.0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final padding = ResponsiveUtils.getAdaptivePadding(context);
    
    return Column(
      children: [
        // Mobile toolbar
        if (isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: MobileConstants.cardBackground,
              border: Border(
                bottom: BorderSide(
                  color: MobileConstants.matrixGreen.withAlpha(50),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolbarButton(
                  icon: Icons.keyboard,
                  onPressed: widget.onKeyboardToggle ?? _showKeyboard,
                  tooltip: 'Keyboard',
                ),
                _buildToolbarButton(
                  icon: Icons.add,
                  onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(10.0, 20.0)),
                  tooltip: 'Zoom In',
                ),
                _buildToolbarButton(
                  icon: Icons.remove,
                  onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(10.0, 20.0)),
                  tooltip: 'Zoom Out',
                ),
                _buildToolbarButton(
                  icon: Icons.clear,
                  onPressed: widget.onClearScreen,
                  tooltip: 'Clear',
                ),
              ],
            ),
          ),
        // Terminal view
        Expanded(
          child: Padding(
            padding: padding,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showKeyboard,
              child: TerminalView(
                widget.terminal,
                backgroundOpacity: 0,
                focusNode: _focusNode,
                autofocus: true,
                textStyle: TerminalStyle(
                  fontFamily: 'FiraCode',
                  fontSize:
                      ResponsiveUtils.getAdaptiveFontSize(context, _fontSize),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showKeyboard() {
    _focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: 20,
        color: MobileConstants.matrixGreen,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
    );
  }
}
