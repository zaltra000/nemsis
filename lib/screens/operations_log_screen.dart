import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/warfare_service.dart';
import '../services/c2_bridge_service.dart';
import '../main.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// OPERATIONS LOG: Real-time feed of all offensive operations
/// ═══════════════════════════════════════════════════════════════════════════
class OperationsLogScreen extends StatelessWidget {
  const OperationsLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final warfare = context.watch<WarfareService>();
    final c2 = context.watch<C2BridgeService>();

    return Column(
      children: [
        // ─── C2 Status Bar ──────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _c2Color(c2.state).withAlpha(40)),
          ),
          child: Row(
            children: [
              _StatusDot(color: _c2Color(c2.state)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'C2 BRIDGE: ${_c2Label(c2.state)}',
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _c2Color(c2.state),
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      c2.serverUrl,
                      style: GoogleFonts.firaCode(
                        fontSize: 8,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
              // Connect/Disconnect button
              GestureDetector(
                onTap: () {
                  if (c2.state == C2State.connected) {
                    c2.disconnect();
                  } else {
                    c2.connect();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _c2Color(c2.state).withAlpha(12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _c2Color(c2.state).withAlpha(40)),
                  ),
                  child: Text(
                    c2.state == C2State.connected ? 'DISCONNECT' : 'CONNECT',
                    style: GoogleFonts.firaCode(
                      fontSize: 9,
                      color: _c2Color(c2.state),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Stats Row ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StatChip(
                label: 'TOTAL OPS',
                value: '${warfare.history.length}',
                color: kCyan,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'SUCCESS',
                value:
                    '${warfare.history.where((h) => h.status == OpStatus.success).length}',
                color: kNeonGreen,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'FAILED',
                value:
                    '${warfare.history.where((h) => h.status == OpStatus.failed).length}',
                color: kRed,
              ),
              const Spacer(),
              if (warfare.history.isNotEmpty)
                GestureDetector(
                  onTap: () => warfare.clearHistory(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white24,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        const Divider(color: Color(0xFF1A1A1A), height: 1),

        // ─── Operations List ────────────────────────────────────────
        Expanded(
          child: warfare.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, color: Colors.white12, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'NO OPERATIONS EXECUTED',
                        style: GoogleFonts.orbitron(
                          fontSize: 11,
                          color: Colors.white24,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Execute tools from the Arsenal tab',
                        style: GoogleFonts.firaCode(
                          fontSize: 10,
                          color: Colors.white12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: warfare.history.length,
                  itemBuilder: (context, index) {
                    final op = warfare.history[index];
                    return _OpCard(op: op);
                  },
                ),
        ),

        // ─── C2 Log (collapsed at bottom) ────────────────────────────
        if (c2.log.isNotEmpty)
          Container(
            height: 80,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1A1A1A)),
            ),
            child: ListView.builder(
              reverse: true,
              itemCount: c2.log.length,
              itemBuilder: (context, index) {
                final entry = c2.log[c2.log.length - 1 - index];
                return Text(
                  entry,
                  style: GoogleFonts.firaCode(
                    fontSize: 8,
                    color: Colors.white24,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Color _c2Color(C2State state) {
    switch (state) {
      case C2State.connected:
        return kNeonGreen;
      case C2State.connecting:
        return kCyan;
      case C2State.error:
        return kRed;
      case C2State.disconnected:
        return Colors.grey;
    }
  }

  String _c2Label(C2State state) {
    switch (state) {
      case C2State.connected:
        return 'ACTIVE';
      case C2State.connecting:
        return 'CONNECTING...';
      case C2State.error:
        return 'ERROR';
      case C2State.disconnected:
        return 'OFFLINE';
    }
  }
}

// ─── Status Dot ─────────────────────────────────────────────────────────────
class _StatusDot extends StatefulWidget {
  final Color color;
  const _StatusDot({required this.color});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha((_ctrl.value * 120).toInt()),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Stat Chip ──────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(30)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.firaCode(
              fontSize: 7,
              color: Colors.white30,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Operation Card ─────────────────────────────────────────────────────────
class _OpCard extends StatelessWidget {
  final OpResult op;
  const _OpCard({required this.op});

  @override
  Widget build(BuildContext context) {
    final statusColor = op.status == OpStatus.success ? kNeonGreen : kRed;
    final statusIcon = op.status == OpStatus.success
        ? Icons.check_circle
        : Icons.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 14),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  op.module,
                  style: GoogleFonts.firaCode(
                    fontSize: 8,
                    color: statusColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  op.tool,
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '${op.timestamp.hour.toString().padLeft(2, '0')}:${op.timestamp.minute.toString().padLeft(2, '0')}:${op.timestamp.second.toString().padLeft(2, '0')}',
                style: GoogleFonts.firaCode(fontSize: 8, color: Colors.white24),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              op.output,
              style: GoogleFonts.firaCode(
                fontSize: 9,
                color: kNeonGreen.withAlpha(180),
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
