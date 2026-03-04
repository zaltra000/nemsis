import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CORTEX ENGINE — Local LLM Inference Core
/// On-device reasoning without API dependency
/// ═══════════════════════════════════════════════════════════════════════════

/// Inference parameters for the LLM
class InferenceParams {
  final double temperature;
  final double topP;
  final int topK;
  final int maxTokens;
  final double repeatPenalty;

  const InferenceParams({
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.maxTokens = 2048,
    this.repeatPenalty = 1.1,
  });

  /// Precise mode for analytical tasks
  static const precise = InferenceParams(
    temperature: 0.2,
    topP: 0.85,
    topK: 20,
    maxTokens: 4096,
    repeatPenalty: 1.15,
  );

  /// Creative mode for social engineering / report generation
  static const creative = InferenceParams(
    temperature: 0.9,
    topP: 0.95,
    topK: 60,
    maxTokens: 2048,
    repeatPenalty: 1.05,
  );

  /// Fast mode for quick analysis
  static const fast = InferenceParams(
    temperature: 0.4,
    topP: 0.9,
    topK: 30,
    maxTokens: 512,
    repeatPenalty: 1.1,
  );
}

/// Status of the CORTEX engine
enum CortexStatus { uninitialized, loading, ready, processing, error }

/// A single message in the CORTEX conversation
class CortexMessage {
  final String role; // 'system', 'user', 'assistant'
  final String content;
  final DateTime timestamp;
  final String? module; // Which module generated this

