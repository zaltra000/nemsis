import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xterm/xterm.dart';
import 'services/terminal_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TerminalService(),
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
        scaffoldBackgroundColor: const Color(0xFF050505),
        textTheme: GoogleFonts.firaCodeTextTheme(ThemeData.dark().textTheme),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0A0A),
          selectedItemColor: Color(0xFF00FF41),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainControlScreen(),
    );
  }
}

class MainControlScreen extends StatefulWidget {
  const MainControlScreen({super.key});
  @override
  State<MainControlScreen> createState() => _MainControlScreenState();
}

class _MainControlScreenState extends State<MainControlScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const TerminalScreen(),
    const DashboardScreen(),
    const ToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          'NEMESIS_EVOLUTION v7.7',
          style: GoogleFonts.outfit(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00FF41),
          ),
        ),
        actions: [_StatusIndicator()],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.terminal),
            label: 'TERMINAL',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'STATS'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'ARSENAL',
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final connected = context.watch<TerminalService>().isConnected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? const Color(0xFF00FF41) : Colors.red,
              boxShadow: [
                BoxShadow(
                  color: (connected ? const Color(0xFF00FF41) : Colors.red)
                      .withAlpha(100),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            connected ? 'ONLINE' : 'OFFLINE',
            style: GoogleFonts.firaCode(
              fontSize: 10,
              color: connected ? const Color(0xFF00FF41) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TerminalService>(context);
    return Container(
      padding: const EdgeInsets.all(8),
      child: TerminalView(
        service.terminal,
        backgroundOpacity: 0,
        textStyle: const TerminalStyle(fontFamily: 'FiraCode', fontSize: 13),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TerminalService>().stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroStat("CPU LOAD", stats.cpu, Colors.redAccent),
          const SizedBox(height: 24),
          _buildHeroStat("RAM USAGE", stats.ram, Colors.blueAccent),
          const SizedBox(height: 32),
          Text(
            "NETWORK TRAFFIC",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00FF41),
            ),
          ),
          const SizedBox(height: 16),
          _NetStatRow(
            label: "TX (SENT)",
            value: "${(stats.netSent / 1024).toStringAsFixed(2)} KB",
            color: Colors.orangeAccent,
          ),
          _NetStatRow(
            label: "RX (RECV)",
            value: "${(stats.netRecv / 1024).toStringAsFixed(2)} KB",
            color: Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            Text(
              "${value.toStringAsFixed(1)}%",
              style: GoogleFonts.firaCode(color: color),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            backgroundColor: Colors.white10,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _NetStatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _NetStatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.firaCode(fontSize: 12, color: Colors.grey),
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TerminalService>(context, listen: false);
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(24),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _toolBtn(
          service,
          "NET SCAN",
          Icons.radar,
          "sudo nmap -T4 -F localhost",
        ),
        _toolBtn(service, "WHOAMI", Icons.person_search, "whoami && id"),
        _toolBtn(service, "SYS INFO", Icons.info_outline, "uname -a"),
        _toolBtn(
          service,
          "PROCESS INFO",
          Icons.list_alt,
          "ps aux --sort=-%mem | head -5",
        ),
        _toolBtn(service, "NET STATUS", Icons.network_check, "ss -tulpn"),
        _toolBtn(
          service,
          "LOG VIEW",
          Icons.history,
          "tail -n 20 /var/log/syslog",
        ),
      ],
    );
  }

  Widget _toolBtn(TerminalService s, String label, IconData icon, String cmd) {
    return Material(
      color: const Color(0xFF111111),
      child: InkWell(
        onTap: () => s.sendCommand(cmd),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00FF41).withAlpha(50)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: const Color(0xFF00FF41)),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
