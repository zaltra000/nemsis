import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/intel_services.dart';
import '../main.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// INTEL SCREEN — SIGINT + OSINT + HUMINT interfaces
/// ═══════════════════════════════════════════════════════════════════════════
class IntelScreen extends StatefulWidget {
  const IntelScreen({super.key});
  @override
  State<IntelScreen> createState() => _IntelScreenState();
}

class _IntelScreenState extends State<IntelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _targetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabCtrl,
            dividerColor: Colors.transparent,
            indicatorColor: kCyan,
            labelColor: kCyan,
            unselectedLabelColor: Colors.white30,
            labelStyle: GoogleFonts.orbitron(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            tabs: const [
              Tab(text: 'SIGINT'),
              Tab(text: 'OSINT'),
              Tab(text: 'HUMINT'),
            ],
          ),
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _SigintTab(),
              _OsintTab(targetCtrl: _targetCtrl),
              _HumintTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SIGINT Tab ─────────────────────────────────────────────────────────────
class _SigintTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sigint = context.watch<SigintService>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Signals Intelligence',
                  style: GoogleFonts.firaCode(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    sigint.scanning ? sigint.stopScan() : sigint.startScan(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (sigint.scanning ? kRed : kCyan).withAlpha(10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (sigint.scanning ? kRed : kCyan).withAlpha(40),
                    ),
                  ),
                  child: Text(
                    sigint.scanning ? 'STOP' : 'SCAN',
                    style: GoogleFonts.orbitron(
                      fontSize: 9,
                      color: sigint.scanning ? kRed : kCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: sigint.signals.isEmpty
              ? Center(
                  child: Text(
                    'No signals captured',
                    style: GoogleFonts.firaCode(
                      fontSize: 10,
                      color: Colors.white12,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: sigint.signals.length,
                  itemBuilder: (_, i) {
                    final s = sigint.signals[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kCardDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kCyan.withAlpha(15)),
                      ),
                      child: Row(
                        children: [
                          Icon(_sigIcon(s.type), color: kCyan, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.identifier,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  s.details,
                                  style: GoogleFonts.firaCode(
                                    fontSize: 8,
                                    color: Colors.white24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            s.type.toUpperCase(),
                            style: GoogleFonts.firaCode(
                              fontSize: 7,
                              color: kCyan,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _sigIcon(String type) {
    switch (type) {
      case 'wifi':
        return Icons.wifi;
      case 'bluetooth':
        return Icons.bluetooth;
      default:
        return Icons.cable;
    }
  }
}

// ─── OSINT Tab ──────────────────────────────────────────────────────────────
class _OsintTab extends StatelessWidget {
  final TextEditingController targetCtrl;
  const _OsintTab({required this.targetCtrl});

  @override
  Widget build(BuildContext context) {
    final osint = context.watch<OsintService>();
    return Column(
      children: [
        // Target input
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kNeonGreen.withAlpha(30)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: targetCtrl,
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter target (domain/IP)...',
                    hintStyle: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: const Color(0x33FFFFFF),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  osint.scanning ? Icons.stop : Icons.search,
                  color: kNeonGreen,
                  size: 18,
                ),
                onPressed: osint.scanning
                    ? null
                    : () {
                        if (targetCtrl.text.trim().isNotEmpty) {
                          osint.investigateTarget(targetCtrl.text.trim());
                        }
                      },
              ),
            ],
          ),
        ),
        // Results
        Expanded(
          child: osint.results.isEmpty
              ? Center(
                  child: Text(
                    'Enter a target to investigate',
                    style: GoogleFonts.firaCode(
                      fontSize: 10,
                      color: Colors.white12,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: osint.results.length,
                  itemBuilder: (_, i) {
                    final r = osint.results[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kCardDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kNeonGreen.withAlpha(15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kNeonGreen.withAlpha(10),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  r.type.toUpperCase(),
                                  style: GoogleFonts.firaCode(
                                    fontSize: 7,
                                    color: kNeonGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                r.target,
                                style: GoogleFonts.firaCode(
                                  fontSize: 9,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            r.data,
                            style: GoogleFonts.firaCode(
                              fontSize: 9,
                              color: Colors.white54,
                            ),
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── HUMINT Tab ─────────────────────────────────────────────────────────────
class _HumintTab extends StatefulWidget {
  @override
  State<_HumintTab> createState() => _HumintTabState();
}

class _HumintTabState extends State<_HumintTab> {
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final humint = context.watch<HumintService>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'TARGET PROFILER',
          style: GoogleFonts.orbitron(
            fontSize: 10,
            color: kOrange,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        _inputField('Target Name', _nameCtrl),
        _inputField('Role/Title', _roleCtrl),
        _inputField('Organization', _orgCtrl),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (_nameCtrl.text.trim().isNotEmpty) {
              humint.profileTarget(
                _nameCtrl.text.trim(),
                role: _roleCtrl.text.trim().isEmpty
                    ? null
                    : _roleCtrl.text.trim(),
                org: _orgCtrl.text.trim().isEmpty ? null : _orgCtrl.text.trim(),
              );
              _nameCtrl.clear();
              _roleCtrl.clear();
              _orgCtrl.clear();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kOrange.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kOrange.withAlpha(40)),
            ),
            child: Center(
              child: Text(
                'GENERATE PROFILE',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  color: kOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Profiles list
        ...humint.profiles.map(
          (p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kOrange.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.target,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (p.attributes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  ...p.attributes.entries.map(
                    (e) => Text(
                      '${e.key}: ${e.value}',
                      style: GoogleFonts.firaCode(
                        fontSize: 9,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ],
                if (p.attackVectors.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'ATTACK VECTORS:',
                    style: GoogleFonts.firaCode(
                      fontSize: 8,
                      color: kRed,
                      letterSpacing: 1,
                    ),
                  ),
                  ...p.attackVectors.map(
                    (v) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chevron_right,
                            color: kRed.withAlpha(60),
                            size: 12,
                          ),
                          Text(
                            v,
                            style: GoogleFonts.firaCode(
                              fontSize: 9,
                              color: Colors.white30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                // Generate pretext buttons
                Wrap(
                  spacing: 6,
                  children: ['it_support', 'password_reset', 'executive']
                      .map(
                        (type) => GestureDetector(
                          onTap: () => humint.generatePretext(type, p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: kOrange.withAlpha(30)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: GoogleFonts.firaCode(
                                fontSize: 7,
                                color: kOrange,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputField(String hint, TextEditingController ctrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.firaCode(fontSize: 11, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.firaCode(
            fontSize: 11,
            color: const Color(0x26FFFFFF),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