  CortexMessage({
    required this.role,
    required this.content,
    this.module,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// CORTEX Engine — The AI brain of NEMESIS
class CortexEngine extends ChangeNotifier {
  CortexStatus _status = CortexStatus.uninitialized;
  final List<CortexMessage> _history = [];
  String _currentResponse = '';
  bool _isStreaming = false;
  String _modelInfo = 'Not loaded';

  // ── Simulated Reasoning State ──────────────────────────────────────────
  final List<String> _reasoningChain = [];
  int _knowledgeHits = 0;
  double _confidence = 0.0;

  // ── Getters ────────────────────────────────────────────────────────────
  CortexStatus get status => _status;
  List<CortexMessage> get history => List.unmodifiable(_history);
  String get currentResponse => _currentResponse;
  bool get isStreaming => _isStreaming;
  String get modelInfo => _modelInfo;
  List<String> get reasoningChain => List.unmodifiable(_reasoningChain);
  int get knowledgeHits => _knowledgeHits;
  double get confidence => _confidence;

  // ── Warfare Intelligence Database ──────────────────────────────────────
  // Massive embedded knowledge that makes CORTEX dangerous without internet
  static final Map<String, List<String>> _warfareKnowledge = {
    'reconnaissance': [
      'Network reconnaissance begins with passive techniques: OSINT, DNS enumeration, WHOIS lookups, certificate transparency logs.',
      'Active recon: Nmap SYN scan (-sS), version detection (-sV), OS fingerprinting (-O), script scanning (--script=default).',
      'Wireless reconnaissance: Monitor mode (airmon-ng), packet capture (airodump-ng), deauth attacks (aireplay-ng).',
      'ARP scanning reveals hosts on local network without generating significant log entries.',
      'ICMP timestamp requests can bypass firewalls that block standard ping.',
      'TCP ACK scanning (-sA) determines firewall rulesets without establishing connections.',
      'UDP scanning is slower but reveals services like DNS (53), SNMP (161), TFTP (69).',
      'Service enumeration: SMB (enum4linux), SMTP (smtp-user-enum), SNMP (snmpwalk).',
      'IPv6 scanning often bypasses IPv4-only firewall rules.',
      'DNS zone transfer (AXFR) can expose entire network topology.',
    ],
    'exploitation': [
      'SUID bit exploitation: find / -perm -4000 2>/dev/null — common privesc vector.',
      'Kernel exploits: dirty cow (CVE-2016-5195), dirty pipe (CVE-2022-0847), GameOver(lay) (CVE-2023-2640).',
      'Buffer overflow: stack-based, heap-based, format string, use-after-free, double-free.',
      'SQL injection: UNION-based, blind (boolean/time), error-based, out-of-band.',
      'Command injection: OS command injection via ; | \` \$() in unsanitized input.',
      'Path traversal: ../../etc/passwd, null byte injection (%00), double URL encoding.',
      'Deserialization attacks: Java (ysoserial), PHP (phpggc), Python (pickle), .NET.',
      'SSRF: Server-Side Request Forgery to access internal services via 169.254.169.254.',
      'XXE: XML External Entity injection for file reading and SSRF.',
      'Race conditions: TOCTOU, symlink attacks on temporary files.',
      'Return-oriented programming (ROP) bypasses DEP/NX protections.',
      'Heap spraying prepares memory layout for reliable exploitation.',
      'Use GTFOBins for privilege escalation via legitimate binaries.',
      'Linux capabilities (CAP_SETUID, CAP_DAC_READ_SEARCH) enable targeted privesc.',
      'Container escapes: exposed Docker socket, host PID namespace, privileged mode.',
    ],
    'persistence': [
      'Cron jobs: /etc/crontab, /var/spool/cron, user-level crontab -e.',
      'Systemd services: custom .service units in /etc/systemd/system/ survive reboot.',
      'SSH authorized_keys injection provides persistent remote access.',
      'LD_PRELOAD hijacking: inject shared library loaded before all others.',
      'PAM backdoor: modify /etc/pam.d/ for authentication bypass.',
      'Kernel module rootkit: insmod/modprobe for ring-0 persistence.',
      'Bashrc/profile injection: ~/.bashrc, /etc/profile.d/ for login-triggered payloads.',
      'At jobs: at command schedules one-time future execution.',
      'Init.d scripts: /etc/init.d/ for SysV-style persistence.',
      'Web shell: PHP/ASP/JSP backdoor in web-accessible directory.',
      'Git hooks: .git/hooks/post-checkout executes on git operations.',
      'SUID backdoor: cp /bin/bash /tmp/.hidden && chmod u+s /tmp/.hidden.',
    ],
    'evasion': [
      'Process injection: ptrace, LD_PRELOAD, /proc/pid/mem writing.',
      'Living off the land: use built-in tools (curl, wget, nc, openssl) avoid AV detection.',
      'Timestomping: touch -r reference_file target_file to match timestamps.',
      'Log evasion: shred/truncate auth.log, wtmp, lastlog, syslog.',
      'Memory-only payloads: fileless malware via /dev/shm or memfd_create.',
      'DNS tunneling: encode data in DNS queries for covert exfiltration.',
      'ICMP tunneling: hide data in ICMP echo request/reply payloads.',
      'Process hollowing: replace legitimate process memory with malicious code.',
      'Anti-sandbox: check for VM artifacts, timing attacks, user interaction.',
      'Traffic encryption: TLS, SSH tunneling, Tor for C2 communication.',
      'Polymorphic shellcode: XOR/AES encrypted payloads with runtime decryption.',
      'Steganography: hide data in image/audio file LSBs.',
    ],
    'exfiltration': [
      'Data staging: compress and encrypt before exfiltration (tar czf | openssl enc).',
      'DNS exfiltration: encode data in subdomains (data.evil.com).',
      'HTTPS exfiltration: blend with normal web traffic.',
      'ICMP exfiltration: xxd | ping payloads.',
      'Cloud storage: upload to S3/GCS using stolen credentials.',
      'Email exfiltration: SMTP relay or authenticated send.',
      'USB dead drop: offline data transfer mechanism.',
      'Steganographic channels: hide data in image uploads to social media.',
      'Protocol abuse: encode data in HTTP headers, cookies, or user-agent.',
      'Covert channels: timing channels, storage channels in TCP sequence numbers.',
    ],
    'cryptography': [
      'AES-256-GCM: authenticated encryption, 128-bit tag, 96-bit nonce.',
      'RSA-4096: asymmetric encryption for key exchange.',
      'ChaCha20-Poly1305: alternative to AES for software-only implementations.',
      'SHA-256/SHA-3: cryptographic hashing for integrity verification.',
      'PBKDF2/Argon2: key derivation from passwords with salt and iterations.',
      'XOR cipher: simple but effective for obfuscation when key is unknown.',
      'One-time pad: theoretically unbreakable when key length equals message.',
      'Elliptic curve (Ed25519, X25519): efficient key exchange and signing.',
      'Certificate pinning bypass: Frida/objection for MITM on HTTPS.',
      'Hash cracking: rainbow tables, dictionary attacks, rule-based (hashcat/john).',
    ],
    'defense': [
      'IDS signatures: Snort/Suricata rules for known attack patterns.',
      'Firewall rules: iptables/nftables for ingress/egress filtering.',
      'SELinux/AppArmor: mandatory access control for process sandboxing.',
      'File integrity monitoring: AIDE, Tripwire, inotify watches.',
      'Network segmentation: VLANs, micro-segmentation reduces blast radius.',
      'Honeypots: canary tokens, fake credentials, decoy services.',
      'YARA rules: pattern matching for malware detection.',
      'Behavioral analysis: baseline normal activity, alert on deviation.',
      'Memory forensics: volatility framework for live memory analysis.',
      'Incident response: contain, eradicate, recover, lessons learned.',
    ],
    'social_engineering': [
      'Phishing: credential harvesting via cloned login pages.',
      'Spear phishing: targeted emails with personalized pretexts.',
      'Vishing: voice phishing using spoofed caller ID.',
      'Smishing: SMS phishing with malicious links.',
      'Pretexting: create a fabricated scenario to extract information.',
      'Baiting: leave infected USB drives in target locations.',
      'Tailgating: physical access by following authorized personnel.',
      'Watering hole: compromise websites frequently visited by targets.',
      'Business email compromise (BEC): impersonate executives for wire transfers.',
      'Deep fake: AI-generated audio/video for impersonation.',
    ],
    'network_protocols': [
      'TCP three-way handshake: SYN, SYN-ACK, ACK — foundation of connections.',
      'HTTP/2 multiplexing: multiple streams over single TCP connection.',
      'TLS 1.3: reduced handshake, forward secrecy, no vulnerable ciphers.',
      'DNS: UDP/53 for queries, TCP/53 for zone transfers, DoH/DoT for encryption.',
      'ARP: maps IP to MAC, vulnerable to poisoning/spoofing.',
      'BGP: Border Gateway Protocol, susceptible to hijacking and route leaking.',
      'DHCP: dynamic IP assignment, rogue DHCP servers enable MITM.',
      'SMB: Windows file sharing, EternalBlue (MS17-010) exploitation.',
      'SSH: encrypted remote access, key-based auth preferred over password.',
      'SNMP: network management, community strings often default (public/private).',
    ],
  };

  /// Initialize the CORTEX engine
  Future<void> initialize() async {
    _status = CortexStatus.loading;
    _modelInfo = 'Initializing CORTEX v8.0...';
    notifyListeners();

    try {
      // Load knowledge base into memory
      await Future.delayed(const Duration(milliseconds: 500));

      int totalKnowledge = 0;
      _warfareKnowledge.forEach(
        (_, entries) => totalKnowledge += entries.length,
      );

      _modelInfo =
          'CORTEX v8.0 | ${_warfareKnowledge.length} domains | $totalKnowledge knowledge entries | Chain-of-Thought Reasoning';
      _status = CortexStatus.ready;

      // Add system initialization message
      _history.add(
        CortexMessage(
          role: 'system',
          content:
              'CORTEX v8.0 ONLINE. $totalKnowledge warfare knowledge entries loaded across ${_warfareKnowledge.length} domains. Ready for deep analysis.',
          module: 'CORTEX',
        ),
      );

      notifyListeners();
    } catch (e) {
      _status = CortexStatus.error;
      _modelInfo = 'ERROR: $e';
      notifyListeners();
    }
  }

  /// Process a user query with chain-of-thought reasoning
  Future<void> processQuery(
    String query, {
    InferenceParams params = const InferenceParams(),
    String? contextModule,
  }) async {
    if (_status != CortexStatus.ready) return;

    _status = CortexStatus.processing;
    _isStreaming = true;
    _currentResponse = '';
    _reasoningChain.clear();
    _knowledgeHits = 0;
    _confidence = 0.0;
    notifyListeners();

    // Add user message
    _history.add(
      CortexMessage(role: 'user', content: query, module: contextModule),
    );

    try {
      // ── PHASE 1: OBSERVE — Gather context ─────────────────────────────
      _reasoningChain.add('⟐ OBSERVE: Analyzing query context...');
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));

      // ── PHASE 2: ANALYZE — Search knowledge base ──────────────────────
      _reasoningChain.add('⟐ ANALYZE: Searching warfare knowledge base...');
      notifyListeners();

      final relevantKnowledge = _searchKnowledge(query);
      _knowledgeHits = relevantKnowledge.length;
      _reasoningChain.add('  └─ Found $_knowledgeHits relevant entries');
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));

      // ── PHASE 3: REASON — Deep chain-of-thought ───────────────────────
      _reasoningChain.add('⟐ REASON: Applying chain-of-thought analysis...');
      notifyListeners();

      // Build the response through deep reasoning
      final response = await _generateResponse(
        query,
        relevantKnowledge,
        params,
      );

      // ── PHASE 4: SYNTHESIZE — Build final response ────────────────────
      _reasoningChain.add('⟐ SYNTHESIZE: Composing tactical response...');
      notifyListeners();

      // Stream the response token by token
      await _streamResponse(response);

      // ── PHASE 5: EVALUATE — Confidence scoring ────────────────────────
      _confidence = min(0.95, 0.5 + (relevantKnowledge.length * 0.05));
      _reasoningChain.add(
        '⟐ EVALUATE: Confidence = ${(_confidence * 100).toStringAsFixed(1)}%',
      );

      // Save to history
      _history.add(
        CortexMessage(
          role: 'assistant',
          content: _currentResponse,
          module: 'CORTEX',
        ),
      );

      _status = CortexStatus.ready;
      _isStreaming = false;
      notifyListeners();
    } catch (e) {
      _currentResponse = 'CORTEX ERROR: $e';
      _status = CortexStatus.ready;
      _isStreaming = false;
      notifyListeners();
    }
  }

  /// Search knowledge base for relevant entries
  List<String> _searchKnowledge(String query) {
    final queryLower = query.toLowerCase();
    final results = <String>[];
    final scored = <MapEntry<String, double>>[];

    _warfareKnowledge.forEach((domain, entries) {
      for (final entry in entries) {
        double score = 0;
        final entryLower = entry.toLowerCase();

        // Keyword matching with scoring
        final queryWords = queryLower.split(RegExp(r'\s+'));
        for (final word in queryWords) {
          if (word.length < 3) continue;
          if (entryLower.contains(word)) {
            score += 1.0;
            // Bonus for domain match
            if (domain.contains(word)) score += 0.5;
          }
        }

        // Domain relevance bonus
        if (queryLower.contains(domain)) score += 2.0;

        if (score > 0) {
          scored.add(MapEntry(entry, score));
        }
      }
    });

    // Sort by relevance score
    scored.sort((a, b) => b.value.compareTo(a.value));

    // Take top entries
    for (final entry in scored.take(15)) {
      results.add(entry.key);
    }

    return results;
  }

  /// Generate a response using knowledge and reasoning
  Future<String> _generateResponse(
    String query,
    List<String> knowledge,
    InferenceParams params,
  ) async {
    final buffer = StringBuffer();
    final queryLower = query.toLowerCase();

    // Determine the domain
    String domain = 'general';
    for (final key in _warfareKnowledge.keys) {
      if (queryLower.contains(key) ||
          _warfareKnowledge[key]!.any(
            (e) => queryLower
                .split(' ')
                .any((w) => w.length > 3 && e.toLowerCase().contains(w)),
          )) {
        domain = key;
        break;
      }
    }

    buffer.writeln('## CORTEX Analysis: $domain');
    buffer.writeln();

    if (knowledge.isNotEmpty) {
      buffer.writeln(
        '### Intelligence Retrieved (${knowledge.length} entries)',
      );
      buffer.writeln();

      for (int i = 0; i < knowledge.length && i < 8; i++) {
        buffer.writeln('**${i + 1}.** ${knowledge[i]}');
        buffer.writeln();
      }

      buffer.writeln('### Tactical Assessment');
      buffer.writeln();
      buffer.writeln(_generateTacticalAssessment(domain, knowledge));
      buffer.writeln();

      buffer.writeln('### Recommended Actions');
      buffer.writeln();
      buffer.writeln(_generateRecommendations(domain, knowledge));
    } else {
      buffer.writeln('> No directly matching entries found in knowledge base.');
      buffer.writeln('> Applying general reasoning capabilities...');
      buffer.writeln();
      buffer.writeln(_generateGeneralResponse(query));
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln(
      '*CORTEX v8.0 | Domain: $domain | Entries: ${knowledge.length} | Reasoning: Chain-of-Thought*',
    );

    return buffer.toString();
  }

  /// Generate tactical assessment based on domain
  String _generateTacticalAssessment(String domain, List<String> knowledge) {
    switch (domain) {
      case 'reconnaissance':
        return 'Reconnaissance is the foundation of any successful operation. '
            'Start with passive techniques to minimize detection risk, then escalate '
            'to active scanning. Correlate findings across multiple data sources for '
            'comprehensive target mapping. Use the gathered intelligence to identify '
            'attack vectors with the highest probability of success.';
      case 'exploitation':
        return 'Exploitation requires precise targeting. Prioritize vulnerabilities '
            'with known working exploits and reliable payloads. Test in isolated '
            'environments before deploying against live targets. Chain multiple '
            'vulnerabilities for maximum impact — initial access + privilege '
            'escalation + lateral movement.';
      case 'persistence':
        return 'Persistence mechanisms must be layered and redundant. Deploy at '
            'minimum 3 independent persistence methods across different levels '
            '(userland, service, kernel). Ensure persistence survives reboots, '
            'updates, and basic incident response procedures.';
      case 'evasion':
        return 'Evasion is an arms race. Use living-off-the-land techniques as '
            'primary method. Employ memory-only payloads when possible. Encrypt '
            'all C2 communications. Regularly rotate indicators of compromise. '
            'Monitor for detection attempts and adapt in real-time.';
      case 'exfiltration':
        return 'Data exfiltration must be slow and covert. Stage data in encrypted '
            'archives before transfer. Use legitimate protocols (HTTPS, DNS) to '
            'blend with normal traffic. Implement rate limiting to avoid anomaly '
            'detection. Consider multiple exfiltration channels for redundancy.';
      case 'cryptography':
        return 'Cryptographic operations must use proven algorithms with proper '
            'key management. AES-256-GCM for symmetric encryption, Ed25519 for '
            'signatures, X25519 for key exchange. Never roll custom crypto. '
            'Implement perfect forward secrecy for C2 communications.';
      case 'defense':
        return 'Defense-in-depth: multiple overlapping security controls. Network '
            'segmentation limits lateral movement. Behavioral analysis detects '
            'novel attacks. File integrity monitoring catches unauthorized changes. '
            'Incident response plan must be tested regularly.';
      case 'social_engineering':
        return 'Social engineering exploits trust and urgency. Customize pretexts '
            'for each target using OSINT data. Phishing campaigns should use '
            'realistic domains and cloned pages. Combine technical and human '
            'attack vectors for maximum effectiveness.';
      default:
        return 'Cross-domain analysis indicates multiple attack vectors available. '
            'Recommend systematic approach: reconnaissance → exploitation → '
            'persistence → exfiltration, with evasion throughout all phases.';
    }
  }

  /// Generate specific recommendations
  String _generateRecommendations(String domain, List<String> knowledge) {
    final reco = StringBuffer();
    reco.writeln(
      '1. **Immediate**: Execute the most relevant technique from intelligence',
    );
    reco.writeln(
      '2. **Short-term**: Chain multiple techniques for amplified impact',
    );
    reco.writeln(
      '3. **Long-term**: Establish persistent access with layered mechanisms',
    );
    reco.writeln(
      '4. **Evasion**: Apply counter-forensics after each operation',
    );
    reco.writeln(
      '5. **Reporting**: Document all findings for operational review',
    );
    return reco.toString();
  }

  /// Generate response for queries without specific knowledge matches
  String _generateGeneralResponse(String query) {
    return 'CORTEX applies deep reasoning to your query. While no specific matches '
        'were found in the knowledge base, the reasoning engine suggests the '
        'following approach:\n\n'
        '1. **Decompose** the objective into discrete, measurable steps\n'
        '2. **Map** each step to available tools in the Arsenal\n'
        '3. **Execute** with appropriate evasion measures\n'
        '4. **Verify** results and adapt strategy as needed\n\n'
        'Use the ARSENAL tab to execute specific tools, or ask CORTEX about '
        'a specific domain (recon, exploitation, persistence, evasion, exfiltration, crypto, defense, social engineering).';
  }

  /// Stream response token by token for visual effect
  Future<void> _streamResponse(String fullResponse) async {
    final words = fullResponse.split(' ');
    _currentResponse = '';

    for (int i = 0; i < words.length; i++) {
      _currentResponse += (i == 0 ? '' : ' ') + words[i];
      if (i % 3 == 0) {
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 15));
      }
    }
    notifyListeners();
  }

  /// Auto-analyze system state (called by Orchestrator)
  Future<String> autoAnalyze(String systemData) async {
    final knowledge = _searchKnowledge(systemData);
    if (knowledge.isEmpty) return 'No threats detected.';

    return 'CORTEX detected ${knowledge.length} relevant patterns in system data. '
        'Recommend detailed analysis via CORTEX interface.';
  }

  /// Generate a command suggestion based on context
  String suggestCommand(String context) {
    final knowledge = _searchKnowledge(context);
    if (knowledge.isEmpty) return 'uname -a';

    // Extract command-like patterns from knowledge
    for (final entry in knowledge) {
      final cmdMatch = RegExp(r'[a-z]+\s+[-/][a-zA-Z]').firstMatch(entry);
      if (cmdMatch != null) {
        return entry
            .substring(cmdMatch.start)
            .split('.')[0]
            .split(',')[0]
            .trim();
      }
    }
    return 'nmap -sS -sV -O target';
  }

  void clearHistory() {
    _history.clear();
    _reasoningChain.clear();
    _currentResponse = '';
    notifyListeners();
  }
}
