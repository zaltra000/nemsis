import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import 'services/terminal_service.dart';
import 'services/system_monitor_service.dart';
import 'services/warfare_service.dart';
import 'services/c2_bridge_service.dart';
import 'screens/nuclear_arsenal_screen.dart';
import 'screens/operations_log_screen.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
const kNeonGreen = Color(0xFF00FF41);
const kDarkGreen = Color(0xFF003B00);
const kDeepBlack = Color(0xFF050505);
const kCardDark = Color(0xFF0D0D0D);
const kCardBorder = Color(0xFF1A1A1A);
const kCyan = Color(0xFF00E5FF);
const kOrange = Color(0xFFFF6D00);
const kRed = Color(0xFFFF1744);
const kPurple = Color(0xFFD500F9);

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TerminalService()),
        ChangeNotifierProvider(create: (_) => SystemMonitorService()),
        ChangeNotifierProvider(create: (_) => WarfareService()),
        ChangeNotifierProvider(create: (_) => C2BridgeService()),
      ],
      child: const NemesisApp(),
    ),
  );
}

class NemesisApp extends StatelessWidget {
  const NemesisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEMESIS CORE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kDeepBlack,
        textTheme: GoogleFonts.firaCodeTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainShell(),
    );
  }
}

// ─── Main Shell ─────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static void Function(int)? _onSwitchTab;
  static void switchToTab(int index) => _onSwitchTab?.call(index);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  final _labels = ['TERM', 'STATS', 'ARSENAL', 'OPS', 'QUICK'];
  final _icons = [
    Icons.terminal,
    Icons.monitor_heart_outlined,
    Icons.rocket_launch,
    Icons.history,
    Icons.grid_view_rounded,
  ];

  @override
  void initState() {
    super.initState();
    MainShell._onSwitchTab = (i) => setState(() => _index = i);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ─── Animated Top Bar ─────────────────────────────────
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 12,
                  left: 16,
                  right: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kDeepBlack,
                      Color.lerp(
                        kDeepBlack,
                        kDarkGreen,
                        _glowAnim.value * 0.3,
                      )!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: kNeonGreen.withAlpha(
                        (_glowAnim.value * 80).toInt(),
                      ),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kNeonGreen,
                        boxShadow: [
                          BoxShadow(
                            color: kNeonGreen.withAlpha(
                              (_glowAnim.value * 150).toInt(),
                            ),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'NEMESIS',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: kNeonGreen,
                        letterSpacing: 4,
                      ),
                    ),
                    Text(
                      ' CORE',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: kNeonGreen.withAlpha(150),
                        letterSpacing: 4,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: kNeonGreen.withAlpha(80)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'v7.7',
                        style: GoogleFonts.firaCode(
                          fontSize: 10,
                          color: kNeonGreen.withAlpha(180),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // ─── Body ─────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                TerminalScreen(),
                DashboardScreen(),
                NuclearArsenalScreen(),
                OperationsLogScreen(),
                ArsenalScreen(),
              ],
            ),
          ),
          // ─── Bottom Navigation ────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              border: Border(top: BorderSide(color: kNeonGreen.withAlpha(40))),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) => _navItem(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int i) {
    final selected = _index == i;
    return GestureDetector(
      onTap: () => setState(() => _index = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kNeonGreen.withAlpha(15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? kNeonGreen.withAlpha(60) : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[i],
              size: 20,
              color: selected ? kNeonGreen : Colors.grey.shade700,
            ),
            const SizedBox(height: 4),
            Text(
              _labels[i],
              style: GoogleFonts.firaCode(
                fontSize: 9,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? kNeonGreen : Colors.grey.shade700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Terminal Screen ────────────────────────────────────────────────────────
class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TerminalService>(context, listen: false);
    return Container(
      color: kDeepBlack,
      child: TerminalView(
        service.terminal,
        textStyle: TerminalStyle(
          fontSize: 13,
          fontFamily: GoogleFonts.firaCode().fontFamily!,
        ),
        theme: const TerminalTheme(
          cursor: kNeonGreen,
          selection: Color(0x4000FF41),
          foreground: kNeonGreen,
          background: kDeepBlack,
          black: Color(0xFF000000),
          red: Color(0xFFFF1744),
          green: Color(0xFF00FF41),
          yellow: Color(0xFFFFEA00),
          blue: Color(0xFF2979FF),
          magenta: Color(0xFFD500F9),
          cyan: Color(0xFF00E5FF),
          white: Color(0xFFE0E0E0),
          brightBlack: Color(0xFF616161),
          brightRed: Color(0xFFFF5252),
          brightGreen: Color(0xFF69F0AE),
          brightYellow: Color(0xFFFFFF00),
          brightBlue: Color(0xFF448AFF),
          brightMagenta: Color(0xFFE040FB),
          brightCyan: Color(0xFF18FFFF),
          brightWhite: Color(0xFFFFFFFF),
          searchHitBackground: Color(0xFF333300),
          searchHitBackgroundCurrent: Color(0xFF665500),
          searchHitForeground: Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}

// ─── Dashboard Screen ───────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<SystemMonitorService>().stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _GaugeCard(
                  label: 'CPU',
                  value: stats.cpu,
                  color: kCyan,
                  icon: Icons.memory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GaugeCard(
                  label: 'RAM',
                  value: stats.ram,
                  color: kPurple,
                  icon: Icons.storage,
                  subtitle:
                      '${stats.ramUsedGB.toStringAsFixed(1)} / ${stats.ramTotalGB.toStringAsFixed(1)} GB',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'NETWORK I/O', icon: Icons.swap_vert),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NetCard(
                  label: 'UPLOAD',
                  value: stats.netSent,
                  icon: Icons.arrow_upward,
                  color: kOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NetCard(
                  label: 'DOWNLOAD',
                  value: stats.netRecv,
                  icon: Icons.arrow_downward,
                  color: kCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'SYSTEM', icon: Icons.developer_board),
          const SizedBox(height: 12),
          // Platform-adaptive system info
          if (Platform.isAndroid) ...[
            const _AndroidInfoPanel(),
          ] else ...[
            const _InfoTile(
              icon: Icons.computer,
              label: 'HOSTNAME',
              cmd: 'hostname',
            ),
            const _InfoTile(
              icon: Icons.fingerprint,
              label: 'USER',
              cmd: 'whoami',
            ),
            const _InfoTile(
              icon: Icons.settings_system_daydream,
              label: 'KERNEL',
              cmd: 'uname -r',
            ),
            const _InfoTile(
              icon: Icons.timer,
              label: 'UPTIME',
              cmd: 'uptime -p',
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Android Info Panel (MethodChannel) ─────────────────────────────────────
class _AndroidInfoPanel extends StatefulWidget {
  const _AndroidInfoPanel();
  @override
  State<_AndroidInfoPanel> createState() => _AndroidInfoPanelState();
}

class _AndroidInfoPanelState extends State<_AndroidInfoPanel> {
  Map<String, String> _info = {};

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      final result = await const MethodChannel(
        'nemesis/stats',
      ).invokeMethod('getDeviceInfo');
      if (result is Map && mounted) {
        setState(() {
          _info = {
            'DEVICE': '${result['manufacturer']} ${result['model']}',
            'ANDROID': '${result['android']} (SDK ${result['sdk']})',
            'BOARD': '${result['board']}',
            'HARDWARE': '${result['hardware']}',
          };
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_info.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: kNeonGreen, strokeWidth: 2),
        ),
      );
    }
    return Column(
      children: _info.entries.map((e) => _buildTile(e.key, e.value)).toList(),
    );
  }

  Widget _buildTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android, size: 16, color: kNeonGreen.withAlpha(120)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.firaCode(
              fontSize: 10,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.firaCode(fontSize: 11, color: kNeonGreen),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kNeonGreen.withAlpha(180)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: kNeonGreen,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: kNeonGreen.withAlpha(30))),
      ],
    );
  }
}

// ─── Gauge Card ─────────────────────────────────────────────────────────────
class _GaugeCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String? subtitle;
  const _GaugeCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
        boxShadow: [BoxShadow(color: color.withAlpha(10), blurRadius: 12)],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(
              painter: _ArcPainter(value: value / 100, color: color),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color.withAlpha(180), size: 18),
                    const SizedBox(height: 2),
                    Text(
                      '${value.toStringAsFixed(1)}%',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.firaCode(
              fontSize: 11,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.firaCode(fontSize: 9, color: Colors.white38),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Arc Painter ────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double value;
  final Color color;
  _ArcPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()
      ..color = color.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 2.3,
        endAngle: 2.3 + (2 * pi * 0.75),
        colors: [color.withAlpha(100), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const startAngle = 2.3;
    const sweepFull = 2 * pi * 0.75;
    canvas.drawArc(rect.deflate(4), startAngle, sweepFull, false, bgPaint);
    canvas.drawArc(
      rect.deflate(4),
      startAngle,
      sweepFull * value.clamp(0, 1),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.value != value;
}

// ─── Format Bytes ───────────────────────────────────────────────────────────
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B/s';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB/s';
}

// ─── Network Card ───────────────────────────────────────────────────────────
class _NetCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _NetCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.firaCode(
                  fontSize: 9,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatBytes(value),
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Info Tile (Linux Only) ─────────────────────────────────────────────────
class _InfoTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String cmd;
  const _InfoTile({required this.icon, required this.label, required this.cmd});

  @override
  State<_InfoTile> createState() => _InfoTileState();
}

class _InfoTileState extends State<_InfoTile> {
  String _value = '...';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      // Use sh for both platforms (bash may not exist on Android)
      final result = await Process.run('sh', ['-c', widget.cmd]);
      if (mounted) setState(() => _value = result.stdout.toString().trim());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kCardBorder),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 16, color: kNeonGreen.withAlpha(120)),
          const SizedBox(width: 12),
          Text(
            widget.label,
            style: GoogleFonts.firaCode(
              fontSize: 10,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              _value,
              style: GoogleFonts.firaCode(fontSize: 11, color: kNeonGreen),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Arsenal Screen ─────────────────────────────────────────────────────────
class ArsenalScreen extends StatelessWidget {
  const ArsenalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TerminalService>(context, listen: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildModuleHeader('APEX: EXPLOIT ENGINE', kRed, Icons.bolt),
        _ToolCard(
          s: service,
          label: 'VULNERABILITY SCAN',
          desc: 'Identify zero-day entry points',
          icon: Icons.search,
          type: 'exploit',
          payload: {'target_id': 'local_net'},
          color: kRed,
        ),
        _ToolCard(
          s: service,
          label: 'PAYLOAD INJECTION',
          desc: 'Deliver malicious shellcode',
          icon: Icons.vibration,
          type: 'exploit',
          payload: {'action': 'inject'},
          color: kRed,
        ),
        const SizedBox(height: 24),
        _buildModuleHeader('GHOST: PERSISTENCE', kPurple, Icons.visibility_off),
        _ToolCard(
          s: service,
          label: 'KERNEL HOOK',
          desc: 'Achieve deep substrate persistence',
          icon: Icons.anchor,
          type: 'persistence',
          payload: {'level': 'kernel'},
          color: kPurple,
        ),
        _ToolCard(
          s: service,
          label: 'EVASION MASK',
          desc: 'Polymorphic signature scrambling',
          icon: Icons.masks,
          type: 'persistence',
          payload: {'action': 'scramble'},
          color: kPurple,
        ),
        const SizedBox(height: 24),
        _buildModuleHeader('BLACKOUT: SABOTAGE', kOrange, Icons.power_off),
        _ToolCard(
          s: service,
          label: 'DEVICE LOCKER',
          desc: 'Hard-lock target interface',
          icon: Icons.lock_person,
          type: 'exec',
          payload: {'cmd': 'am start -n com.android.settings/.DeviceAdminAdd'},
          color: kOrange,
        ),
        _ToolCard(
          s: service,
          label: 'THERMAL OVERLOAD',
          desc: 'Stress CPU/GPU to critical limits',
          icon: Icons.whatshot,
          type: 'exec',
          payload: {'cmd': 'while :; do :; done &'},
          color: kOrange,
        ),
        const SizedBox(height: 24),
        _buildModuleHeader('SIPHON: EXFILTRATION', kCyan, Icons.cloud_download),
        _ToolCard(
          s: service,
          label: 'ASSET SCAN',
          desc: 'Locate sensitive documents & keys',
          icon: Icons.find_in_page,
          type: 'siphon',
          payload: {'mode': 'recursive'},
          color: kCyan,
        ),
        _ToolCard(
          s: service,
          label: 'ENCRYPTED TUNNEL',
          desc: 'Establish stealth data pipeline',
          icon: Icons.vpn_lock,
          type: 'siphon',
          payload: {'tunnel': 'aes256'},
          color: kCyan,
        ),
      ],
    );
  }

  Widget _buildModuleHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: color.withAlpha(40))),
        ],
      ),
    );
  }
}

// ─── Tool Card ──────────────────────────────────────────────────────────────
class _ToolCard extends StatelessWidget {
  final TerminalService s;
  final String label;
  final String desc;
  final IconData icon;
  final String type;
  final Map<String, dynamic> payload;
  final Color color;
  const _ToolCard({
    required this.s,
    required this.label,
    required this.desc,
    required this.icon,
    required this.type,
    required this.payload,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Complex payload sending via WebSocket bridge
            final msg = json.encode({'type': type, ...payload});
            // We need a way to send raw JSON to the server via TerminalService
            // For now, let's assume we can use a special command or service call
            s.sendRaw(msg);
            MainShell.switchToTab(0);
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withAlpha(30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(30)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withAlpha(12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withAlpha(30)),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        desc,
                        style: GoogleFonts.firaCode(
                          fontSize: 10,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color.withAlpha(60), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
