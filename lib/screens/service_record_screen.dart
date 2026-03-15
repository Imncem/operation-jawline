import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/promotion_history_entry.dart';
import '../models/service_record_summary.dart';
import '../providers/phase3_providers.dart';
import 'intel_report_screen.dart';
import 'medals_screen.dart';
import 'settings_screen.dart';
import '../widgets/personal_records_card.dart';
import '../widgets/service_record_header.dart';
import '../widgets/service_record_stats_grid.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _surface = Color(0xFF111411);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

class ServiceRecordScreen extends ConsumerWidget {
  const ServiceRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(serviceRecordProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: summaryAsync.when(
        data: (summary) => _buildContent(context, summary),
        loading: () => _TacticalLoader(),
        error: (error, _) =>
            _TacticalError(message: error.toString().toUpperCase()),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0F0D),
          border: Border(bottom: BorderSide(color: _amber, width: 1.5)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: _amber,
                      size: 18,
                    ),
                  ),
                ),
                Container(width: 3, height: 32, color: _amber),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OP: JAWLINE  //  PERSONNEL FILE',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _amber.withValues(alpha: 0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'SERVICE RECORD',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _text,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ServiceRecordSummary summary) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── Quick Actions ────────────────────────────────────────
        _QuickActionsRow(
          onMedals: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MedalsScreen()),
            );
          },
          onIntel: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IntelReportScreen()),
            );
          },
          onSettings: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        const SizedBox(height: 20),

        // ── Agent Profile ────────────────────────────────────────
        _SectionDivider(label: 'AGENT PROFILE'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _amber.withValues(alpha: 0.25)),
          ),
          child: ServiceRecordHeader(
            rankName: summary.rankName,
            level: summary.level,
            totalXP: summary.totalXP,
            chainLabel: summary.disciplineChainLabel,
            joinDateKey: summary.joinDateKey,
          ),
        ),
        const SizedBox(height: 20),

        // ── Career Stats ─────────────────────────────────────────
        _SectionDivider(label: 'CAREER STATISTICS'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _amber.withValues(alpha: 0.25)),
          ),
          child: ServiceRecordStatsGrid(stats: summary.careerStats),
        ),
        const SizedBox(height: 20),

        // ── Promotion History ────────────────────────────────────
        _SectionDivider(label: 'PROMOTION HISTORY'),
        const SizedBox(height: 12),
        _PromotionHistoryCard(history: summary.promotionHistory),
        const SizedBox(height: 20),

        // ── Personal Records ─────────────────────────────────────
        _SectionDivider(label: 'PERSONAL RECORDS'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _amber.withValues(alpha: 0.25)),
          ),
          child: PersonalRecordsCard(records: summary.personalRecords),
        ),
      ],
    );
  }
}

// ─── Section Divider ──────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  final String label;

  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: _amber),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: _amber,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Container(height: 1, color: _amber.withValues(alpha: 0.2))),
      ],
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onMedals;
  final VoidCallback onIntel;
  final VoidCallback onSettings;

  const _QuickActionsRow({
    required this.onMedals,
    required this.onIntel,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionTile(
            tag: '01',
            label: 'MEDALS',
            icon: Icons.emoji_events_outlined,
            onTap: onMedals,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            tag: '02',
            label: 'INTEL',
            icon: Icons.insights_outlined,
            onTap: onIntel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionTile(
            tag: '03',
            label: 'CONFIG',
            icon: Icons.settings_outlined,
            onTap: onSettings,
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  final String tag;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.tag,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? _amber.withValues(alpha: 0.15) : _surface,
          border: Border.all(
            color: _pressed ? _amber : _amber.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            Text(
              widget.tag,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                color: _amber.withValues(alpha: 0.5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Icon(widget.icon, size: 20, color: _amber),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: _text,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Promotion History Card ───────────────────────────────────────────────────

class _PromotionHistoryCard extends StatelessWidget {
  final List<PromotionHistoryEntry> history;

  const _PromotionHistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _amber.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty_outlined, size: 13, color: _dim),
            const SizedBox(width: 10),
            Text(
              'NO PROMOTIONS RECORDED YET',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _dim,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: List.generate(history.length, (i) {
          final entry = history[i];
          final isLast = i == history.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(color: _amber.withValues(alpha: 0.08)),
                    ),
            ),
            child: Row(
              children: [
                // Index dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Date
                Text(
                  entry.dateKey,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: _text.withValues(alpha: 0.4),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 14),
                // From rank
                Text(
                  entry.fromRank.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: _text.withValues(alpha: 0.5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '▸',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: _amber.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                // To rank
                Text(
                  entry.toRank.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _amber,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Tactical Loader ──────────────────────────────────────────────────────────

class _TacticalLoader extends StatefulWidget {
  @override
  State<_TacticalLoader> createState() => _TacticalLoaderState();
}

class _TacticalLoaderState extends State<_TacticalLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _amber,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _amber.withValues(alpha: _controller.value * 0.8),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'RETRIEVING PERSONNEL FILE...',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _amber.withValues(alpha: 0.6),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tactical Error ───────────────────────────────────────────────────────────

class _TacticalError extends StatelessWidget {
  final String message;

  const _TacticalError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off_outlined, color: _dim, size: 28),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: _dim,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
