import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/tool_item.dart';
import 'services/terminal_service.dart';
import 'utils/responsive.dart';
import 'constants/mobile_constants.dart';
import 'widgets/mobile_optimized_terminal.dart';
import 'widgets/adaptive_dashboard.dart';
import 'widgets/adaptive_tools_grid.dart';
import 'widgets/floating_tools_button.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
      title: 'NEMESIS_CORE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: MobileConstants.darkBackground,
        textTheme: GoogleFonts.firaCodeTextTheme(ThemeData.dark().textTheme),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A0A0A),
          selectedItemColor: MobileConstants.matrixGreen,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          centerTitle: true,
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

class _MainControlScreenState extends State<MainControlScreen> 
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  
  final List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _screens.addAll([
      const TerminalScreen(),
      const DashboardScreen(),
      const ToolsScreen(),
    ]);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: MobileConstants.animationDuration,
      curve: Curves.easeInOut,
    );
  }
  
  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    
    if (details.primaryVelocity! < 0 && _currentIndex < 2) {
      _onNavItemTapped(_currentIndex + 1);
    } else if (details.primaryVelocity! > 0 && _currentIndex > 0) {
      _onNavItemTapped(_currentIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final appBarHeight = ResponsiveUtils.getAppBarHeight(context);
    final bottomNavHeight = ResponsiveUtils.getBottomNavHeight(context);
    final titleFontSize = ResponsiveUtils.getAdaptiveFontSize(context, 16);
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: AppBar(
          title: Text(
            'NEMESIS_EVOLUTION v7.7',
            style: GoogleFonts.outfit(
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: MobileConstants.matrixGreen,
              fontSize: titleFontSize,
            ),
          ),
          actions: const [_StatusIndicator()],
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: isMobile ? _onHorizontalDrag : null,
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: isMobile 
            ? const BouncingScrollPhysics() 
            : const NeverScrollableScrollPhysics(),
          children: _screens,
        ),
      ),
      floatingActionButton: _currentIndex == 0 
        ? const _TerminalFloatingActions()
        : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border(
            top: BorderSide(
              color: MobileConstants.matrixGreen.withAlpha(30),
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: bottomNavHeight,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onNavItemTapped,
              iconSize: isMobile ? 20 : 24,
              selectedFontSize: isMobile ? 10 : 12,
              unselectedFontSize: isMobile ? 10 : 12,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.terminal),
                  activeIcon: Icon(Icons.terminal, color: MobileConstants.matrixGreen),
                  label: 'TERMINAL',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  activeIcon: Icon(Icons.analytics, color: MobileConstants.matrixGreen),
                  label: 'STATS',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view),
                  activeIcon: Icon(Icons.grid_view, color: MobileConstants.matrixGreen),
                  label: 'ARSENAL',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator();

  @override
  Widget build(BuildContext context) {
    final connected = context.watch<TerminalService>().isConnected;
    final isMobile = ResponsiveUtils.isMobile(context);
    final dotSize = isMobile ? 8.0 : 10.0;
    final fontSize = ResponsiveUtils.getAdaptiveFontSize(context, 9);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? MobileConstants.matrixGreen : Colors.red,
              boxShadow: [
                BoxShadow(
                  color: (connected ? MobileConstants.matrixGreen : Colors.red)
                      .withAlpha(100),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 6 : 8),
          Text(
            connected ? 'ONLINE' : 'OFFLINE',
            style: GoogleFonts.firaCode(
              fontSize: fontSize,
              color: connected ? MobileConstants.matrixGreen : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TerminalFloatingActions extends StatelessWidget {
  const _TerminalFloatingActions();

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TerminalService>(context, listen: false);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    if (!isMobile) return const SizedBox.shrink();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'keyboard',
          backgroundColor: MobileConstants.cardBackground,
          onPressed: () {
            // Show keyboard
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: const Icon(Icons.keyboard, color: MobileConstants.matrixGreen),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'tools',
          backgroundColor: MobileConstants.matrixGreen,
          onPressed: () {
            _showQuickTools(context, service);
          },
          child: const Icon(
            Icons.grid_view,
            color: MobileConstants.darkBackground,
          ),
        ),
      ],
    );
  }
  
  void _showQuickTools(BuildContext context, TerminalService service) {
    final tools = [
      const ToolItem(label: "NET SCAN", icon: Icons.radar, command: "sudo nmap -T4 -F localhost"),
      const ToolItem(label: "WHOAMI", icon: Icons.person_search, command: "whoami && id"),
      const ToolItem(label: "SYS INFO", icon: Icons.info_outline, command: "uname -a"),
      const ToolItem(label: "PROCESSES", icon: Icons.list_alt, command: "ps aux --sort=-%mem | head -5"),
      const ToolItem(label: "NET STAT", icon: Icons.network_check, command: "ss -tulpn"),
      const ToolItem(label: "LOGS", icon: Icons.history, command: "tail -n 20 /var/log/syslog"),
    ];
    
    FloatingToolsButton(
      tools: tools,
      onToolSelected: service.sendCommand,
    ).showToolsMenu(context);
  }
}

class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TerminalService>(context);
    final terminal = service.terminal;
    final maxLines = 1000;
    
    return MobileOptimizedTerminal(
      terminal: terminal,
      onClearScreen: () {
        if (terminal.buffer.height > maxLines) {
          terminal.buffer.clear();
        }
        service.sendCommand('clear');
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TerminalService>().stats;
    
    return AdaptiveDashboard(
      cpu: stats.cpu,
      ram: stats.ram,
      netSent: stats.netSent,
      netRecv: stats.netRecv,
    );
  }
}

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final service = Provider.of<TerminalService>(context, listen: false);
    
    final tools = [
      const ToolItem(label: "NET SCAN", icon: Icons.radar, command: "sudo nmap -T4 -F localhost"),
      const ToolItem(label: "WHOAMI", icon: Icons.person_search, command: "whoami && id"),
      const ToolItem(label: "SYS INFO", icon: Icons.info_outline, command: "uname -a"),
      const ToolItem(label: "PROCESSES", icon: Icons.list_alt, command: "ps aux --sort=-%mem | head -5"),
      const ToolItem(label: "NET STAT", icon: Icons.network_check, command: "ss -tulpn"),
      const ToolItem(label: "LOGS", icon: Icons.history, command: "tail -n 20 /var/log/syslog"),
    ];
    
    return AdaptiveToolsGrid(
      tools: tools,
      onToolSelected: service.sendCommand,
    );
  }
}
