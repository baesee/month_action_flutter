import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/action_model.dart' as model;
import '../../data/models/action_history_model.dart';
import '../../data/repositories/action_repository.dart';
import '../../data/repositories/action_history_repository.dart';
import 'package:intl/intl.dart';
import '../viewmodels/calendar_provider.dart';
import 'package:month_action/presentation/widgets/animated_card.dart';
import 'package:month_action/presentation/widgets/custom_empty_error_loading.dart';

class CompletedScreen extends StatefulWidget {
  const CompletedScreen({super.key});

  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> {
  List<model.Action> _actions = [];
  List<ActionHistory> _histories = [];
  bool _loading = true;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  CalendarProvider? _calendarProvider;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    // Provider 리스너 해제
    _calendarProvider?.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final actions = await ActionRepository().getAllActions();
    final histories = await ActionHistoryRepository().getAllActionHistories();
    setState(() {
      _actions = actions;
      _histories = histories;
      _loading = false;
    });
  }

  void _goToPrevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: CustomLoading(message: '불러오는 중...'));
    }
    // 완료된 Action만 추출 (히스토리 기준)
    final completedIds = _histories.map((h) => h.actionId).toSet();
    final completedActions =
        _actions.where((a) => completedIds.contains(a.id)).toList();
    completedActions.sort(
      (a, b) => (b.date ?? DateTime(2000)).compareTo(a.date ?? DateTime(2000)),
    );
    // 선택 월 기준 필터
    final monthCompletedActions =
        completedActions
            .where(
              (a) =>
                  a.date != null &&
                  a.date!.year == _selectedMonth.year &&
                  a.date!.month == _selectedMonth.month,
            )
            .toList();
    // 이번 달/누적/연속 스트릭 등 집계
    final monthCompleted = monthCompletedActions.length;
    final totalCompleted = completedActions.length;
    // streak 계산 (간단 버전: 최근 연속 완료일)
    int streak = 0;
    DateTime? prev;
    for (final a
        in monthCompletedActions.where((a) => a.date != null).toList()
          ..sort((a, b) => (b.date!).compareTo(a.date!))) {
      if (prev == null || a.date!.difference(prev).inDays == 1) {
        streak++;
        prev = a.date;
      } else {
        break;
      }
    }
    // TOP3 (가장 많이 완료한 제목, 선택 월 기준)
    final Map<String, int> titleCount = {};
    for (final a in monthCompletedActions) {
      titleCount[a.title] = (titleCount[a.title] ?? 0) + 1;
    }
    final top3 =
        titleCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    // 동기부여 메시지
    String message = '';
    if (streak >= 7) {
      message = '🔥 7일 연속 완료! 대단해요!';
    } else if (monthCompleted >= 10) {
      message = '🎯 이번 달 목표를 향해 잘 달려가고 있어요!';
    } else if (monthCompleted > 0) {
      message = '💪 계속해서 성취를 쌓아가세요!';
    } else {
      message = '🚀 첫 완료를 향해 도전해보세요!';
    }
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '완료된 항목',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            // 상단 년월 네비게이터
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
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
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _goToNextMonth,
                  ),
                  IconButton(
                    icon: const Icon(Icons.today, color: Colors.white),
                    onPressed: () {
                      final today = DateTime.now();
                      setState(() {
                        _selectedMonth = DateTime(today.year, today.month);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: Colors.white),
                    onPressed: _pickMonth,
                  ),
                ],
              ),
            ),
            // 성취 요약 카드 (gradient, 이모지, 큰 폰트)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎉 이번 달 완료: $monthCompleted개',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '누적 완료: $totalCompleted개   |   스트릭: $streak일',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // TOP3 카드
            if (top3.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF23262F),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOP 3 완료 항목',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...top3
                        .take(3)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('🏅', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.key,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${e.value}회',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            // 최근 완료 리스트 (카드형)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '최근 완료',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            ...monthCompletedActions.map(
              (a) => AnimatedCard(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        a.category == model.CategoryType.expense
                            ? const Color(0xFFF7971E)
                            : const Color(0xFF6DD5FA),
                    child: Icon(
                      a.category == model.CategoryType.expense
                          ? Icons.attach_money
                          : Icons.check,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    a.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    a.date != null
                        ? DateFormat('yyyy-MM-dd (E)', 'ko').format(a.date!)
                        : '',
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF6DD5FA),
                    size: 28,
                  ),
                ),
              ),
            ),
            if (monthCompletedActions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CustomEmpty(message: '아직 완료된 항목이 없습니다!', emoji: '🌙'),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedCompletedList(List<model.Action> actions) {
    if (actions.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text('완료된 항목이 없습니다.', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ];
    }
    // 날짜별 그룹핑
    final Map<String, List<model.Action>> grouped = {};
    for (final a in actions) {
      final key =
          a.date != null
              ? DateFormat('yyyy-MM-dd (E)', 'ko').format(a.date!)
              : '날짜 없음';
      grouped.putIfAbsent(key, () => []).add(a);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final key in sortedKeys) ...[
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 8, bottom: 4),
          child: Text(
            key,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ),
        ...grouped[key]!.map(
          (a) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(
                a.category == model.CategoryType.expense
                    ? Icons.attach_money
                    : Icons.check_circle,
                color:
                    a.category == model.CategoryType.expense
                        ? Colors.green
                        : Colors.blue,
              ),
              title: Text(
                a.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle:
                  a.description != null && a.description!.isNotEmpty
                      ? Text(a.description!)
                      : null,
              trailing:
                  a.category == model.CategoryType.expense && a.amount > 0
                      ? Text(
                        '${NumberFormat('#,###').format(a.amount)}원',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
          ),
        ),
      ],
    ];
  }
}
