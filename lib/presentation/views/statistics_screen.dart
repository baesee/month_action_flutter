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
    final dailyStats = _statService.getDailyCompletionCount(expenseHistories);
    final monthlyStats = _statService.getMonthlyCompletionCount(
      expenseHistories,
    );
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              '월별 지출 추이',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 180, child: _buildBarChart(monthlyStats)),
            const SizedBox(height: 16),
            Text(
              '일별 지출 추이',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 180, child: _buildBarChart(dailyStats)),
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
    final dailyStats = _statService.getDailyCompletionCount(todoHistories);
    final monthlyStats = _statService.getMonthlyCompletionCount(todoHistories);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '완료(할일) 건수: $doneCount',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('연속 완료 스트릭: $streak일'),
            const SizedBox(height: 16),
            _buildGoalProgress(percent, goal, doneCount),
            const SizedBox(height: 16),
            _buildStreakBadge(todoHistories),
            const SizedBox(height: 16),
            Text(
              '월별 완료 추이',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 180, child: _buildBarChart(monthlyStats)),
            const SizedBox(height: 16),
            Text(
              '일별 완료 추이',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 180, child: _buildBarChart(dailyStats)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const CustomEmpty(message: '데이터 없음', emoji: '📊');
    }
    final keys = data.keys.toList()..sort();
    final maxY =
        data.values.isEmpty
            ? 1
            : (data.values.reduce((a, b) => a > b ? a : b) * 1.2).ceil();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= keys.length)
                  return const SizedBox.shrink();
                final label = keys[idx];
                return Text(
                  label.length > 5 ? label.substring(label.length - 5) : label,
                  style: const TextStyle(fontSize: 10),
                );
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
                BarChartRodData(toY: data[keys[i]]!.toDouble(), width: 14),
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
