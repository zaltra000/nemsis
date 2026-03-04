import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/defense_services.dart';
import '../services/orchestrator_service.dart';
import '../ai/anomaly_detector.dart';
import '../main.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DEFENSE SCREEN — SHIELD + CLOAK + PHANTOM Controls
/// ═══════════════════════════════════════════════════════════════════════════
class DefenseScreen extends StatelessWidget {
  const DefenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shield = context.watch<ShieldService>();
    final cloak = context.watch<CloakService>();
    final phantom = context.watch<PhantomService>();
    final anomaly = context.watch<AnomalyDetector>();
    final orch = context.watch<OrchestratorService>();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ─── Orchestrator Status ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kNeonGreen.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(Icons.memory, color: kNeonGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORCHESTRATOR',
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Uptime: ${orch.uptimeFormatted} | Decisions: ${orch.decisionsCount}',
                      style: GoogleFonts.firaCode(
                        fontSize: 8,
                        color: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _orchColor(orch.state).withAlpha(10),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _orchColor(orch.state).withAlpha(40),
                  ),
                ),
                child: Text(
                  orch.state.name.toUpperCase(),
                  style: GoogleFonts.firaCode(
                    fontSize: 8,
                    color: _orchColor(orch.state),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ─── SHIELD ─────────────────────────────────────────────────────
        _ModuleHeader(
          'SHIELD',
          'Intrusion Detection/Prevention',
          Icons.shield,
          kCyan,
          shield.active,
        ),
        _ToggleCard(
          'IDS/IPS Engine',
          shield.active,
          () => shield.active ? shield.deactivate() : shield.activate(),
          kCyan,
        ),
        _StatRow([
          _StatItem('Packets', '${shield.packetsAnalyzed}', kCyan),
          _StatItem('Alerts', '${shield.alerts.length}', kOrange),
          _StatItem('Blocked', '${shield.threatsBlocked}', kRed),
        ]),
        if (shield.alerts.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...shield.alerts
              .take(3)
              .map(
                (a) => _AlertCard(
                  title: a.type.toUpperCase(),
                  desc: a.description,
                  severity: a.severity,
                ),
              ),
        ],
        const SizedBox(height: 16),

        // ─── ANOMALY DETECTOR ───────────────────────────────────────────
        _ModuleHeader(
          'ANOMALY DETECTOR',
          'AI-Powered Threat Analysis',
          Icons.psychology,
          kOrange,
          anomaly.running,
        ),
        _StatRow([
          _StatItem('Scans', '${anomaly.scanCount}', kOrange),
          _StatItem('Anomalies', '${anomaly.anomalies.length}', kRed),
          _StatItem('Critical', '${anomaly.criticalCount}', kRed),
        ]),
        if (anomaly.unacknowledged.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...anomaly.unacknowledged
              .take(3)
              .map(
                (a) => _AlertCard(
                  title: a.type.name.toUpperCase(),
                  desc: a.description,
                  severity: a.severityScore,
                ),
              ),
        ],
        const SizedBox(height: 16),

        // ─── CLOAK ──────────────────────────────────────────────────────
        _ModuleHeader(
          'CLOAK',
          'Anti-Forensics Engine',
          Icons.cleaning_services,
          kPurple,
          cloak.active,
        ),
        _ActionCard(
          'Sanitize Logs',
          Icons.delete_sweep,
          kPurple,
          () => cloak.sanitizeLogs(),
        ),
        _ActionCard(
          'Scrub Metadata',
          Icons.cleaning_services,
          kPurple,
          () => cloak.scrubMetadata('/tmp'),
        ),
        _ActionCard(
          'Clear Temp Files',
          Icons.folder_delete,
          kPurple,
          () => cloak.clearTempFiles(),
        ),
        if (cloak.operations.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cloak.operations
                  .take(5)
                  .map(
                    (op) => Text(
                      op,
                      style: GoogleFonts.firaCode(
                        fontSize: 8,
                        color: const Color(0x33FFFFFF),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),

        // ─── PHANTOM ────────────────────────────────────────────────────
        _ModuleHeader(
          'PHANTOM',
          'Evasion Engine',
          Icons.visibility_off,
          const Color(0xFFFF6D00),
          phantom.stealthMode,
        ),
        _ToggleCard(
          'STEALTH MODE',
          phantom.stealthMode,
          () => phantom.toggleStealth(),
          const Color(0xFFFF6D00),
        ),
        const SizedBox(height: 6),
        ...phantom.techniques.entries.map(
          (e) => _ToggleCard(
            e.key,
            e.value,
            () => phantom.toggleTechnique(e.key),
            const Color(0xFFFF6D00),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Color _orchColor(OrchestratorState s) {
    switch (s) {
      case OrchestratorState.running:
        return kNeonGreen;
      case OrchestratorState.initializing:
        return kCyan;
      case OrchestratorState.paused:
        return kOrange;
      case OrchestratorState.error:
        return kRed;
      case OrchestratorState.offline:
        return Colors.grey;
    }
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────────────────

class _ModuleHeader extends StatelessWidget {
  final String name, subtitle;
  final IconData icon;
  final Color color;
  final bool active;
  const _ModuleHeader(
    this.name,
    this.subtitle,
    this.icon,
    this.color,
    this.active,
  );
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.firaCode(
                    fontSize: 8,
                    color: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? kNeonGreen : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;
  final Color color;
  const _ToggleCard(this.label, this.value, this.onToggle, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value ? color.withAlpha(8) : kCardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color.withAlpha(40) : const Color(0xFF1A1A1A),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.firaCode(fontSize: 10, color: Colors.white70),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 36,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: value ? color.withAlpha(60) : Colors.white10,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? color : Colors.white24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kCardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withAlpha(20)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.firaCode(
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Icon(Icons.play_arrow, color: color.withAlpha(60), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final List<_StatItem> items;
  const _StatRow(this.items);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6, bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withAlpha(5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: item.color.withAlpha(20)),
                ),
                child: Column(
                  children: [
                    Text(
                      item.value,
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                    Text(
                      item.label,
                      style: GoogleFonts.firaCode(
                        fontSize: 7,
                        color: Colors.white24,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  final String label, value;
  final Color color;
  const _StatItem(this.label, this.value, this.color);
}

class _AlertCard extends StatelessWidget {
  final String title, desc;
  final int severity;
  const _AlertCard({
    required this.title,
    required this.desc,
    required this.severity,
  });
  @override
  Widget build(BuildContext context) {
    final c = severity >= 80
        ? kRed
        : severity >= 50
        ? kOrange
        : kCyan;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.withAlpha(5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withAlpha(25)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: c, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.orbitron(
                    fontSize: 8,
                    color: c,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.firaCode(
                    fontSize: 8,
                    color: Colors.white30,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
