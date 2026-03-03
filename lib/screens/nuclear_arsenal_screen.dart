import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/terminal_service.dart';
import '../services/warfare_service.dart';
import '../main.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// NEMESIS ARSENAL: Full Nuclear Warfare Interface
/// 6 Categories × Multiple Tools = Complete Digital Warhead
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Tool Definition Model ──────────────────────────────────────────────────
class _NemesisTool {
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final String command;
  final String module;
  final bool background;

  const _NemesisTool({
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.command,
    required this.module,
    this.background = false,
  });
}

// ─── Module Definition ──────────────────────────────────────────────────────
class _WarModule {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_NemesisTool> tools;

  const _WarModule({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tools,
  });
}

// ─── Tool Definitions ───────────────────────────────────────────────────────
final bool _isAndroid = Platform.isAndroid;

final List<_WarModule> _warModules = [
  // ═════════════════════════════════════════════════════════════════════════
  // MODULE 1: RECON — Intelligence Gathering
  // ═════════════════════════════════════════════════════════════════════════
  _WarModule(
    name: 'RECON',
    subtitle: 'Intelligence & Reconnaissance',
    icon: Icons.radar,
    color: kCyan,
    tools: [
      _NemesisTool(
        label: 'NETWORK MAP',
        desc: 'Map all network interfaces & IPs',
        icon: Icons.lan,
        color: kCyan,
        command: _isAndroid ? 'ip addr show' : 'ip -c addr show',
        module: 'RECON',
      ),
      _NemesisTool(
        label: 'ARP TABLE',
        desc: 'Discover neighboring hosts via ARP',
        icon: Icons.hub,
        color: kCyan,
        command: _isAndroid ? 'ip neigh show' : 'ip -c neigh show',
        module: 'RECON',
      ),
      _NemesisTool(
        label: 'PORT SCAN',
        desc: 'Enumerate open ports & listeners',
        icon: Icons.lock_open,
        color: kCyan,
        command: _isAndroid ? 'cat /proc/net/tcp | head -20' : 'ss -tulpn',
        module: 'RECON',
      ),
      _NemesisTool(
        label: 'DNS RECON',
        desc: 'Resolve & enumerate DNS records',
        icon: Icons.dns,
        color: kCyan,
        command: _isAndroid
            ? 'getprop net.dns1 && getprop net.dns2'
            : 'cat /etc/resolv.conf',
        module: 'RECON',
      ),
      _NemesisTool(
        label: 'ROUTE TABLE',
        desc: 'Display routing table & gateways',
        icon: Icons.alt_route,
        color: kCyan,
        command: 'ip route show',
        module: 'RECON',
      ),
      _NemesisTool(
        label: 'WIFI SCAN',
        desc: 'Enumerate nearby wireless networks',
        icon: Icons.wifi_find,
        color: kCyan,
        command: _isAndroid
            ? 'dumpsys wifi | grep -E "SSID|BSSID|level" | head -30'
            : 'iwlist wlan0 scan 2>/dev/null | grep -E "ESSID|Signal" | head -20',
        module: 'RECON',
      ),
      _NemesisTool(
        label: 'ACTIVE CONNS',
        desc: 'Show all established connections',
        icon: Icons.cable,
        color: kCyan,
        command: _isAndroid
            ? 'cat /proc/net/tcp6 | head -20'
            : 'ss -tn state established',
        module: 'RECON',
      ),
      _NemesisTool(
        label: 'TRACEROUTE',
        desc: 'Trace packet route to target',
        icon: Icons.timeline,
        color: kCyan,
        command: _isAndroid
            ? 'tracepath 8.8.8.8 2>/dev/null | head -15'
            : 'traceroute -m 15 8.8.8.8 2>/dev/null || tracepath 8.8.8.8 2>/dev/null | head -15',
        module: 'RECON',
      ),
    ],
  ),

  // ═════════════════════════════════════════════════════════════════════════
  // MODULE 2: EXPLOIT — Vulnerability Assessment & Exploitation
  // ═════════════════════════════════════════════════════════════════════════
  _WarModule(
    name: 'EXPLOIT',
    subtitle: 'Vulnerability & Payload Engine',
    icon: Icons.bolt,
    color: kRed,
    tools: [
      _NemesisTool(
        label: 'SUID FINDER',
        desc: 'Locate SUID/SGID binaries for privesc',
        icon: Icons.security,
        color: kRed,
        command: 'find / -perm -4000 -type f 2>/dev/null | head -20',
        module: 'EXPLOIT',
      ),
      _NemesisTool(
        label: 'WRITABLE FILES',
        desc: 'Find world-writable files & dirs',
        icon: Icons.edit_note,
        color: kRed,
        command:
            'find / -writable -type f 2>/dev/null | grep -v proc | head -20',
        module: 'EXPLOIT',
      ),
      _NemesisTool(
        label: 'KERNEL VER',
        desc: 'Fingerprint kernel for known CVEs',
        icon: Icons.bug_report,
        color: kRed,
        command: 'uname -a && cat /proc/version',
        module: 'EXPLOIT',
      ),
      _NemesisTool(
        label: 'CRON JOBS',
        desc: 'Enumerate scheduled tasks for injection',
        icon: Icons.schedule,
        color: kRed,
        command: _isAndroid
            ? 'ls -la /data/crontab 2>/dev/null || echo "No crontab access"'
            : 'crontab -l 2>/dev/null; ls -la /etc/cron* 2>/dev/null | head -20',
        module: 'EXPLOIT',
      ),
      _NemesisTool(
        label: 'PASSWD DUMP',
        desc: 'Extract user accounts & hashes',
        icon: Icons.key,
        color: kRed,
        command: 'cat /etc/passwd 2>/dev/null | head -20',
        module: 'EXPLOIT',
      ),
      _NemesisTool(
        label: 'SHADOW PROBE',
        desc: 'Attempt to read shadow password file',
        icon: Icons.visibility_off,
        color: kRed,
        command:
            'cat /etc/shadow 2>/dev/null || echo "[ACCESS DENIED] Requires root"',
        module: 'EXPLOIT',
      ),
      _NemesisTool(
        label: 'SSH KEYS',
        desc: 'Hunt for SSH private keys',
        icon: Icons.vpn_key,
        color: kRed,
        command:
            'find / -name "id_rsa" -o -name "id_ed25519" -o -name "*.pem" 2>/dev/null | head -15',
        module: 'EXPLOIT',
      ),
      _NemesisTool(
        label: 'CAPABILITIES',
        desc: 'Find binaries with elevated capabilities',
        icon: Icons.admin_panel_settings,
        color: kRed,
        command: _isAndroid
            ? 'ls -la /system/bin/ | head -20'
            : 'getcap -r / 2>/dev/null | head -20',
        module: 'EXPLOIT',
      ),
    ],
  ),

  // ═════════════════════════════════════════════════════════════════════════
  // MODULE 3: PERSIST — Maintaining Access
  // ═════════════════════════════════════════════════════════════════════════
  _WarModule(
    name: 'PERSIST',
    subtitle: 'Backdoor & Persistence Engine',
    icon: Icons.all_inclusive,
    color: kPurple,
    tools: [
      _NemesisTool(
        label: 'STARTUP HOOKS',
        desc: 'List all startup services & hooks',
        icon: Icons.play_circle,
        color: kPurple,
        command: _isAndroid
            ? 'getprop | grep boot | head -15'
            : 'systemctl list-unit-files --state=enabled 2>/dev/null | head -20',
        module: 'PERSIST',
      ),
      _NemesisTool(
        label: 'RC.LOCAL',
        desc: 'Check local startup script injection point',
        icon: Icons.code,
        color: kPurple,
        command:
            'cat /etc/rc.local 2>/dev/null || echo "[INFO] rc.local not found"',
        module: 'PERSIST',
      ),
      _NemesisTool(
        label: 'BASHRC HOOK',
        desc: 'Inspect shell startup files for hooks',
        icon: Icons.terminal,
        color: kPurple,
        command:
            'cat ~/.bashrc 2>/dev/null | tail -20; cat ~/.profile 2>/dev/null | tail -10',
        module: 'PERSIST',
      ),
      _NemesisTool(
        label: 'SYSTEMD UNIT',
        desc: 'List custom systemd services',
        icon: Icons.settings,
        color: kPurple,
        command: _isAndroid
            ? 'ls -la /data/local/tmp/ 2>/dev/null'
            : 'ls -la /etc/systemd/system/*.service 2>/dev/null; ls -la ~/.config/systemd/ 2>/dev/null',
        module: 'PERSIST',
      ),
      _NemesisTool(
        label: 'HIDDEN FILES',
        desc: 'Scan for hidden files in home & system dirs',
        icon: Icons.folder_special,
        color: kPurple,
        command: 'find /home -name ".*" -type f 2>/dev/null | head -20',
        module: 'PERSIST',
      ),
      _NemesisTool(
        label: 'LOADED MODULES',
        desc: 'Enumerate loaded kernel modules',
        icon: Icons.memory,
        color: kPurple,
        command: _isAndroid
            ? 'lsmod 2>/dev/null || cat /proc/modules | head -20'
            : 'lsmod | head -20',
        module: 'PERSIST',
      ),
    ],
  ),

  // ═════════════════════════════════════════════════════════════════════════
  // MODULE 4: SABOTAGE — Disruption & Denial
  // ═════════════════════════════════════════════════════════════════════════
  _WarModule(
    name: 'SABOTAGE',
    subtitle: 'Disruption & Denial Operations',
    icon: Icons.dangerous,
    color: kOrange,
    tools: [
      _NemesisTool(
        label: 'CPU STRESS',
        desc: 'Saturate all CPU cores to 100%',
        icon: Icons.whatshot,
        color: kOrange,
        command:
            'echo "[BLACKOUT] CPU stress initiated" && for i in \$(seq 1 \$(nproc)); do yes > /dev/null & done',
        module: 'SABOTAGE',
        background: true,
      ),
      _NemesisTool(
        label: 'KILL STRESS',
        desc: 'Terminate all stress operations',
        icon: Icons.cancel,
        color: kOrange,
        command: 'killall yes 2>/dev/null; echo "[BLACKOUT] Stress terminated"',
        module: 'SABOTAGE',
      ),
      _NemesisTool(
        label: 'MEMORY BOMB',
        desc: 'Consume available RAM rapidly',
        icon: Icons.storage,
        color: kOrange,
        command:
            'echo "[BLACKOUT] Memory pressure test" && head -c 100M /dev/zero | cat > /dev/null',
        module: 'SABOTAGE',
      ),
      _NemesisTool(
        label: 'DISK FILL',
        desc: 'Monitor disk space for fill potential',
        icon: Icons.disc_full,
        color: kOrange,
        command: 'df -h && echo "---" && du -sh /tmp 2>/dev/null',
        module: 'SABOTAGE',
      ),
      _NemesisTool(
        label: 'PROC KILL',
        desc: 'List and target specific processes',
        icon: Icons.gps_off,
        color: kOrange,
        command: _isAndroid
            ? 'ps -A | head -20'
            : 'ps aux --sort=-%cpu | head -15',
        module: 'SABOTAGE',
      ),
      _NemesisTool(
        label: 'LOG WIPE',
        desc: 'Enumerate and assess log files',
        icon: Icons.delete_sweep,
        color: kOrange,
        command: _isAndroid
            ? 'logcat -d | tail -20'
            : 'ls -lh /var/log/*.log 2>/dev/null | head -15',
        module: 'SABOTAGE',
      ),
    ],
  ),

  // ═════════════════════════════════════════════════════════════════════════
  // MODULE 5: EXFIL — Data Extraction & Siphoning
  // ═════════════════════════════════════════════════════════════════════════
  _WarModule(
    name: 'EXFIL',
    subtitle: 'Data Extraction & Siphoning',
    icon: Icons.cloud_download,
    color: const Color(0xFF00BFA5),
    tools: [
      _NemesisTool(
        label: 'DOC HUNTER',
        desc: 'Locate sensitive documents (.pdf, .docx, .xlsx)',
        icon: Icons.find_in_page,
        color: const Color(0xFF00BFA5),
        command:
            'find / -type f \\( -name "*.pdf" -o -name "*.docx" -o -name "*.xlsx" -o -name "*.csv" \\) 2>/dev/null | head -25',
        module: 'EXFIL',
      ),
      _NemesisTool(
        label: 'DB SCANNER',
        desc: 'Find database files (.db, .sqlite, .sql)',
        icon: Icons.table_chart,
        color: const Color(0xFF00BFA5),
        command:
            'find / -type f \\( -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" -o -name "*.sql" \\) 2>/dev/null | head -25',
        module: 'EXFIL',
      ),
      _NemesisTool(
        label: 'CREDENTIAL SWEEP',
        desc: 'Grep for passwords & API keys in configs',
        icon: Icons.password,
        color: const Color(0xFF00BFA5),
        command:
            'grep -ril "password\\|api_key\\|secret\\|token" /etc/ /home/ 2>/dev/null | head -20',
        module: 'EXFIL',
      ),
      _NemesisTool(
        label: 'MEDIA SCAN',
        desc: 'Locate images, videos & audio files',
        icon: Icons.perm_media,
        color: const Color(0xFF00BFA5),
        command: _isAndroid
            ? 'find /sdcard -type f \\( -name "*.jpg" -o -name "*.mp4" -o -name "*.mp3" \\) 2>/dev/null | head -25'
            : 'find /home -type f \\( -name "*.jpg" -o -name "*.png" -o -name "*.mp4" \\) 2>/dev/null | head -25',
        module: 'EXFIL',
      ),
      _NemesisTool(
        label: 'GIT SECRETS',
        desc: 'Scan git repositories for secrets',
        icon: Icons.source,
        color: const Color(0xFF00BFA5),
        command: 'find / -name ".git" -type d 2>/dev/null | head -10',
        module: 'EXFIL',
      ),
      _NemesisTool(
        label: 'ENV HARVEST',
        desc: 'Extract all environment variables',
        icon: Icons.eco,
        color: const Color(0xFF00BFA5),
        command: 'env | sort',
        module: 'EXFIL',
      ),
      _NemesisTool(
        label: 'BROWSER DATA',
        desc: 'Locate browser profiles & cookies',
        icon: Icons.web,
        color: const Color(0xFF00BFA5),
        command: _isAndroid
            ? 'find /data/data -name "cookies.db" -o -name "Cookies" 2>/dev/null | head -10'
            : 'find ~/.mozilla ~/.config/google-chrome ~/.config/chromium -name "Cookies" -o -name "Login Data" 2>/dev/null | head -15',
        module: 'EXFIL',
      ),
    ],
  ),

  // ═════════════════════════════════════════════════════════════════════════
  // MODULE 6: CRYPTO — Cryptographic Operations
  // ═════════════════════════════════════════════════════════════════════════
  _WarModule(
    name: 'CRYPTO',
    subtitle: 'Cryptographic Warfare Tools',
    icon: Icons.enhanced_encryption,
    color: const Color(0xFFFFD600),
    tools: [
      _NemesisTool(
        label: 'HASH FILE',
        desc: 'Generate SHA256 hash of a target file',
        icon: Icons.fingerprint,
        color: const Color(0xFFFFD600),
        command:
            'echo "Enter file path to hash:" && sha256sum /etc/hostname 2>/dev/null',
        module: 'CRYPTO',
      ),
      _NemesisTool(
        label: 'SSL CERTS',
        desc: 'Enumerate installed SSL certificates',
        icon: Icons.verified_user,
        color: const Color(0xFFFFD600),
        command: _isAndroid
            ? 'ls /system/etc/security/cacerts/ 2>/dev/null | head -20'
            : 'ls /etc/ssl/certs/ 2>/dev/null | head -20',
        module: 'CRYPTO',
      ),
      _NemesisTool(
        label: 'KEY SEARCH',
        desc: 'Hunt for private keys & certificates',
        icon: Icons.vpn_key,
        color: const Color(0xFFFFD600),
        command:
            'find / -type f \\( -name "*.key" -o -name "*.crt" -o -name "*.pem" -o -name "*.p12" \\) 2>/dev/null | head -20',
        module: 'CRYPTO',
      ),
      _NemesisTool(
        label: 'RANDOM GEN',
        desc: 'Generate cryptographically secure random bytes',
        icon: Icons.casino,
        color: const Color(0xFFFFD600),
        command:
            'head -c 32 /dev/urandom | xxd 2>/dev/null || head -c 32 /dev/urandom | od -A x -t x1z -v',
        module: 'CRYPTO',
      ),
      _NemesisTool(
        label: 'CIPHER CHECK',
        desc: 'List available OpenSSL ciphers',
        icon: Icons.lock_clock,
        color: const Color(0xFFFFD600),
        command:
            'openssl ciphers -v 2>/dev/null | head -20 || echo "[INFO] OpenSSL not available"',
        module: 'CRYPTO',
      ),
      _NemesisTool(
        label: 'BASE64 TOOL',
        desc: 'Encode/decode base64 data',
        icon: Icons.transform,
        color: const Color(0xFFFFD600),
        command:
            'echo "NEMESIS_CORE_ACTIVE" | base64 && echo "---" && echo "TkVNRVNJU19DT1JFX0FDVElWRQ==" | base64 -d',
        module: 'CRYPTO',
      ),
    ],
  ),
];

