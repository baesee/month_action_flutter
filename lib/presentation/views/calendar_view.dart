import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calendar_provider.dart';
import '../action/action_edit_screen.dart';

typedef DateChangedCallback = void Function(DateTime date);

class CalendarView extends StatefulWidget {
  final DateTime selectedDate;
  final DateChangedCallback? onDateChanged;
  const CalendarView({
    super.key,
    required this.selectedDate,
    this.onDateChanged,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _selectedDay = widget.selectedDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForMonth(_focusedDay);
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForDate(_selectedDay!);
    });
  }

  @override
  void didUpdateWidget(covariant CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(widget.selectedDate, _selectedDay)) {
      setState(() {
        _selectedDay = widget.selectedDate;
        _focusedDay = DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month,
        );
      });
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForMonth(_focusedDay);
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForDate(widget.selectedDate);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    Provider.of<CalendarProvider>(
      context,
      listen: false,
    ).fetchActionsForDate(selectedDay);
    widget.onDateChanged?.call(selectedDay);
  }

  void _goToPrevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
    });
    widget.onDateChanged?.call(_focusedDay);
  }

  void _goToNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
    });
    widget.onDateChanged?.call(_focusedDay);
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _focusedDay = DateTime(today.year, today.month);
      _selectedDay = today;
    });
    widget.onDateChanged?.call(today);
  }

  @override
  Widget build(BuildContext context) {
    final monthStr = DateFormat('yyyy년 M월', 'ko').format(_focusedDay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForMonth(_focusedDay);
    });
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _goToPrevMonth,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _focusedDay,
                      firstDate: DateTime(2020, 1),
                      lastDate: DateTime(2100, 12),
                      locale: const Locale('ko'),
                    );
                    if (picked != null) {
                      setState(() {
                        _focusedDay = DateTime(picked.year, picked.month);
                        _selectedDay = picked;
                      });
                      widget.onDateChanged?.call(picked);
                    }
                  },
                  child: Center(
                    child: Text(
                      monthStr,
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
              IconButton(icon: const Icon(Icons.today), onPressed: _goToToday),
            ],
          ),
        ),
        TableCalendar(
          locale: 'ko_KR',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _onDaySelected,
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          headerVisible: false,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final provider = Provider.of<CalendarProvider>(
                context,
                listen: false,
              );
              final actions = provider.monthActions;
              final count =
                  actions
                      .where(
                        (a) =>
                            a.date != null &&
                            a.date!.year == day.year &&
                            a.date!.month == day.month &&
                            a.date!.day == day.day,
                      )
                      .length;
              if (count == 0) return null;
              if (count <= 5) {
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      count,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...List.generate(
                        4,
                        (i) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 2),
                        child: Text(
                          '+${count - 4}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Consumer<CalendarProvider>(
            builder: (context, provider, _) {
              final actions = provider.dayActions;
              final isLoading = provider.isLoading;
              final error = provider.error;
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (error != null) {
                return Center(child: Text('에러: $error'));
              }
              final filtered =
                  actions
                      .where(
                        (a) =>
                            a.date != null &&
                            _selectedDay != null &&
                            a.date!.year == _selectedDay!.year &&
                            a.date!.month == _selectedDay!.month &&
                            a.date!.day == _selectedDay!.day,
                      )
                      .toList();
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('등록된 행동이 없습니다.', style: TextStyle(fontSize: 16)),
                );
              }
              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final action = filtered[idx];
                  return ListTile(
                    title: Text(action.title),
                    subtitle: Text(
                      action.date != null
                          ? DateFormat('HH:mm').format(action.date!)
                          : '',
                    ),
                    trailing: GestureDetector(
                      onTap: () {
                        Provider.of<CalendarProvider>(
                          context,
                          listen: false,
                        ).updateAction(action.copyWith(done: !action.done));
                      },
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
                        provider.fetchActionsForMonth(_focusedDay);
                        provider.fetchActionsForDate(_selectedDay!);
                        setState(() {});
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
