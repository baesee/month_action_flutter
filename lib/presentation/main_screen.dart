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

  // FAB 액션 핸들러 (기존 FloatingActionButton onPressed 로직)
  Future<void> _onFabPressed() async {
    final selectedDate = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ActionAddScreen()));
    if (selectedDate is DateTime) {
      final provider = Provider.of<CalendarProvider>(context, listen: false);
      provider.fetchActionsForMonth(
        DateTime(selectedDate.year, selectedDate.month),
      );
      provider.fetchActionsForDate(selectedDate);
      _setExternalSelectedDate(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF181A20),
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(4, (index) {
            return Container(
              color: const Color(0xFF181A20),
              child: Navigator(
                key: _navigatorKeys[index],
                initialRoute: _initialRoutes[index],
                onGenerateRoute: (settings) {
                  final builders = _routeBuilders(context, index);
                  final builder =
                      builders[settings.name] ?? builders.values.first;
                  return MaterialPageRoute(
                    builder: builder,
                    settings: settings,
                  );
                },
              ),
            );
          }),
        ),
        floatingActionButton:
            _selectedIndex == 0
                ? FloatingActionButton(
                  onPressed: _onFabPressed,
                  backgroundColor: const Color(0xFF6DD5FA),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                )
                : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          color: const Color(0xFF23262F),
          elevation: 16,
          child: SizedBox(
            height: 88,
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.calendar_month,
                    label: '월간',
                    selected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.emoji_events,
                    label: '완료',
                    selected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.bar_chart,
                    label: '통계',
                    selected: _selectedIndex == 2,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.settings,
                    label: '설정',
                    selected: _selectedIndex == 3,
                    onTap: () => setState(() => _selectedIndex = 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: selected ? 32 : 28,
            color: selected ? const Color(0xFF6DD5FA) : Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? const Color(0xFF6DD5FA) : Colors.white,
            ),
          ),
        ],
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
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 5,
              ),
              insets: EdgeInsets.symmetric(horizontal: 24),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF23262F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
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
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                          ),
                          onPressed: _goToNextMonth,
                        ),
                        IconButton(
                          icon: const Icon(Icons.today, color: Colors.white),
                          onPressed: _goToToday,
                        ),
                      ],
                    ),
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