// ═════════════════════════════════════════════════════════════════════════════
// NUCLEAR ARSENAL SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class NuclearArsenalScreen extends StatefulWidget {
  const NuclearArsenalScreen({super.key});

  @override
  State<NuclearArsenalScreen> createState() => _NuclearArsenalScreenState();
}

class _NuclearArsenalScreenState extends State<NuclearArsenalScreen>
    with SingleTickerProviderStateMixin {
  int _selectedModule = -1; // -1 = show all modules grid
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedModule == -1) {
      return _buildModuleGrid();
    }
    return _buildToolList(_warModules[_selectedModule]);
  }

  // ─── Module Selection Grid ──────────────────────────────────────────────
  Widget _buildModuleGrid() {
    return Column(
      children: [
        // Nuclear status bar
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, _) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kRed.withAlpha((_pulseAnim.value * 15).toInt()),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kRed.withAlpha((_pulseAnim.value * 60).toInt()),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: kRed, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'NUCLEAR ARSENAL • ${_warModules.length} MODULES • ${_warModules.fold<int>(0, (s, m) => s + m.tools.length)} TOOLS',
                      style: GoogleFonts.firaCode(
                        fontSize: 10,
                        color: kRed,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Module grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: _warModules.length,
            itemBuilder: (context, index) {
              final mod = _warModules[index];
              return _ModuleCard(
                module: mod,
                onTap: () => setState(() => _selectedModule = index),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Tool List for a Selected Module ────────────────────────────────────
  Widget _buildToolList(_WarModule module) {
    final terminal = Provider.of<TerminalService>(context, listen: false);
    final warfare = Provider.of<WarfareService>(context, listen: false);

    return Column(
      children: [
        // Back bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedModule = -1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: module.color.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: module.color.withAlpha(40)),
                  ),
                  child: Icon(Icons.arrow_back, color: module.color, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Icon(module.icon, color: module.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.name,
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: module.color,
                        letterSpacing: 3,
                      ),
                    ),
                    Text(
                      module.subtitle,
                      style: GoogleFonts.firaCode(
                        fontSize: 9,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: module.color.withAlpha(60)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${module.tools.length} TOOLS',
                  style: GoogleFonts.firaCode(fontSize: 9, color: module.color),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF1A1A1A), height: 1),
        // Tools list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: module.tools.length,
            itemBuilder: (context, index) {
              final tool = module.tools[index];
              return _WarToolCard(
                tool: tool,
                onExecute: () {
                  warfare.executeTerminalTool(
                    module: tool.module,
                    tool: tool.label,
                    command: tool.command,
                    sendCommand: terminal.sendCommand,
                  );
                  MainShell.switchToTab(0);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Module Card Widget ─────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final _WarModule module;
  final VoidCallback onTap;

  const _ModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: module.color.withAlpha(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kCardDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: module.color.withAlpha(25)),
            boxShadow: [
              BoxShadow(
                color: module.color.withAlpha(6),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: module.color.withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(module.icon, color: module.color, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: module.color.withAlpha(40)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${module.tools.length}',
                      style: GoogleFonts.firaCode(
                        fontSize: 10,
                        color: module.color,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.subtitle,
                    style: GoogleFonts.firaCode(
                      fontSize: 8,
                      color: Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── War Tool Card Widget ───────────────────────────────────────────────────
class _WarToolCard extends StatefulWidget {
  final _NemesisTool tool;
  final VoidCallback onExecute;

  const _WarToolCard({required this.tool, required this.onExecute});

  @override
  State<_WarToolCard> createState() => _WarToolCardState();
}

class _WarToolCardState extends State<_WarToolCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _flashCtrl;

  @override
  void initState() {
    super.initState();
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() => _pressed = true);
    _flashCtrl.forward().then((_) {
      _flashCtrl.reverse();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _pressed = false);
      });
    });
    widget.onExecute();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flashCtrl,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _onTap,
              borderRadius: BorderRadius.circular(12),
              splashColor: widget.tool.color.withAlpha(30),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _pressed ? widget.tool.color.withAlpha(15) : kCardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pressed
                        ? widget.tool.color.withAlpha(80)
                        : widget.tool.color.withAlpha(20),
                  ),
                  boxShadow: _pressed
                      ? [
                          BoxShadow(
                            color: widget.tool.color.withAlpha(20),
                            blurRadius: 12,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.tool.color.withAlpha(10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.tool.color.withAlpha(25),
                        ),
                      ),
                      child: Icon(
                        widget.tool.icon,
                        color: widget.tool.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tool.label,
                            style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.tool.desc,
                            style: GoogleFonts.firaCode(
                              fontSize: 9,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.tool.background)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.sync,
                          color: widget.tool.color.withAlpha(60),
                          size: 14,
                        ),
                      ),
                    Icon(
                      Icons.play_arrow_rounded,
                      color: _pressed
                          ? widget.tool.color
                          : widget.tool.color.withAlpha(50),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
