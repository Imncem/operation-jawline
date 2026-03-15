import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../intel/insight_engine.dart';
import '../intel/zenith_intelligence_engine.dart';
import '../models/daily_check_in.dart';
import '../models/daily_mission_record.dart';
import '../models/zenith_adjustment.dart';
import '../models/zenith_analysis_result.dart';
import '../services/mission_progress_service.dart';
import '../services/sfx_service.dart';
import '../widgets/line_chart_card.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _amber = Color(0xFFD4A017);
const _green = Color(0xFF4CAF50);
const _blue = Color(0xFF29B6F6);
const _red = Color(0xFFEF5350);
const _surface = Color(0xFF111411);
const _bg = Color(0xFF0A0C0A);
const _text = Color(0xFFCDD4C0);
const _dim = Color(0xFF3A4238);

class IntelReportScreen extends ConsumerStatefulWidget {
  const IntelReportScreen({super.key});

  @override
  ConsumerState<IntelReportScreen> createState() => _IntelReportScreenState();
}

class _IntelReportScreenState extends ConsumerState<IntelReportScreen> {
  int _days = 7;
  final _insightEngine = const InsightEngine();
  final _zenithEngine = const ZenithIntelligenceEngine();

  @override
  Widget build(BuildContext context) {
    final checkInsAsync = ref.watch(checkInHistoryProvider);
    final missionsAsync = ref.watch(missionHistoryProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: checkInsAsync.when(
        data: (checkIns) => missionsAsync.when(
          data: (missions) => _buildContent(checkIns, missions),
          loading: () => _TacticalLoader(),
          error: (_, __) => _TacticalError(message: 'NO MISSION HISTORY FOUND'),
        ),
        loading: () => _TacticalLoader(),
        error: (_, __) => _TacticalError(message: 'NO CHECK-IN HISTORY FOUND'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
                      'OP: JAWLINE  //  ANALYSIS',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: _amber.withValues(alpha: 0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'INTEL REPORT',
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
                const Spacer(),
                // Day range toggle
                _DayRangeToggle(
                  selected: _days,
                  onChanged: (d) {
                    SfxService.selection();
                    setState(() => _days = d);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<DailyCheckIn> checkIns,
    List<DailyMissionRecord> missions,
  ) {
    final recentCheckIns =
        checkIns.reversed.take(_days).toList().reversed.toList();
    final recentMissions =
        missions.reversed.take(_days).toList().reversed.toList();
    final insights = _insightEngine.buildInsights(
      checkIns: recentCheckIns,
      missionRecords: recentMissions,
    );
    final intelligence = _zenithEngine.analyze(
      checkIns: checkIns,
      missionRecords: missions,
      windowDays: _days,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── Header ────────────────────────────────────────────────
        _SectionHeader(
          tag: 'BIOMETRIC TRENDS',
          subtitle: 'Last $_days days of field data',
        ),
        const SizedBox(height: 16),
        _ZenithAnalysisCard(analysis: intelligence.analysis),
        const SizedBox(height: 12),
        _RecommendedAdjustmentCard(adjustment: intelligence.adjustment),
        const SizedBox(height: 16),

        // ── Charts ────────────────────────────────────────────────
        _ChartBlock(
          tag: '01',
          label: 'BODY MASS',
          unit: 'KG',
          child: LineChartCard(
            title: 'Weight',
            values: recentCheckIns.map((e) => e.weightKg ?? 0).toList(),
            color: _amber,
            decimals: 1,
            interpretation:
                'Use this for direction, not daily noise. A steady trend over 7-30 days is more meaningful than single-day spikes.',
          ),
        ),
        const SizedBox(height: 12),

        _ChartBlock(
          tag: '02',
          label: 'ENERGY LEVEL',
          unit: '/10',
          child: LineChartCard(
            title: 'Energy',
            values: recentCheckIns.map((e) => e.energy.toDouble()).toList(),
            color: _green,
            decimals: 0,
            interpretation:
                'Higher energy usually supports harder training lanes. If this trends down, bias recovery and sleep quality.',
          ),
        ),
        const SizedBox(height: 12),

        _ChartBlock(
          tag: '03',
          label: 'HYDRATION',
          unit: 'L',
          child: LineChartCard(
            title: 'Hydration',
            values: recentCheckIns.map((e) => e.waterLiters).toList(),
            color: _blue,
            decimals: 1,
            interpretation:
                'Aim for consistent intake across the week. Large swings often align with lower readiness and recovery quality.',
          ),
        ),
        const SizedBox(height: 12),

        _ChartBlock(
          tag: '04',
          label: 'PUFFINESS INDEX',
          unit: '/5',
          child: LineChartCard(
            title: 'Puffiness',
            values: recentCheckIns.map((e) => e.puffiness.toDouble()).toList(),
            color: _red,
            decimals: 0,
            interpretation:
                'Lower is better here. Rising puffiness can signal recovery strain, poor sleep, or hydration inconsistency.',
          ),
        ),
        const SizedBox(height: 12),

        _ChartBlock(
          tag: '05',
          label: 'MISSION COMPLETION',
          unit: '%',
          child: LineChartCard(
            title: 'Mission Completion %',
            values: recentMissions.map((e) => e.completion * 100).toList(),
            color: _amber,
            decimals: 0,
            interpretation:
                'This shows execution consistency. 80%+ across most days indicates stable discipline and protocol adherence.',
          ),
        ),
        const SizedBox(height: 24),

        // ── Insights ──────────────────────────────────────────────
        _InsightsDivider(),
        const SizedBox(height: 14),
        _InsightsCard(insights: insights),
      ],
    );
  }
}

// ─── Day Range Toggle ─────────────────────────────────────────────────────────

class _DayRangeToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DayRangeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToggleTab(label: '7D', value: 7, selected: selected, onTap: onChanged),
        const SizedBox(width: 4),
        _ToggleTab(
            label: '30D', value: 30, selected: selected, onTap: onChanged),
      ],
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final int value;
  final int selected;
  final ValueChanged<int> onTap;

  const _ToggleTab({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? _amber.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? _amber : _dim,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? _amber : _dim,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String tag;
  final String subtitle;

  const _SectionHeader({required this.tag, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, color: _amber),
            const SizedBox(width: 8),
            Text(
              tag,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _amber,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: _text.withValues(alpha: 0.4),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Chart Block ──────────────────────────────────────────────────────────────

class _ChartBlock extends StatelessWidget {
  final String tag;
  final String label;
  final String unit;
  final Widget child;

  const _ChartBlock({
    required this.tag,
    required this.label,
    required this.unit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _amber.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  tag,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: _amber.withValues(alpha: 0.5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                    width: 1, height: 10, color: _amber.withValues(alpha: 0.3)),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: _amber,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: _amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      color: _amber.withValues(alpha: 0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chart content
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Insights Divider ─────────────────────────────────────────────────────────

class _InsightsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: _amber),
        const SizedBox(width: 8),
        const Text(
          'AI FIELD ANALYSIS',
          style: TextStyle(
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

// ─── Insights Card ────────────────────────────────────────────────────────────

class _InsightsCard extends StatelessWidget {
  final List<String> insights;

  const _InsightsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _amber.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty_outlined, size: 14, color: _dim),
            const SizedBox(width: 10),
            Text(
              'INSUFFICIENT DATA FOR ANALYSIS',
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
        children: List.generate(insights.length, (i) {
          final isLast = i == insights.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(color: _amber.withValues(alpha: 0.08)),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '▸',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: _amber.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insights[i],
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _text.withValues(alpha: 0.7),
                      height: 1.5,
                      letterSpacing: 0.5,
                    ),
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

class _ZenithAnalysisCard extends StatelessWidget {
  const _ZenithAnalysisCard({required this.analysis});

  final ZenithAnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ZENITH ANALYSIS',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _amber,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'OPERATIONAL INTERPRETATION OF RECENT TELEMETRY',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: _text.withValues(alpha: 0.45),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              analysis.summaryTitle,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _text,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              analysis.summaryText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: _text.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ...analysis.bulletInsights.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '> ',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: _amber.withValues(alpha: 0.7),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: _text.withValues(alpha: 0.68),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              height: 1,
              color: _amber.withValues(alpha: 0.12),
            ),
            Text(
              analysis.recommendedActionTitle,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: _amber,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              analysis.recommendedActionText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _text.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'CONFIDENCE ${analysis.confidenceLabel.toUpperCase()}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: _amber.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedAdjustmentCard extends StatelessWidget {
  const _RecommendedAdjustmentCard({required this.adjustment});

  final ZenithAdjustment adjustment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RECOMMENDED ADJUSTMENT',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: _amber,
                letterSpacing: 3,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdjustmentChip(
                  label:
                      'Lane ${adjustment.laneOverrideSuggestion?.label ?? 'Neutral'}',
                ),
                _AdjustmentChip(
                  label:
                      'Focus ${adjustment.focusSuggestion?.label ?? 'Baseline'}',
                ),
                _AdjustmentChip(
                  label: adjustment.durationDeltaMin == 0
                      ? 'Duration 0m'
                      : 'Duration ${adjustment.durationDeltaMin > 0 ? '+' : ''}${adjustment.durationDeltaMin}m',
                ),
                _AdjustmentChip(
                  label: adjustment.restrictHighIntensity
                      ? 'HI restricted'
                      : 'HI available',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentChip extends StatelessWidget {
  const _AdjustmentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.08),
        border: Border.all(color: _amber.withValues(alpha: 0.22)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: _text.withValues(alpha: 0.75),
          letterSpacing: 1.2,
        ),
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
            'RETRIEVING FIELD DATA...',
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
          Icon(Icons.signal_wifi_off_outlined, color: _dim, size: 28),
          const SizedBox(height: 14),
          Text(
            message,
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
