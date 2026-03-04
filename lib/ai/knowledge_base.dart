import 'dart:math';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// KNOWLEDGE BASE — Embedded Vector-like Search with BM25 + Relevance Scoring
/// ═══════════════════════════════════════════════════════════════════════════

/// A single knowledge entry with metadata
class KnowledgeEntry {
  final String id;
  final String domain;
  final String content;
  final List<String> tags;
  final int severity; // 0-100
  final String category; // 'offensive', 'defensive', 'intelligence'

  const KnowledgeEntry({
    required this.id,
    required this.domain,
    required this.content,
    required this.tags,
    this.severity = 50,
    this.category = 'offensive',
  });
}

/// Search result with relevance score
class SearchResult {
  final KnowledgeEntry entry;
  final double score;

  const SearchResult({required this.entry, required this.score});
}

/// The Knowledge Base: massive embedded intelligence database
class KnowledgeBase extends ChangeNotifier {
  final List<KnowledgeEntry> _entries = [];
  bool _initialized = false;
  int _totalEntries = 0;

  bool get initialized => _initialized;
  int get totalEntries => _totalEntries;
  int get domainCount => _entries.map((e) => e.domain).toSet().length;

  /// Initialize and load all knowledge packs
  Future<void> initialize() async {
    _entries.clear();

    // ═══════════════════════════════════════════════════════════════════════
    // CVE DATABASE — Common Vulnerabilities and Exposures
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('cve', 'offensive', [
      _e(
        'CVE-2024-3094: XZ Utils backdoor (liblzma). Supply chain compromise affecting SSH authentication. CVSS 10.0.',
        ['xz', 'ssh', 'supply-chain', 'backdoor'],
        100,
      ),
      _e(
        'CVE-2023-44487: HTTP/2 Rapid Reset. DDoS amplification vulnerability in HTTP/2 implementations. CVSS 7.5.',
        ['http2', 'dos', 'ddos', 'rapid-reset'],
        85,
      ),
      _e(
        'CVE-2023-2640: GameOver(lay) Ubuntu kernel privesc via OverlayFS. Allows unprivileged users to gain root.',
        ['kernel', 'privesc', 'ubuntu', 'overlayfs'],
        95,
      ),
      _e(
        'CVE-2022-0847: Dirty Pipe. Linux kernel arbitrary file overwrite via pipe splice. Trivial root escalation.',
        ['kernel', 'privesc', 'linux', 'pipe'],
        98,
      ),
      _e(
        'CVE-2021-44228: Log4Shell. Remote code execution in Apache Log4j via JNDI injection. CVSS 10.0.',
        ['java', 'rce', 'log4j', 'jndi'],
        100,
      ),
      _e(
        'CVE-2021-4034: PwnKit. Polkit pkexec local privilege escalation. Affects most Linux distributions.',
        ['privesc', 'polkit', 'linux', 'suid'],
        95,
      ),
      _e(
        'CVE-2021-3156: Baron Samedit. Sudo heap-based buffer overflow. Root escalation on all Unix-like systems.',
        ['sudo', 'privesc', 'heap', 'overflow'],
        98,
      ),
      _e(
        'CVE-2020-1472: Zerologon. Netlogon protocol cryptographic flaw. Domain admin in 3 seconds.',
        ['windows', 'active-directory', 'crypto', 'netlogon'],
        100,
      ),
      _e(
        'CVE-2019-0708: BlueKeep. RDP remote code execution. Pre-auth, wormable. Modern EternalBlue equivalent.',
        ['rdp', 'rce', 'windows', 'worm'],
        98,
      ),
      _e(
        'CVE-2017-0144: EternalBlue. SMBv1 remote code execution. Used in WannaCry/NotPetya. CVSS 9.3.',
        ['smb', 'rce', 'windows', 'worm'],
        100,
      ),
      _e(
        'CVE-2016-5195: Dirty COW. Linux kernel race condition for arbitrary file write. Universal privesc.',
        ['kernel', 'privesc', 'linux', 'race-condition'],
        95,
      ),
      _e(
        'CVE-2014-0160: Heartbleed. OpenSSL TLS heartbeat extension memory leak. Extract private keys remotely.',
        ['openssl', 'tls', 'memory-leak', 'crypto'],
        95,
      ),
      _e(
        'CVE-2014-6271: Shellshock. Bash function export RCE. Affects CGI, DHCP clients, SSH ForceCommand.',
        ['bash', 'rce', 'cgi', 'injection'],
        98,
      ),
    ]);

    // ═══════════════════════════════════════════════════════════════════════
    // EXPLOIT PATTERNS — Attack Techniques and Methodologies
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('exploit_patterns', 'offensive', [
      _e(
        'Stack-based buffer overflow: overwrite return address with shellcode pointer. Bypass ASLR with info leak.',
        ['memory', 'buffer-overflow', 'stack', 'shellcode'],
        90,
      ),
      _e(
        'Return-Oriented Programming (ROP): chain existing code gadgets to bypass DEP/NX. Find gadgets with ROPgadget.',
        ['rop', 'dep', 'memory', 'exploitation'],
        85,
      ),
      _e(
        'Heap spray: fill heap with NOP sleds + shellcode. Improve exploitation reliability. Common in browser exploits.',
        ['heap', 'spray', 'browser', 'memory'],
        80,
      ),
      _e(
        'Use-After-Free (UAF): exploit dangling pointer after object deallocation. Achieve code execution via vtable overwrite.',
        ['uaf', 'memory', 'vtable', 'heap'],
        90,
      ),
      _e(
        'Format string vulnerability: %n writes to memory, %x leaks stack data. Bypass ASLR and execute shellcode.',
        ['format-string', 'memory', 'leak', 'stack'],
        85,
      ),
      _e(
        'SQL injection UNION: SELECT 1,2,3,...,N -- to determine column count. Extract database schema and data.',
        ['sqli', 'union', 'database', 'web'],
        75,
      ),
      _e(
        'Blind SQL injection: IF(condition, SLEEP(5), 0) for time-based. 1 AND 1=1 vs 1 AND 1=2 for boolean-based.',
        ['sqli', 'blind', 'time-based', 'boolean'],
        75,
      ),
      _e(
        'Server-Side Request Forgery (SSRF): access 169.254.169.254 for cloud metadata. Pivot to internal services.',
        ['ssrf', 'cloud', 'aws', 'metadata'],
        85,
      ),
      _e(
        'XML External Entity (XXE): <!ENTITY xxe SYSTEM "file:///etc/passwd">. Read files, SSRF, DoS via billion laughs.',
        ['xxe', 'xml', 'rce', 'file-read'],
        80,
      ),
      _e(
        'Insecure deserialization: Java (ysoserial), PHP (phpggc), Python (pickle.loads). Achieve RCE via object graphs.',
        ['deserialization', 'rce', 'java', 'python'],
        90,
      ),
      _e(
        'Path traversal: ../../etc/passwd. Bypass with url-encoding (%2e%2e%2f), null bytes, double-encoding.',
        ['traversal', 'lfi', 'file-read', 'bypass'],
        70,
      ),
      _e(
        'Command injection: backticks cmd, subshell, semicolons, pipes. Escape filters with IFS, hex encoding.',
        ['command-injection', 'rce', 'shell', 'bypass'],
        85,
      ),
      _e(
        'JWT attacks: none algorithm, weak secret brute force (jwt-cracker), key confusion (RS256→HS256).',
        ['jwt', 'authentication', 'crypto', 'bypass'],
        80,
      ),
      _e(
        'LDAP injection: )(|(password=*) to bypass filters. Extract directory data. Achieve authentication bypass.',
        ['ldap', 'injection', 'authentication', 'bypass'],
        75,
      ),
      _e(
        'NoSQL injection: gt operator bypasses MongoDB auth. where and regex operators enable data extraction.',
        ['nosql', 'mongodb', 'injection', 'bypass'],
        75,
      ),
    ]);

    // ═══════════════════════════════════════════════════════════════════════
    // PERSISTENCE TECHNIQUES
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('persistence', 'offensive', [
      _e(
        'Crontab persistence: (crontab -l; echo "* * * * * /tmp/.payload") | crontab -. Survives user session termination.',
        ['cron', 'linux', 'scheduled-task'],
        70,
      ),
      _e(
        'Systemd service: create .service file in /etc/systemd/system/ with Restart=always. Kernel-level auto-restart.',
        ['systemd', 'linux', 'service', 'kernel'],
        85,
      ),
      _e(
        'SSH authorized_keys: inject public key into ~/.ssh/authorized_keys. Silent persistent access.',
        ['ssh', 'keys', 'remote-access'],
        75,
      ),
      _e(
        'LD_PRELOAD: export LD_PRELOAD=/path/to/evil.so in /etc/ld.so.preload. Inject into every process.',
        ['ld_preload', 'injection', 'linux', 'preload'],
        90,
      ),
      _e(
        'PAM backdoor: modify pam_unix.so to accept master password. Universal authentication bypass.',
        ['pam', 'authentication', 'backdoor', 'linux'],
        95,
      ),
      _e(
        'Kernel module rootkit: insmod rootkit.ko. Hide processes, files, network connections. Ring-0 persistence.',
        ['rootkit', 'kernel', 'module', 'ring0'],
        98,
      ),
      _e(
        'Git hook injection: echo "payload" > .git/hooks/post-checkout && chmod +x. Executes on git operations.',
        ['git', 'hooks', 'developer', 'supply-chain'],
        70,
      ),
      _e(
        'XDG autostart: create .desktop file in ~/.config/autostart/. Executes at graphical login.',
        ['xdg', 'autostart', 'desktop', 'linux'],
        65,
      ),
      _e(
        'SUID backdoor: cp /bin/bash /tmp/.x && chmod u+s /tmp/.x. Instant root shell via /tmp/.x -p.',
        ['suid', 'backdoor', 'privesc', 'linux'],
        90,
      ),
      _e(
        'AT job: echo "/tmp/payload" | at now + 1 minute. One-time future execution. Survives across reboots.',
        ['at', 'scheduled', 'linux', 'one-time'],
        65,
      ),
    ]);

    // ═══════════════════════════════════════════════════════════════════════
    // EVASION TECHNIQUES
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('evasion', 'offensive', [
      _e(
        'Living-off-the-land: use curl, wget, nc, openssl, python for attacks. No external tools = no AV signatures.',
        ['lotl', 'evasion', 'native', 'antivirus'],
        85,
      ),
      _e(
        'Fileless malware: execute payloads from /dev/shm, /proc/self/fd, or memfd_create(). Never touch disk.',
        ['fileless', 'memory', 'shm', 'evasion'],
        95,
      ),
      _e(
        'Timestomping: touch -r /etc/hostname /tmp/evil. Match file timestamps to legitimate system files.',
        ['timestomping', 'forensics', 'anti-forensics'],
        70,
      ),
      _e(
        'Log evasion: truncate -s 0 /var/log/auth.log. Or use utmpdump/wtmpfix to edit binary logs.',
        ['log', 'anti-forensics', 'evasion'],
        80,
      ),
      _e(
        'DNS tunneling: encode data in DNS TXT queries. Use iodine, dnscat2, or dns2tcp for covert channels.',
        ['dns', 'tunneling', 'covert-channel', 'exfil'],
        85,
      ),
      _e(
        'Process injection via ptrace: PTRACE_ATTACH to target PID, inject shellcode into its memory space.',
        ['ptrace', 'injection', 'process', 'linux'],
        90,
      ),
      _e(
        'Anti-sandbox: check /proc/cpuinfo for VM indicators, timing analysis, user interaction checks.',
        ['sandbox', 'detection', 'vm', 'anti-analysis'],
        80,
      ),
      _e(
        'Polymorphic shellcode: XOR-encode payload with random key. Runtime decoder stub. Each instance unique.',
        ['polymorphic', 'shellcode', 'encoding', 'evasion'],
        90,
      ),
      _e(
        'Traffic mimicry: disguise C2 as legitimate HTTPS, DNS, or SMTP traffic. Domain fronting via CDN.',
        ['traffic', 'mimicry', 'c2', 'domain-fronting'],
        85,
      ),
      _e(
        'Steganography: hide data in PNG/JPEG LSBs. Tools: steghide, zsteg, openstego. Invisible data transfer.',
        ['steganography', 'covert', 'image', 'exfil'],
        75,
      ),
    ]);

    // ═══════════════════════════════════════════════════════════════════════
    // DEFENSE & IDS SIGNATURES
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('defense', 'defensive', [
      _e(
        'Snort rule: alert tcp any any -> any 445 (msg:"EternalBlue attempt"; content:"|FF|SMB"; sid:1000001;)',
        ['snort', 'ids', 'smb', 'detection'],
        80,
      ),
      _e(
        'YARA rule: detect Meterpreter via string patterns stdapi, priv, core_channel. Condition: 2 of them match.',
        ['yara', 'malware', 'meterpreter', 'detection'],
        85,
      ),
      _e(
        'iptables block: iptables -A INPUT -p tcp --dport 445 -j DROP. Block SMB from external networks.',
        ['iptables', 'firewall', 'block', 'smb'],
        70,
      ),
      _e(
        'SELinux enforcement: setenforce 1. Confines processes to MAC policy. Blocks unauthorized access patterns.',
        ['selinux', 'mac', 'linux', 'hardening'],
        80,
      ),
      _e(
        'File integrity: aide --check. AIDE compares current filesystem against known-good baseline. Detects modifications.',
        ['aide', 'integrity', 'monitoring', 'forensics'],
        75,
      ),
      _e(
        'Auditd monitoring: auditctl -w /etc/passwd -p wa -k passwd_changes. Kernel-level file access auditing.',
        ['auditd', 'monitoring', 'kernel', 'linux'],
        80,
      ),
      _e(
        'Fail2ban: monitor auth.log for brute force. Auto-ban IPs after threshold. [sshd] maxretry=3 bantime=3600.',
        ['fail2ban', 'brute-force', 'ssh', 'automation'],
        75,
      ),
      _e(
        'Network segmentation: VLAN isolation reduces lateral movement. Microsegmentation with NFV for zero-trust.',
        ['vlan', 'segmentation', 'zero-trust', 'network'],
        85,
      ),
      _e(
        'Honeypot deployment: canarytokens.org for alerts. OpenCanary for fake services. Detect attacker presence early.',
        ['honeypot', 'canary', 'detection', 'deception'],
        75,
      ),
      _e(
        'Memory forensics: volatility3 -f dump.raw windows.pstree. Analyze process trees, DLL injections, rootkits.',
        ['volatility', 'forensics', 'memory', 'analysis'],
        85,
      ),
    ]);

    // ═══════════════════════════════════════════════════════════════════════
    // NETWORK PROTOCOLS
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('network', 'intelligence', [
      _e(
        'TCP SYN scan: send SYN, receive SYN-ACK (open) or RST (closed). Stealthy: never completes handshake.',
        ['tcp', 'scan', 'syn', 'nmap'],
        70,
      ),
      _e(
        'ARP spoofing: send gratuitous ARP to associate attacker MAC with gateway IP. Enable MITM position.',
        ['arp', 'spoofing', 'mitm', 'layer2'],
        85,
      ),
      _e(
        'BGP hijacking: announce more-specific prefix to redirect traffic. Requires AS peering or compromised router.',
        ['bgp', 'hijack', 'routing', 'isp'],
        95,
      ),
      _e(
        'DNS poisoning: corrupt resolver cache with forged responses. Race condition attack or Kaminsky technique.',
        ['dns', 'poisoning', 'cache', 'redirect'],
        85,
      ),
      _e(
        'VLAN hopping: double-tagging 802.1Q frames. Switch strips outer tag, forwards frame to target VLAN.',
        ['vlan', 'hopping', 'layer2', 'switch'],
        80,
      ),
      _e(
        'DHCP starvation: exhaust DHCP pool with spoofed MAC addresses. Then deploy rogue DHCP for MITM.',
        ['dhcp', 'starvation', 'rogue', 'mitm'],
        80,
      ),
      _e(
        'TLS 1.3: 0-RTT resumption, ECDHE key exchange, AEAD ciphers only. No vulnerable legacy negotiation.',
        ['tls', 'encryption', 'https', 'protocol'],
        65,
      ),
      _e(
        'HTTP/2 HPACK: header compression can leak information via CRIME-like attacks on compressed headers.',
        ['http2', 'compression', 'side-channel', 'crime'],
        70,
      ),
      _e(
        'QUIC protocol: UDP-based, multiplexed, encrypted transport. Bypasses TCP-based DPI and firewalling.',
        ['quic', 'udp', 'encryption', 'bypass'],
        75,
      ),
      _e(
        'IPv6 ND spoofing: equivalent of ARP spoofing for IPv6. ICMPv6 Router Advertisement attacks.',
        ['ipv6', 'nd', 'spoofing', 'icmpv6'],
        80,
      ),
    ]);

    // ═══════════════════════════════════════════════════════════════════════
    // SOCIAL ENGINEERING
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('social_engineering', 'intelligence', [
      _e(
        'Phishing template: urgent password reset email with cloned login page. Harvest credentials in real-time.',
        ['phishing', 'credential', 'email', 'harvesting'],
        80,
      ),
      _e(
        'Spear phishing: personalize using LinkedIn/social media OSINT. Reference specific projects, managers, events.',
        ['spear-phishing', 'targeted', 'osint', 'personalized'],
        85,
      ),
      _e(
        'Pretexting: impersonate IT support, auditor, or vendor. Establish trust before requesting sensitive actions.',
        ['pretexting', 'impersonation', 'trust', 'social'],
        80,
      ),
      _e(
        'Watering hole: compromise website frequented by targets. Deploy browser exploits or credential harvesting.',
        ['watering-hole', 'browser', 'compromise', 'targeted'],
        85,
      ),
      _e(
        'USB drop: prepare HID attack devices (Rubber Ducky). Leave in target parking lot or reception area.',
        ['usb', 'hid', 'physical', 'baiting'],
        75,
      ),
      _e(
        'Vishing: voice phishing via spoofed caller ID. Urgency + authority = high success rate. Record calls for intel.',
        ['vishing', 'voice', 'phone', 'spoofing'],
        80,
      ),
      _e(
        'BEC: Business Email Compromise via executive impersonation. Target wire transfers and sensitive data.',
        ['bec', 'executive', 'wire-fraud', 'impersonation'],
        90,
      ),
      _e(
        'Callback phishing: email instructs target to call attacker-controlled number. Bypass email security filters.',
        ['callback', 'phishing', 'phone', 'bypass'],
        75,
      ),
    ]);

    // ═══════════════════════════════════════════════════════════════════════
    // CRYPTOGRAPHIC ATTACKS
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('cryptography', 'offensive', [
      _e(
        'AES-CBC padding oracle: exploit PKCS#7 padding validation to decrypt ciphertext byte-by-byte.',
        ['aes', 'cbc', 'padding-oracle', 'crypto'],
        85,
      ),
      _e(
        'RSA small exponent: e=3 with small message, cube root attack. Always use OAEP padding.',
        ['rsa', 'small-exponent', 'crypto', 'attack'],
        75,
      ),
      _e(
        'Hash length extension: SHA-256, MD5 vulnerable. Extend MAC without knowing secret. Use HMAC instead.',
        ['hash', 'extension', 'sha256', 'md5'],
        80,
      ),
      _e(
        'Rainbow table attack: precomputed hash chains for fast password cracking. Defeated by per-password salting.',
        ['rainbow', 'hash', 'password', 'cracking'],
        70,
      ),
      _e(
        'Hashcat modes: -m 0 MD5, -m 100 SHA1, -m 1000 NTLM, -m 1800 sha512crypt. GPU-accelerated cracking.',
        ['hashcat', 'cracking', 'gpu', 'password'],
        75,
      ),
      _e(
        'TLS downgrade: force negotiation to weaker cipher. POODLE, BEAST, CRIME, DROWN attacks.',
        ['tls', 'downgrade', 'ssl', 'crypto'],
        80,
      ),
      _e(
        'Certificate pinning bypass: use Frida + objection to disable SSL pinning at runtime. MITM HTTPS traffic.',
        ['pinning', 'bypass', 'frida', 'mitm'],
        85,
      ),
      _e(
        'Kerberoasting: request TGS tickets for service accounts, crack offline with hashcat -m 13100.',
        ['kerberos', 'active-directory', 'cracking', 'windows'],
        85,
      ),
    ]);

    // ═══════════════════════════════════════════════════════════════════════
    // OSINT TECHNIQUES
    // ═══════════════════════════════════════════════════════════════════════
    _addEntries('osint', 'intelligence', [
      _e(
        'Shodan dorks: "port:22 country:US org:target". Find internet-facing assets with known vulnerabilities.',
        ['shodan', 'dork', 'asset-discovery', 'iot'],
        80,
      ),
      _e(
        'Google dorking: site:target.com filetype:pdf OR filetype:xlsx. Find exposed documents and data.',
        ['google', 'dork', 'document', 'exposure'],
        75,
      ),
      _e(
        'Certificate Transparency: crt.sh search. Discover subdomains via SSL certificate issuance logs.',
        ['certificate', 'transparency', 'subdomain', 'recon'],
        70,
      ),
      _e(
        'WHOIS history: DomainTools, SecurityTrails. Track domain ownership changes, reveal hidden infrastructure.',
        ['whois', 'domain', 'history', 'infrastructure'],
        70,
      ),
      _e(
        'GitHub recon: search repos for api_key, password, secret, token. Trufflehog for automated credential scanning.',
        ['github', 'secrets', 'credentials', 'code'],
        85,
      ),
      _e(
        'Social media OSINT: LinkedIn for org chart, Twitter for tech stack mentions, GitHub for code patterns.',
        ['social', 'linkedin', 'twitter', 'profiling'],
        75,
      ),
      _e(
        'Email enumeration: hunter.io, phonebook.cz, SMTP VRFY/RCPT TO. Build target email list for phishing.',
        ['email', 'enumeration', 'harvest', 'phishing'],
        75,
      ),
      _e(
        'Wayback Machine: web.archive.org for historical site versions. Find removed sensitive pages and data.',
        ['wayback', 'archive', 'history', 'exposure'],
        70,
      ),
    ]);

    _totalEntries = _entries.length;
    _initialized = true;
    notifyListeners();
  }

