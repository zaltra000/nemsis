import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'cortex_engine.dart';
import 'knowledge_base.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// REASONING ENGINE — Autonomous Chain-of-Thought Decision System
/// OBSERVE → ANALYZE → PLAN → EXECUTE → ADAPT
/// ═══════════════════════════════════════════════════════════════════════════

/// A single reasoning step
class ReasoningStep {
  final String phase; // OBSERVE, ANALYZE, PLAN, EXECUTE, ADAPT
  final String content;
  final DateTime timestamp;
  final double confidence;

  ReasoningStep({
    required this.phase,
    required this.content,
    this.confidence = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// A complete reasoning chain
class ReasoningChain {
  final String id;
  final String objective;
  final List<ReasoningStep> steps;
  final DateTime created;
  String status; // 'active', 'completed', 'failed'
  double overallConfidence;

  ReasoningChain({
    required this.id,
    required this.objective,
    List<ReasoningStep>? steps,
    this.status = 'active',
    this.overallConfidence = 0.0,
    DateTime? created,
  }) : steps = steps ?? [],
       created = created ?? DateTime.now();
}

/// Threat assessment result
class ThreatAssessment {
  final String target;
  final int severityScore; // 0-100
  final String level; // 'critical', 'high', 'medium', 'low', 'info'
  final List<String> findings;
  final List<String> recommendations;
  final DateTime timestamp;

  ThreatAssessment({
    required this.target,
    required this.severityScore,
    required this.level,
    required this.findings,
    required this.recommendations,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// The Reasoning Engine: autonomous OODA-style decision loop
class ReasoningEngine extends ChangeNotifier {
  final CortexEngine cortexEngine;
  final KnowledgeBase _kb;

  final List<ReasoningChain> _chains = [];
  final List<ThreatAssessment> _assessments = [];
  bool _autonomousMode = false;
  Timer? _autonomousTimer;

  List<ReasoningChain> get chains => List.unmodifiable(_chains);
  List<ThreatAssessment> get assessments => List.unmodifiable(_assessments);
  bool get autonomousMode => _autonomousMode;

  ReasoningEngine({
    required CortexEngine cortex,
    required KnowledgeBase knowledgeBase,
  }) : cortexEngine = cortex,
       _kb = knowledgeBase;

  /// Execute a full reasoning chain for an objective
  Future<ReasoningChain> reason(String objective) async {
    final chain = ReasoningChain(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      objective: objective,
    );
    _chains.insert(0, chain);
    notifyListeners();

    try {
      // ═══ PHASE 1: OBSERVE ═══
      chain.steps.add(
        ReasoningStep(
          phase: 'OBSERVE',
          content: 'Gathering system intelligence for: $objective',
          confidence: 0.1,
        ),
      );
      notifyListeners();

      final systemState = await _gatherSystemState();
      chain.steps.add(
        ReasoningStep(
          phase: 'OBSERVE',
          content: 'System state collected: ${systemState.length} data points',
          confidence: 0.2,
        ),
      );
      notifyListeners();

      // ═══ PHASE 2: ANALYZE ═══
      chain.steps.add(
        ReasoningStep(
          phase: 'ANALYZE',
          content: 'Querying knowledge base...',
          confidence: 0.3,
        ),
      );
      notifyListeners();

      final knowledgeResults = _kb.search(objective, limit: 10);
      chain.steps.add(
        ReasoningStep(
          phase: 'ANALYZE',
          content:
              'Found ${knowledgeResults.length} relevant knowledge entries. '
              'Top domains: ${knowledgeResults.take(3).map((r) => r.entry.domain).toSet().join(", ")}',
          confidence: 0.4 + (knowledgeResults.length * 0.02),
        ),
      );
      notifyListeners();

      // Correlate system state with knowledge
      final vulnerabilities = _correlateFindings(systemState, knowledgeResults);
      chain.steps.add(
        ReasoningStep(
          phase: 'ANALYZE',
          content:
              'Correlation analysis: ${vulnerabilities.length} potential vectors identified',
          confidence: 0.5,
        ),
      );
      notifyListeners();

      // ═══ PHASE 3: PLAN ═══
      final plan = _generatePlan(objective, vulnerabilities, knowledgeResults);
      chain.steps.add(
        ReasoningStep(phase: 'PLAN', content: plan, confidence: 0.7),
      );
      notifyListeners();

      // ═══ PHASE 4: EXECUTE (recommendations) ═══
      final commands = _generateCommands(objective, knowledgeResults);
      chain.steps.add(
        ReasoningStep(
          phase: 'EXECUTE',
          content: 'Recommended commands:\n${commands.join("\n")}',
          confidence: 0.8,
        ),
      );
      notifyListeners();

      // ═══ PHASE 5: ADAPT ═══
      chain.steps.add(
        ReasoningStep(
          phase: 'ADAPT',
          content:
              'Chain complete. Standing by for execution feedback to adapt strategy.',
          confidence: 0.9,
        ),
      );

      chain.status = 'completed';
      chain.overallConfidence = 0.9;
      notifyListeners();
    } catch (e) {
      chain.steps.add(
        ReasoningStep(
          phase: 'ERROR',
          content: 'Reasoning failed: $e',
          confidence: 0.0,
        ),
      );
      chain.status = 'failed';
      notifyListeners();
    }

    return chain;
  }

  /// Perform a threat assessment on a target
  Future<ThreatAssessment> assessThreat(String target) async {
    final findings = <String>[];
    final recommendations = <String>[];
    int severity = 0;

    // Search knowledge base for relevant threats
    final results = _kb.search(target, limit: 15);

    for (final result in results) {
      findings.add(
        '[${result.entry.domain.toUpperCase()}] ${result.entry.content}',
      );
      severity = severity < result.entry.severity
          ? result.entry.severity
          : severity;
    }

    // Generate recommendations based on findings
    if (severity >= 90) {
      recommendations.addAll([
        'CRITICAL: Immediate action required',
        'Deploy exploit chain targeting identified vulnerability',
        'Establish persistence before patch window closes',
        'Activate evasion protocols during operation',
      ]);
    } else if (severity >= 70) {
      recommendations.addAll([
        'HIGH: Exploit viable with standard techniques',
        'Conduct further reconnaissance to confirm vulnerability',
        'Prepare payload and establish exfiltration channel',
      ]);
    } else if (severity >= 40) {
      recommendations.addAll([
        'MEDIUM: Further investigation required',
        'Cross-reference with additional data sources',
        'Consider alternative attack vectors',
      ]);
    } else {
      recommendations.addAll([
        'LOW: Limited exploitation potential',
        'Continue passive reconnaissance',
        'Monitor for new vulnerability disclosures',
      ]);
    }

    final level = severity >= 90
        ? 'critical'
        : severity >= 70
        ? 'high'
        : severity >= 40
        ? 'medium'
        : severity >= 20
        ? 'low'
        : 'info';

    final assessment = ThreatAssessment(
      target: target,
      severityScore: severity,
      level: level,
      findings: findings,
      recommendations: recommendations,
    );

    _assessments.insert(0, assessment);
    notifyListeners();
    return assessment;
  }

  /// Toggle autonomous mode
  void setAutonomousMode(bool enabled) {
    _autonomousMode = enabled;
    if (enabled) {
      _startAutonomousLoop();
    } else {
      _autonomousTimer?.cancel();
      _autonomousTimer = null;
    }
    notifyListeners();
  }

  /// Autonomous reasoning loop
  void _startAutonomousLoop() {
    _autonomousTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      if (!_autonomousMode) {
        timer.cancel();
        return;
      }

      // Auto-analyze current system state
      final systemState = await _gatherSystemState();
      if (systemState.isNotEmpty) {
        await assessThreat(systemState.join(' '));
      }
    });
  }

  /// Gather current system state data
  Future<List<String>> _gatherSystemState() async {
    final data = <String>[];
    try {
      // Kernel info
      final uname = await Process.run('uname', ['-a']);
      data.add(uname.stdout.toString().trim());

      // Network interfaces
      final ip = await Process.run('ip', ['addr', 'show']);
      data.add(ip.stdout.toString().trim());

      // Active connections
      final conns = await Process.run('sh', [
        '-c',
        'ss -tn state established 2>/dev/null | head -10',
      ]);
      data.add(conns.stdout.toString().trim());

      // Running processes
      final procs = await Process.run('sh', [
        '-c',
        'ps aux --sort=-%cpu 2>/dev/null | head -5',
      ]);
      data.add(procs.stdout.toString().trim());
    } catch (_) {}
    return data;
  }

  /// Correlate system findings with knowledge base
  List<String> _correlateFindings(
    List<String> systemState,
    List<SearchResult> knowledge,
  ) {
    final correlations = <String>[];
    final stateStr = systemState.join(' ').toLowerCase();

    for (final result in knowledge) {
      for (final tag in result.entry.tags) {
        if (stateStr.contains(tag)) {
          correlations.add(
            '${result.entry.domain}: ${tag} detected in system state',
          );
        }
      }
    }
    return correlations;
  }

  /// Generate an execution plan
  String _generatePlan(
    String objective,
    List<String> vulns,
    List<SearchResult> knowledge,
  ) {
    final plan = StringBuffer();
    plan.writeln('Tactical Plan for: $objective');
    plan.writeln('─────────────────────────────');

    if (vulns.isNotEmpty) {
      plan.writeln('Step 1: Exploit ${vulns.length} identified correlations');
      plan.writeln('Step 2: Establish persistence via layered mechanisms');
      plan.writeln('Step 3: Activate evasion protocols');
      plan.writeln('Step 4: Execute primary objective');
      plan.writeln('Step 5: Clean traces and adapt');
    } else {
      plan.writeln('Step 1: Expand reconnaissance scope');
      plan.writeln('Step 2: Identify secondary attack surfaces');
      plan.writeln('Step 3: Deploy targeted scanning');
    }

    return plan.toString();
  }

  /// Generate executable commands
  List<String> _generateCommands(
    String objective,
    List<SearchResult> knowledge,
  ) {
    final commands = <String>[];
    final objLower = objective.toLowerCase();

    if (objLower.contains('recon') || objLower.contains('scan')) {
      commands.addAll(['ip addr show', 'ss -tulpn', 'ip neigh show']);
    }
    if (objLower.contains('exploit') || objLower.contains('vuln')) {
      commands.addAll([
        'find / -perm -4000 -type f 2>/dev/null',
        'uname -a',
        'cat /etc/passwd',
      ]);
    }
    if (objLower.contains('persist')) {
      commands.addAll([
        'crontab -l',
        'systemctl list-unit-files --state=enabled | head -20',
      ]);
    }
    if (objLower.contains('exfil') || objLower.contains('data')) {
      commands.addAll([
        'find /home -type f -name "*.pdf" 2>/dev/null | head -10',
      ]);
    }

    if (commands.isEmpty) {
      commands.addAll(['uname -a', 'ip addr show', 'whoami']);
    }

    return commands;
  }

  @override
  void dispose() {
    _autonomousTimer?.cancel();
    super.dispose();
  }
}
