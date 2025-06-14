import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calendar_provider.dart';
import '../action/action_edit_screen.dart';
import 'package:month_action/data/models/action_model.dart';
import 'package:month_action/presentation/widgets/animated_card.dart';
import 'package:month_action/presentation/widgets/custom_empty_error_loading.dart';

typedef DateChangedCallback = void Function(DateTime date);

class WeeklyCalendarView extends StatefulWidget {
  final DateTime selectedDate;
  final DateChangedCallback? onDateChanged;
  const WeeklyCalendarView({
    super.key,
    required this.selectedDate,
    this.onDateChanged,
  });

  @override
  State<WeeklyCalendarView> createState() => _WeeklyCalendarViewState();
}

class _WeeklyCalendarViewState extends State<WeeklyCalendarView> {
  late DateTime _focusedDay;

  // 시간대 구분
  final List<String> _timeSlots = ['오전', '오후', '저녁'];

  // 더미 데이터: 날짜+시간대별 행동 개수
  final Map<String, int> _dummyActionCount = {
    // key: yyyy-MM-dd-오전/오후/저녁
    '${_dateKey(DateTime.now().subtract(Duration(days: 1)))}-오전': 1,
    '${_dateKey(DateTime.now())}-오후': 2,
    '${_dateKey(DateTime.now().add(Duration(days: 2)))}-저녁': 1,
  };

  static String _dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  DateTime get _startOfWeek {
    final weekday = _focusedDay.weekday;
    return _focusedDay.subtract(Duration(days: weekday - 1));
  }

  DateTime get _endOfWeek => _startOfWeek.add(const Duration(days: 6));

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForWeek(_startOfWeek, _endOfWeek);
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(widget.selectedDate, _focusedDay)) {
      setState(() {
        _focusedDay = widget.selectedDate;
      });
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForWeek(_startOfWeek, _endOfWeek);
    }
  }

  void _goToPrevWeek() {
    setState(() {
      _focusedDay = _focusedDay.subtract(const Duration(days: 7));
    });
    Provider.of<CalendarProvider>(
      context,
      listen: false,
    ).fetchActionsForWeek(_startOfWeek, _endOfWeek);
  }

  void _goToNextWeek() {
    setState(() {
      _focusedDay = _focusedDay.add(const Duration(days: 7));
    });
    Provider.of<CalendarProvider>(
      context,
      listen: false,
    ).fetchActionsForWeek(_startOfWeek, _endOfWeek);
  }

  void _goToToday() {
    setState(() {
      _focusedDay = DateTime.now();
    });
    Provider.of<CalendarProvider>(
      context,
      listen: false,
    ).fetchActionsForWeek(_startOfWeek, _endOfWeek);
  }

  void _onDaySlotTap(DateTime date) {
    setState(() {
      _focusedDay = date;
    });
    Provider.of<CalendarProvider>(
      context,
      listen: false,
    ).fetchActionsForDate(date);
    widget.onDateChanged?.call(date);
  }

  @override
  Widget build(BuildContext context) {
    final weekRange =
        '${DateFormat('M/d').format(_startOfWeek)} ~ ${DateFormat('M/d').format(_endOfWeek)}';
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Container(
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _goToPrevWeek,
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _focusedDay,
                            firstDate: DateTime(2020, 1),
                            lastDate: DateTime(2100, 12),
                            locale: const Locale('ko'),
                          );
                          if (picked != null &&
                              !isSameDay(picked, _focusedDay)) {
                            setState(() {
                              _focusedDay = picked;
                            });
                            Provider.of<CalendarProvider>(
                              context,
                              listen: false,
                            ).fetchActionsForWeek(_startOfWeek, _endOfWeek);
                            widget.onDateChanged?.call(picked);
                          }
                        },
                        child: Text(
                          weekRange,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _goToNextWeek,
                  ),
                  IconButton(
                    icon: const Icon(Icons.today, color: Colors.white),
                    onPressed: _goToToday,
                  ),
                ],
              ),
            ),
          ),
          SizedBox.shrink(),
          Expanded(
            child: Consumer<CalendarProvider>(
              builder: (context, provider, _) {
                final actions = provider.dayActions;
                final isLoading = provider.isLoading;
                final error = provider.error;
                if (isLoading) {
                  return const CustomLoading(message: '불러오는 중...');
                }
                if (error != null) {
                  return CustomError(message: '에러: $error');
                }
                if (actions.isEmpty) {
                  return const CustomEmpty(
                    message: '등록된 행동이 없습니다.',
                    emoji: '📅',
                  );
                }
                return ListView.separated(
                  itemCount: actions.length,
                  separatorBuilder: (_, __) => const SizedBox.shrink(),
                  itemBuilder: (context, idx) {
                    final action = actions[idx];
                    return AnimatedCard(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(action.title),
                        subtitle: _buildSubtitle(action),
                        trailing: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _toggleDone(context, idx),
                          child: Container(
                            width: 48,
                            alignment: Alignment.center,
                            child: Icon(
                              action.done
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: action.done ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                        onTap: () async {
                          final result = await Navigator.of(
                            context,
                            rootNavigator: true,
                          ).push(
                            MaterialPageRoute(
                              builder: (_) => ActionEditScreen(action: action),
                            ),
                          );
                          if (result == true) {
                            final provider = Provider.of<CalendarProvider>(
                              context,
                              listen: false,
                            );
                            provider.fetchActionsForDate(
                              action.date ?? DateTime.now(),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List> _groupByDate(List actions) {
    final Map<DateTime, List> map = {};
    for (var action in actions) {
      final date = DateTime(
        action.date.year,
        action.date.month,
        action.date.day,
      );
      map.putIfAbsent(date, () => []).add(action);
    }
    return map;
  }

  Widget _buildSubtitle(dynamic action) {
    if (action.category == CategoryType.expense) {
      return Text('${NumberFormat('#,###').format(action.amount)}원');
    } else if (action.description != null && action.description.isNotEmpty) {
      return Text(
        action.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  void _toggleDone(BuildContext context, int index) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final action = provider.dayActions[index];
    provider.updateAction(
      action.copyWith(done: !action.done),
      weekStart: _startOfWeek,
      weekEnd: _endOfWeek,
    );
  }
}
