import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../ai/cortex_engine.dart';
import '../ai/knowledge_base.dart';
import '../main.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CORTEX SCREEN — AI Chat + Reasoning Visualization
/// ═══════════════════════════════════════════════════════════════════════════
class CortexScreen extends StatefulWidget {
  const CortexScreen({super.key});
  @override
  State<CortexScreen> createState() => _CortexScreenState();
}

class _CortexScreenState extends State<CortexScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    final cortex = Provider.of<CortexEngine>(context, listen: false);
    cortex.processQuery(text);
  }

  @override
  Widget build(BuildContext context) {
    final cortex = context.watch<CortexEngine>();
    final kb = context.watch<KnowledgeBase>();

    return Column(
      children: [
        // ─── Status Bar ─────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _statusColor(cortex.status).withAlpha(40),
            ),
          ),
          child: Row(
            children: [
              _Dot(color: _statusColor(cortex.status)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cortex.modelInfo,
                  style: GoogleFonts.firaCode(
                    fontSize: 8,
                    color: Colors.white38,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (kb.initialized)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: kCyan.withAlpha(40)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${kb.totalEntries} KB',
                    style: GoogleFonts.firaCode(fontSize: 8, color: kCyan),
                  ),
                ),
            ],
          ),
        ),

        // ─── Reasoning Chain (collapsible) ──────────────────────────
        if (cortex.reasoningChain.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF080808),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: kPurple.withAlpha(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: kPurple, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'REASONING CHAIN',
                      style: GoogleFonts.orbitron(
                        fontSize: 8,
                        color: kPurple,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    if (cortex.confidence > 0)
                      Text(
                        '${(cortex.confidence * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.firaCode(
                          fontSize: 9,
                          color: kNeonGreen,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ...cortex.reasoningChain.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(
                      step,
                      style: GoogleFonts.firaCode(
                        fontSize: 8,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ─── Chat History ───────────────────────────────────────────
        Expanded(
          child: cortex.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology_alt,
                        color: Colors.white10,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'CORTEX V8.0',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          color: const Color(0x33FFFFFF),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ask anything about offensive/defensive operations',
                        style: GoogleFonts.firaCode(
                          fontSize: 9,
                          color: Colors.white12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount:
                      cortex.history.length + (cortex.isStreaming ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < cortex.history.length) {
                      final msg = cortex.history[index];
                      return _ChatBubble(msg: msg);
                    }
                    // Streaming response
                    return _StreamingBubble(text: cortex.currentResponse);
                  },
                ),
        ),

        // ─── Quick Actions ──────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _QuickAction(
                'Recon Guide',
                () => _query('How to perform network reconnaissance?'),
              ),
              _QuickAction(
                'Privesc',
                () => _query('Linux privilege escalation techniques'),
              ),
              _QuickAction(
                'Persistence',
                () => _query('Best persistence mechanisms'),
              ),
              _QuickAction(
                'Evasion',
                () => _query('Anti-forensics and evasion techniques'),
              ),
              _QuickAction(
                'CVE Scan',
                () => _query('Latest critical CVEs for exploitation'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // ─── Input Bar ──────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kPurple.withAlpha(30)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  style: GoogleFonts.firaCode(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Query CORTEX...',
                    hintStyle: GoogleFonts.firaCode(
                      fontSize: 12,
                      color: const Color(0x33FFFFFF),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              IconButton(
                icon: Icon(
                  cortex.isStreaming ? Icons.stop_circle : Icons.send_rounded,
                  color: kPurple,
                  size: 20,
                ),
                onPressed: cortex.isStreaming ? null : _send,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _query(String q) {
    _inputCtrl.text = q;
    _send();
  }

  Color _statusColor(CortexStatus s) {
    switch (s) {
      case CortexStatus.ready:
        return kNeonGreen;
      case CortexStatus.processing:
        return kCyan;
      case CortexStatus.loading:
        return kOrange;
      case CortexStatus.error:
        return kRed;
      case CortexStatus.uninitialized:
        return Colors.grey;
    }
  }
}

// ─── Pulsing Dot ────────────────────────────────────────────────────────────
class _Dot extends StatefulWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        boxShadow: [
          BoxShadow(
            color: widget.color.withAlpha((_c.value * 100).toInt()),
            blurRadius: 4,
          ),
        ],
      ),
    ),
  );
}

// ─── Chat Message Bubble ────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final CortexMessage msg;
  const _ChatBubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final isSystem = msg.role == 'system';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSystem
            ? kPurple.withAlpha(8)
            : (isUser ? kCyan.withAlpha(8) : kCardDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSystem
              ? kPurple.withAlpha(25)
              : (isUser ? kCyan.withAlpha(25) : const Color(0xFF1A1A1A)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isUser ? 'USER' : (isSystem ? 'SYSTEM' : 'CORTEX'),
                style: GoogleFonts.orbitron(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: isUser ? kCyan : (isSystem ? kPurple : kNeonGreen),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.firaCode(
                  fontSize: 7,
                  color: const Color(0x33FFFFFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            msg.content,
            style: GoogleFonts.firaCode(
              fontSize: 10,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streaming Response Bubble ──────────────────────────────────────────────
class _StreamingBubble extends StatelessWidget {
  final String text;
  const _StreamingBubble({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kNeonGreen.withAlpha(5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kNeonGreen.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CORTEX',
                style: GoogleFonts.orbitron(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: kNeonGreen,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  color: kNeonGreen.withAlpha(100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text.isEmpty ? '...' : text,
            style: GoogleFonts.firaCode(
              fontSize: 10,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Chip ──────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickAction(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: kPurple.withAlpha(30)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: GoogleFonts.firaCode(fontSize: 9, color: kPurple),
          ),
        ),
      ),
    );
  }
}
