import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/action_model.dart' as model;
import '../../data/models/action_history_model.dart';
import '../../data/services/action_statistics_service.dart';
import '../../data/repositories/action_repository.dart';
import '../../data/repositories/action_history_repository.dart';
import 'package:intl/intl.dart';
import '../../main.dart'; // routeObserver가 main.dart에 있다고 가정
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/calendar_provider.dart';
import 'package:month_action/presentation/widgets/animated_card.dart';
import 'package:month_action/presentation/widgets/custom_progress_bar.dart';
import 'package:month_action/presentation/widgets/custom_tab_indicator.dart';
import 'package:month_action/presentation/widgets/custom_empty_error_loading.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  List<model.Action> _actions = [];
  List<ActionHistory> _histories = [];
  bool _loading = true;
  final _statService = ActionStatisticsService();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  CalendarProvider? _calendarProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    // Provider 구독 및 리스너 등록
    final provider = Provider.of<CalendarProvider>(context);
    if (_calendarProvider != provider) {
      _calendarProvider?.removeListener(_loadData);
      _calendarProvider = provider;
      _calendarProvider?.addListener(_loadData);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    // Provider 리스너 해제
    _calendarProvider?.removeListener(_loadData);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 다른 화면에서 돌아올 때마다 데이터 새로고침
    _loadData();
  }

  Future<void> _loadData() async {
    final actions = await ActionRepository().getActionsByMonth(_selectedMonth);
    final histories = await ActionHistoryRepository().getAllActionHistories();
    setState(() {
      _actions = actions;
      _histories = histories;
      _loading = false;
    });
  }

  DateTime get _monthStart =>
      DateTime(_selectedMonth.year, _selectedMonth.month, 1);
  DateTime get _monthEnd =>
      DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

  List<ActionHistory> _filterByMonth(List<ActionHistory> list) {
    return list
        .where(
          (h) =>
              !h.completedAt.isBefore(_monthStart) &&
              !h.completedAt.isAfter(_monthEnd),
        )
        .toList();
  }

  void _goToPrevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _loading = true;
    });
    _loadData();
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _loading = true;
    });
    _loadData();
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2100, 12),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _loading = true;
      });
      _loadData();
    }
  }

  Widget _buildMonthNavigator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPrevMonth,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickMonth,
              child: Center(
                child: Text(
                  DateFormat('yyyy년 M월', 'ko').format(_selectedMonth),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '통계 및 리포트',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '지출'), Tab(text: '할일')],
          indicator: const CustomTabIndicator(),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _loading
              ? const CustomLoading(message: '통계 불러오는 중...')
              : Column(
                children: [
                  _buildMonthNavigator(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Container(
                          color: const Color(0xFF181A20),
                          child: _buildExpenseTab(),
                        ),
                        Container(
                          color: const Color(0xFF181A20),
                          child: _buildTodoTab(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildExpenseTab() {
    final expenseActions =
        _actions
            .where(
              (a) =>
                  a.category == model.CategoryType.expense &&
                  a.date != null &&
                  a.date!.year == _selectedMonth.year &&
                  a.date!.month == _selectedMonth.month,
            )
            .toList();
    final expenseIds = expenseActions.map((a) => a.id).toSet();
    final expenseHistories = _filterByMonth(
      _histories.where((h) => expenseIds.contains(h.actionId)).toList(),
    );
    final totalAmount = expenseActions.fold<int>(
      0,
      (sum, a) => sum + (a.amount),
    );
    final doneAmount = expenseHistories.fold<int>(0, (sum, h) {
      try {
        final action = expenseActions.firstWhere((a) => a.id == h.actionId);
        return sum + action.amount;
      } catch (_) {
        return sum;
      }
    });
    final goal = expenseActions.length; // 목표: 해당 월의 지출 등록 건수
    final doneCount = expenseHistories.length;
    final percent = goal == 0 ? 0.0 : (doneCount / goal).clamp(0.0, 1.0);
    // 스트릭/최고 스트릭 계산
    int streak = _statService.getStreak(expenseHistories);
    int maxStreak = 0, curStreak = 1;
    final days = expenseHistories.map((h) => h.completedAt).toList()..sort();
    for (int i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        curStreak++;
        if (curStreak > maxStreak) maxStreak = curStreak;
      } else {
        curStreak = 1;
      }
    }
    if (maxStreak == 0 && streak > 0) maxStreak = streak;
    final lastCompleted = days.isNotEmpty ? days.last : null;
    final dailyStats = _statService.getDailyCompletionCount(expenseHistories);
    final monthlyStats = _statService.getMonthlyCompletionCount(
      expenseHistories,
    );
    // 인사이트 메시지
    String insight = '';
    if (percent >= 1.0) {
      insight = '🎉 이번 달 모든 지출 목표를 달성했어요!';
    } else if (streak >= 7) {
      insight = '🔥 7일 연속 지출 관리 성공! 좋은 습관이 쌓이고 있어요!';
    } else if (doneCount > 0) {
      insight = '💪 계속해서 지출을 잘 관리하고 있어요!';
    } else {
      insight = '🚀 첫 지출 관리를 시작해보세요!';
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 요약 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF23262F),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            DonutChart(
                              percent: percent,
                              size: 140,
                              strokeWidth: 18,
                              valueColor: Color(0xFFF7971E),
                              backgroundColor: Colors.white12,
                              center: Text(
                                '${(percent * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '목표: $goal건',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '달성: $doneCount건',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '남은 목표: ${goal - doneCount}건',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            if (lastCompleted != null)
                              Text(
                                '최근 달성: ${DateFormat('M.d (E)', 'ko').format(lastCompleted)}',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFF7971E).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Color(0xFFF7971E),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '스트릭 $streak일',
                              style: TextStyle(
                                color: Color(0xFFF7971E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '최고 $maxStreak일',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    insight,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 기존 통계 차트/지표
            Text(
              '총 지출 금액: ${_formatNumber(totalAmount)}원',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('완료된 지출 금액: ${_formatNumber(doneAmount)}원'),
            const SizedBox(height: 8),
            Text('완료(지출) 건수: $doneCount'),
            const SizedBox(height: 16),
            _buildGoalProgress(percent, goal, doneCount),
            const SizedBox(height: 16),
            _buildStreakBadge(expenseHistories),
            const SizedBox(height: 32),
            Text(
              '일별 완료 건수',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 180,
                child: _buildExpenseCountBarChart(
                  expenseHistories,
                  _selectedMonth,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '일별 완료 금액',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 180,
                child: _buildExpenseAmountBarChart(
                  expenseHistories,
                  expenseActions,
                  _selectedMonth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoTab() {
    final todoActions =
        _actions
            .where(
              (a) =>
                  a.category == model.CategoryType.todo &&
                  a.date != null &&
                  a.date!.year == _selectedMonth.year &&
                  a.date!.month == _selectedMonth.month,
            )
            .toList();
    final todoIds = todoActions.map((a) => a.id).toSet();
    final todoHistories = _filterByMonth(
      _histories.where((h) => todoIds.contains(h.actionId)).toList(),
    );
    final goal = todoActions.length; // 목표: 해당 월의 할일 등록 건수
    final doneCount = todoHistories.length;
    final percent = goal == 0 ? 0.0 : (doneCount / goal).clamp(0.0, 1.0);
    final streak = _statService.getStreak(todoHistories);
    // 최고 스트릭 계산 (간단 버전: 정렬 후 최대 연속)
    int maxStreak = 0, curStreak = 1;
    final days = todoHistories.map((h) => h.completedAt).toList()..sort();
    for (int i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        curStreak++;
        if (curStreak > maxStreak) maxStreak = curStreak;
      } else {
        curStreak = 1;
      }
    }
    if (maxStreak == 0 && streak > 0) maxStreak = streak;
    final lastCompleted = days.isNotEmpty ? days.last : null;
    final dailyStats = _statService.getDailyCompletionCount(todoHistories);
    final monthlyStats = _statService.getMonthlyCompletionCount(todoHistories);
    // 인사이트 메시지
    String insight = '';
    if (percent >= 1.0) {
      insight = '🎉 이번 달 목표를 모두 달성했어요!';
    } else if (streak >= 7) {
      insight = '🔥 7일 연속 달성! 습관이 만들어지고 있어요!';
    } else if (doneCount > 0) {
      insight = '💪 계속해서 성취를 쌓아가세요!';
    } else {
      insight = '🚀 첫 달성을 향해 도전해보세요!';
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 요약 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF23262F),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            DonutChart(
                              percent: percent,
                              size: 140,
                              strokeWidth: 18,
                              valueColor: Color(0xFF6DD5FA),
                              backgroundColor: Colors.white12,
                              center: Text(
                                '${(percent * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '목표: $goal개',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '달성: $doneCount개',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '남은 목표: ${goal - doneCount}개',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                            if (lastCompleted != null)
                              Text(
                                '최근 달성: ${DateFormat('M.d (E)', 'ko').format(lastCompleted)}',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF6DD5FA).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Color(0xFF6DD5FA),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '스트릭 $streak일',
                              style: TextStyle(
                                color: Color(0xFF6DD5FA),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '최고 $maxStreak일',
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    insight,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 기존 통계 차트/지표
            Text(
              '일별 완료 건수',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: SizedBox(
                height: 180,
                child: _buildTodoBarChart(todoHistories, _selectedMonth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCountBarChart(
    List<ActionHistory> histories,
    DateTime month,
  ) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final keys = List.generate(daysInMonth, (i) {
      final d = DateTime(month.year, month.month, i + 1);
      return DateFormat('MM-dd').format(d);
    });
    final Map<String, int> countMap = {for (var k in keys) k: 0};
    for (final h in histories) {
      final dateKey = DateFormat('MM-dd').format(h.completedAt);
      countMap[dateKey] = (countMap[dateKey] ?? 0) + 1;
    }
    final maxY =
        countMap.values.isEmpty
            ? 1
            : (countMap.values.reduce((a, b) => a > b ? a : b) * 1.2).ceil();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final day = keys[group.x.toInt()];
              return BarTooltipItem(
                '[$day]\n건수: ${countMap[day]}',
                TextStyle(color: Colors.blueAccent),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= keys.length)
                  return const SizedBox.shrink();
                if (idx == 0 || idx == keys.length - 1 || idx % 5 == 0) {
                  return Text(keys[idx], style: const TextStyle(fontSize: 10));
                }
                return const SizedBox.shrink();
              },
              reservedSize: 32,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < keys.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: countMap[keys[i]]!.toDouble(),
                  width: 14,
                  color: Colors.blueAccent,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseAmountBarChart(
    List<ActionHistory> histories,
    List<model.Action> actions,
    DateTime month,
  ) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final keys = List.generate(daysInMonth, (i) {
      final d = DateTime(month.year, month.month, i + 1);
      return DateFormat('MM-dd').format(d);
    });
    final Map<String, int> amountMap = {for (var k in keys) k: 0};
    final actionMap = {for (var a in actions) a.id: a};
    for (final h in histories) {
      final dateKey = DateFormat('MM-dd').format(h.completedAt);
      final a = actionMap[h.actionId];
      if (a != null) {
        amountMap[dateKey] = (amountMap[dateKey] ?? 0) + a.amount;
      }
    }
    final maxY =
        amountMap.values.isEmpty
            ? 1
            : (amountMap.values.reduce((a, b) => a > b ? a : b) * 1.2).ceil();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final day = keys[group.x.toInt()];
              return BarTooltipItem(
                '[$day]\n금액: ${amountMap[day]}원',
                TextStyle(color: Colors.orangeAccent),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= keys.length)
                  return const SizedBox.shrink();
                if (idx == 0 || idx == keys.length - 1 || idx % 5 == 0) {
                  return Text(keys[idx], style: const TextStyle(fontSize: 10));
                }
                return const SizedBox.shrink();
              },
              reservedSize: 32,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < keys.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amountMap[keys[i]]!.toDouble(),
                  width: 14,
                  color: Colors.orangeAccent,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTodoBarChart(List<ActionHistory> histories, DateTime month) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final keys = List.generate(daysInMonth, (i) {
      final d = DateTime(month.year, month.month, i + 1);
      return DateFormat('MM-dd').format(d);
    });
    final Map<String, int> countMap = {for (var k in keys) k: 0};
    for (final h in histories) {
      final dateKey = DateFormat('MM-dd').format(h.completedAt);
      countMap[dateKey] = (countMap[dateKey] ?? 0) + 1;
    }
    final maxY =
        countMap.values.isEmpty
            ? 1
            : (countMap.values.reduce((a, b) => a > b ? a : b) * 1.2).ceil();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.black87,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final day = keys[group.x.toInt()];
              return BarTooltipItem(
                '[$day]\n건수: ${countMap[day]}',
                TextStyle(color: Colors.blueAccent),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= keys.length)
                  return const SizedBox.shrink();
                if (idx == 0 || idx == keys.length - 1 || idx % 5 == 0) {
                  return Text(keys[idx], style: const TextStyle(fontSize: 10));
                }
                return const SizedBox.shrink();
              },
              reservedSize: 32,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < keys.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: countMap[keys[i]]!.toDouble(),
                  width: 14,
                  color: Colors.blueAccent,
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildGoalProgress(double percent, int goal, int doneCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '목표 달성률: ${(percent * 100).toStringAsFixed(1)}% ($doneCount/$goal)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: CustomProgressBar(value: percent, height: 12),
        ),
        if (percent >= 1.0)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: const [
                Icon(Icons.emoji_events, color: Colors.amber),
                SizedBox(width: 6),
                Text(
                  '축하합니다! 목표를 달성했어요!',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStreakBadge(List<ActionHistory> histories) {
    // Implementation of _buildStreakBadge method
    return Container(); // Placeholder, actual implementation needed
  }
}

// --- DonutChart 위젯 추가 ---
class DonutChart extends StatelessWidget {
  final double percent; // 0.0 ~ 1.0
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color valueColor;
  final Widget? center;

  const DonutChart({
    super.key,
    required this.percent,
    this.size = 140,
    this.strokeWidth = 18,
    this.backgroundColor = const Color(0x22FFFFFF),
    this.valueColor = const Color(0xFF6DD5FA),
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutChartPainter(
              percent: percent,
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor,
              valueColor: valueColor,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final Color backgroundColor;
  final Color valueColor;

  _DonutChartPainter({
    required this.percent,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // 배경 원
    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 값 원
    final valuePaint =
        Paint()
          ..color = valueColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * 3.141592653589793 * percent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.141592653589793 / 2, // 12시 방향 시작
      sweepAngle,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- DonutChart 위젯 끝 ---