  /// Helper to create entries
  KnowledgeEntry _e(String content, List<String> tags, int severity) {
    return KnowledgeEntry(
      id: '${_entries.length}',
      domain: '',
      content: content,
      tags: tags,
      severity: severity,
    );
  }

  /// Add entries to a domain
  void _addEntries(
    String domain,
    String category,
    List<KnowledgeEntry> entries,
  ) {
    for (final e in entries) {
      _entries.add(
        KnowledgeEntry(
          id: '${domain}_${_entries.length}',
          domain: domain,
          content: e.content,
          tags: e.tags,
          severity: e.severity,
          category: category,
        ),
      );
    }
  }

  /// Hybrid search: keyword + tag matching with BM25-inspired scoring
  List<SearchResult> search(
    String query, {
    int limit = 20,
    String? domain,
    String? category,
  }) {
    final queryLower = query.toLowerCase();
    final queryTokens = queryLower
        .split(RegExp(r'[\s,;.!?]+'))
        .where((t) => t.length >= 2)
        .toList();
    final results = <SearchResult>[];

    for (final entry in _entries) {
      // Apply filters
      if (domain != null && entry.domain != domain) continue;
      if (category != null && entry.category != category) continue;

      double score = 0;
      final contentLower = entry.content.toLowerCase();

      // ── BM25-inspired term frequency scoring ──────────────────────────
      for (final token in queryTokens) {
        // Content matches
        final termFreq = token.allMatches(contentLower).length;
        if (termFreq > 0) {
          // BM25-like: saturating tf with k1=1.5
          score += (termFreq * 2.5) / (termFreq + 1.5);
        }

        // Tag exact matches (higher weight)
        if (entry.tags.any((t) => t.contains(token))) {
          score += 3.0;
        }

        // Domain match bonus
        if (entry.domain.contains(token)) {
          score += 2.0;
        }
      }

      // Severity weight (higher severity = slightly higher relevance)
      score *= (1.0 + entry.severity / 200.0);

      if (score > 0) {
        results.add(SearchResult(entry: entry, score: score));
      }
    }

    // Sort by relevance
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// Get all entries for a domain
  List<KnowledgeEntry> getByDomain(String domain) {
    return _entries.where((e) => e.domain == domain).toList();
  }

  /// Get all unique domains
  List<String> get domains => _entries.map((e) => e.domain).toSet().toList();

  /// Get entries by category
  List<KnowledgeEntry> getByCategory(String category) {
    return _entries.where((e) => e.category == category).toList();
  }

  /// Get statistics
  Map<String, int> get statistics {
    final stats = <String, int>{};
    for (final entry in _entries) {
      stats[entry.domain] = (stats[entry.domain] ?? 0) + 1;
    }
    return stats;
  }
}
