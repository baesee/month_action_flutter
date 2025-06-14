import 'package:flutter/material.dart';
import 'package:month_action/presentation/views/monthly_view.dart';
import 'package:month_action/presentation/views/calendar_view.dart';
import 'package:month_action/presentation/views/weekly_calendar_view.dart';
import 'package:month_action/presentation/views/daily_calendar_view.dart';
import 'package:month_action/presentation/action/action_add_screen.dart';
import 'package:provider/provider.dart';
import 'package:month_action/presentation/viewmodels/calendar_provider.dart';
import 'package:intl/intl.dart';
import 'package:month_action/presentation/views/statistics_screen.dart';
import 'package:month_action/presentation/views/completed_screen.dart';
// TODO: MonthlyView(월간), StatisticsScreen, SettingsScreen 파일도 준비/연결

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  // 외부에서 월간 탭의 날짜를 강제로 바꿀 때 사용
  DateTime? _externalSelectedDate;
  void _setExternalSelectedDate(DateTime date) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _externalSelectedDate = date;
        });
      }
    });
  }

  // 각 탭별 첫 화면 라우트 이름
  static const List<String> _initialRoutes = [
    '/monthly',
    '/completed',
    '/statistics',
    '/settings',
  ];

  // 탭별 라우트 빌더
  Map<String, WidgetBuilder> _routeBuilders(BuildContext context, int index) {
    switch (index) {
      case 0:
        return {
          '/monthly':
              (_) => MonthlyTabScreen(
                externalSelectedDate: _externalSelectedDate,
                onExternalDateSelected:
                    () => setState(() => _externalSelectedDate = null),
              ),
        };
      case 1:
        return {'/completed': (_) => const CompletedScreen()};
      case 2:
        return {'/statistics': (_) => const StatisticsScreen()};
      case 3:
        return {'/settings': (_) => const SettingsScreen()};
      default:
        return {'/': (_) => const SizedBox.shrink()};
    }
  }

  // 뒤로가기 버튼 처리
  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_selectedIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    // 모든 탭의 스택이 비어있으면 앱 종료 허용
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final backgroundColor =
        theme.bottomNavigationBarTheme.backgroundColor ??
        theme.colorScheme.surface;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(4, (index) {
            return Navigator(
              key: _navigatorKeys[index],
              initialRoute: _initialRoutes[index],
              onGenerateRoute: (settings) {
                final builders = _routeBuilders(context, index);
                final builder =
                    builders[settings.name] ?? builders.values.first;
                return MaterialPageRoute(builder: builder, settings: settings);
                // fallback
                return MaterialPageRoute(
                  builder: (_) => const SizedBox.shrink(),
                );
              },
            );
          }),
        ),
        floatingActionButton:
            _selectedIndex == 0
                ? FloatingActionButton(
                  onPressed: () async {
                    final selectedDate = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ActionAddScreen(),
                      ),
                    );
                    if (selectedDate is DateTime) {
                      final provider = Provider.of<CalendarProvider>(
                        context,
                        listen: false,
                      );
                      provider.fetchActionsForMonth(
                        DateTime(selectedDate.year, selectedDate.month),
                      );
                      provider.fetchActionsForDate(selectedDate);
                      _setExternalSelectedDate(selectedDate);
                    }
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 6,
                  tooltip: '행동 추가',
                  child: const Icon(Icons.add, size: 32),
                )
                : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: backgroundColor,
          indicatorColor: selectedColor.withOpacity(0.12),
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month, size: 28),
              selectedIcon: Icon(Icons.calendar_month, size: 32),
              label: '월간',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events, size: 28),
              selectedIcon: Icon(Icons.emoji_events, size: 32),
              label: '완료',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart, size: 28),
              selectedIcon: Icon(Icons.bar_chart, size: 32),
              label: '통계',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings, size: 28),
              selectedIcon: Icon(Icons.settings, size: 32),
              label: '설정',
            ),
          ],
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }
}

// 2. 카테고리
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리'),
        automaticallyImplyLeading: false,
        leading: canPop ? null : const BackButton(),
      ),
      body: const Center(
        child: Text('카테고리 관리 화면입니다.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

// 3. 액션
class ActionScreen extends StatelessWidget {
  const ActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('행동(액션) 관리'),
        automaticallyImplyLeading: false,
        leading: canPop ? null : const BackButton(),
      ),
      body: const Center(
        child: Text('액션 관리 화면입니다.', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

// 5. 설정
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정2'),
        automaticallyImplyLeading: false,
        leading: canPop ? null : const BackButton(),
      ),
      body: const Center(
        child: Text('설정 화면입니다.222', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

// 월간/주간/일간/월간(캘린더) 탭 통합 뷰
class MonthlyTabScreen extends StatefulWidget {
  const MonthlyTabScreen({
    super.key,
    this.externalSelectedDate,
    this.onExternalDateSelected,
  });

  final DateTime? externalSelectedDate;
  final VoidCallback? onExternalDateSelected;

  @override
  State<MonthlyTabScreen> createState() => _MonthlyTabScreenState();
}

class _MonthlyTabScreenState extends State<MonthlyTabScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _tabs = ['일간', '주간', '월간', '달력'];
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  // 월간 탭용 월 네비게이터 상태
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  void didUpdateWidget(covariant MonthlyTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 외부에서 날짜가 지정되면 동기화
    if (widget.externalSelectedDate != null &&
        widget.externalSelectedDate != _selectedDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedDate = widget.externalSelectedDate!;
          });
          widget.onExternalDateSelected?.call();
        }
      });
    }
  }

  void _goToPrevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedMonth,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2100, 12),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() {
        _focusedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('월간'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabController,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.black54,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            DailyCalendarView(
              selectedDate: _selectedDate,
              onDateChanged: _onDateChanged,
            ),
            WeeklyCalendarView(
              selectedDate: _selectedDate,
              onDateChanged: _onDateChanged,
            ),
            // 월간 탭: 상단에 월 네비게이터 Row 추가, MonthlyView에 focusedMonth 전달
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
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
                              DateFormat(
                                'yyyy년 M월',
                                'ko',
                              ).format(_focusedMonth),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _goToNextMonth,
                      ),
                      IconButton(
                        icon: const Icon(Icons.today),
                        onPressed: _goToToday,
                      ),
                    ],
                  ),
                ),
                Expanded(child: MonthlyView(focusedMonth: _focusedMonth)),
              ],
            ),
            CalendarView(
              selectedDate: _selectedDate,
              onDateChanged: _onDateChanged,
            ),
          ],
        ),
      ),
    );
  }
}
