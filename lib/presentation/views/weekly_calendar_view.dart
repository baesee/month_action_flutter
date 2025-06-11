import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calendar_provider.dart';
import '../action/action_edit_screen.dart';
import 'package:month_action/data/models/action_model.dart';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _goToPrevWeek,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    weekRange,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _goToNextWeek,
              ),
              IconButton(icon: const Icon(Icons.today), onPressed: _goToToday),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Consumer<CalendarProvider>(
            builder: (context, provider, _) {
              final actions = provider.dayActions;
              final grouped = _groupByDate(actions);
              final sortedDates = grouped.keys.toList()..sort();
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.error != null) {
                return Center(child: Text('에러: ${provider.error}'));
              }
              if (sortedDates.isEmpty) {
                return const Center(child: Text('데이터가 없습니다.'));
              }
              return ListView.builder(
                itemCount: sortedDates.length,
                itemBuilder: (context, idx) {
                  final date = sortedDates[idx];
                  final dayActions = grouped[date]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: Colors.grey[200],
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        child: Text(
                          DateFormat('yyyy-MM-dd (E)', 'ko').format(date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...dayActions.map(
                        (action) => _buildActionTile(context, action),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
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

  Widget _buildActionTile(BuildContext context, dynamic action) {
    return ListTile(
      title: Text(action.title),
      subtitle:
          action.category == CategoryType.expense
              ? Text('${NumberFormat('#,###').format(action.amount)}원')
              : (action.description != null && action.description.isNotEmpty
                  ? Text(
                    action.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                  : const SizedBox.shrink()),
      trailing: GestureDetector(
        onTap: () {
          Provider.of<CalendarProvider>(context, listen: false).updateAction(
            action.copyWith(done: !action.done),
            weekStart: _startOfWeek,
            weekEnd: _endOfWeek,
          );
        },
        child: Container(
          width: 48,
          alignment: Alignment.center,
          child: Icon(
            action.done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: action.done ? Colors.green : Colors.grey,
          ),
        ),
      ),
      onTap: () async {
        final result = await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => ActionEditScreen(action: action)),
        );
        if (result == true) {
          final provider = Provider.of<CalendarProvider>(
            context,
            listen: false,
          );
          provider.fetchActionsForWeek(_startOfWeek, _endOfWeek);
          provider.fetchActionsForDate(_focusedDay);
          setState(() {});
        }
      },
    );
  }
}
