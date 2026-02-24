import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sfx_service.dart';
import 'ai_workout_screen.dart';
import 'daily_check_in_screen.dart';
import 'mission_control_screen.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen>
    with TickerProviderStateMixin {
  int _tabIndex = 0;
  late AnimationController _scanlineController;
  late AnimationController _glitchController;

  @override
  void initState() {
    super.initState();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _scanlineController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    SfxService.tap();
    _glitchController.forward(from: 0);
    setState(() => _tabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const MissionControlScreen(),
      const DailyCheckInScreen(),
      AIWorkoutScreen(),
    ];

    return Theme(
      data: _tacticalTheme(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0C0A),
        appBar: _TacticalAppBar(tabIndex: _tabIndex),
        body: AnimatedBuilder(
          animation: _scanlineController,
          builder: (context, child) {
            return CustomPaint(
              painter: _ScanlinePainter(_scanlineController.value),
              child: child,
            );
          },
          child: IndexedStack(
            index: _tabIndex,
            children: pages,
          ),
        ),
        bottomNavigationBar: _TacticalNavBar(
          selectedIndex: _tabIndex,
          onSelected: _onTabSelected,
        ),
      ),
    );
  }

  ThemeData _tacticalTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0C0A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD4A017),
        secondary: Color(0xFF4CAF50),
        surface: Color(0xFF111411),
        onPrimary: Color(0xFF0A0C0A),
        onSurface: Color(0xFFCDD4C0),
      ),
      fontFamily: 'monospace',
    );
  }
}

class _TacticalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int tabIndex;

  const _TacticalAppBar({required this.tabIndex});

  static const _titles = [
    'MISSION CONTROL',
    'DAILY CHECK-IN',
    'ZENITH // AI COACH',
  ];

  static const _subtitles = [
    'OPERATIONAL OVERVIEW',
    'STATUS REPORT',
    'NEURAL INTERFACE',
  ];

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFD4A017);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F0D),
        border: Border(
          bottom: BorderSide(color: amber, width: 1.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const _BracketDecoration(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'OP: JAWLINE  //  ${_subtitles[tabIndex]}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: amber,
                              letterSpacing: 1.6,
                            ).copyWith(
                              color: amber.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: FittedBox(
                        key: ValueKey(_titles[tabIndex]),
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _titles[tabIndex],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCDD4C0),
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(
                width: 78,
                child: _MissionClock(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BracketDecoration extends StatelessWidget {
  const _BracketDecoration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 36,
      child: CustomPaint(painter: _BracketPainter()),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A017)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MissionClock extends StatefulWidget {
  const _MissionClock();

  @override
  State<_MissionClock> createState() => _MissionClockState();
}

class _MissionClockState extends State<_MissionClock> {
  late String _time;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    final now = DateTime.now();
    _time =
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'ZULU',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: const Color(0xFFD4A017).withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
          Text(
            _time,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD4A017),
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TacticalNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    _NavItem(icon: Icons.grid_view_rounded, label: 'CONTROL', tag: '01'),
    _NavItem(icon: Icons.fact_check_outlined, label: 'CHECK-IN', tag: '02'),
    _NavItem(icon: Icons.memory_rounded, label: 'ZENITH', tag: '03'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F0D),
        border: Border(
          top: BorderSide(color: Color(0xFFD4A017), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (index) {
              return Expanded(
                child: _TacticalNavItem(
                  item: _items[index],
                  isSelected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String tag;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.tag,
  });
}

class _TacticalNavItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TacticalNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TacticalNavItem> createState() => _TacticalNavItemState();
}

class _TacticalNavItemState extends State<_TacticalNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFD4A017);
    const green = Color(0xFF4CAF50);
    final selected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color:
                selected ? amber.withValues(alpha: 0.08) : Colors.transparent,
            border: Border.all(
              color: selected ? amber : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.item.tag,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: selected
                          ? amber.withValues(alpha: 0.8)
                          : const Color(0xFF4A5240),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selected
                          ? amber.withValues(alpha: 0.15)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      widget.item.icon,
                      size: 18,
                      color: selected ? amber : const Color(0xFF4A5240),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: green.withValues(alpha: 0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  Text(
                    widget.item.label,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? amber : const Color(0xFF3A4238),
                      letterSpacing: 1.5,
                    ),
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

class _ScanlinePainter extends CustomPainter {
  final double progress;

  _ScanlinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.15)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final sweepY = size.height * progress;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD4A017).withValues(alpha: 0),
          const Color(0xFFD4A017).withValues(alpha: 0.03),
          const Color(0xFFD4A017).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, sweepY - 40, size.width, 80));

    canvas.drawRect(
      Rect.fromLTWH(0, sweepY - 40, size.width, 80),
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.progress != progress;
}
