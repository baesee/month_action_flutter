import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calendar_provider.dart';
import '../action/action_edit_screen.dart';
import 'package:month_action/data/models/action_model.dart';
import 'package:month_action/presentation/widgets/animated_card.dart';
import 'package:month_action/presentation/widgets/custom_empty_error_loading.dart';

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

  Widget _buildSubtitle(action) {
    if (action.category == CategoryType.expense) {
      return Text('${NumberFormat('#,###').format(action.amount)}원');
    } else if (action.category == CategoryType.todo) {
      if (action.description?.isNotEmpty == true) {
        return Text(
          action.description!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      } else {
        return const SizedBox.shrink();
      }
    }
    return const SizedBox.shrink();
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
                  onPressed: _goToToday,
                ),
              ],
            ),
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
              color: Color(0xFF6DD5FA),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Color(0xFFF7971E),
              shape: BoxShape.circle,
            ),
            markerDecoration: BoxDecoration(
              color: Color(0xFF6DD5FA),
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(color: Colors.white70),
            defaultTextStyle: TextStyle(color: Colors.white),
            outsideTextStyle: TextStyle(color: Colors.white24),
          ),
          headerVisible: false,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              final provider = Provider.of<CalendarProvider>(
                context,
                listen: false,
              );
              final actions =
                  provider.monthActions
                      .where(
                        (a) =>
                            a.date != null &&
                            a.date!.year == day.year &&
                            a.date!.month == day.month &&
                            a.date!.day == day.day,
                      )
                      .toList();

              if (actions.isEmpty) return null;

              // 최대 5개까지 점 표시, 6개 이상이면 +N
              final dots =
                  actions.take(5).map((action) {
                    final color =
                        action.category.toString() == 'CategoryType.expense'
                            ? Colors.red
                            : Colors.blue;
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList();

              if (actions.length > 5) {
                dots.removeRange(4, dots.length); // 4개만 남기고
                dots.add(
                  Container(
                    margin: const EdgeInsets.only(left: 2),
                    child: Text(
                      '+${actions.length - 4}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dots,
                ),
              );
            },
          ),
        ),
        const SizedBox.shrink(),
        Expanded(
          child: Consumer<CalendarProvider>(
            builder: (context, provider, _) {
              final actions = provider.dayActions;
              final isLoading = provider.isLoading;
              final error = provider.error;
              if (isLoading) {
                return const CustomLoading(message: '캘린더 불러오는 중...');
              }
              if (error != null) {
                return CustomError(
                  message: '에러: $error',
                  onRetry: () {
                    Provider.of<CalendarProvider>(
                      context,
                      listen: false,
                    ).fetchActionsForMonth(_focusedDay);
                  },
                );
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
                return const CustomEmpty(message: '등록된 항목이 없습니다.', emoji: '��');
              }
              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox.shrink(),
                itemBuilder: (context, idx) {
                  final action = filtered[idx];
                  return AnimatedCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            action.category == CategoryType.expense
                                ? const Color(0xFFF7971E)
                                : const Color(0xFF6DD5FA),
                        child: Icon(
                          action.category == CategoryType.expense
                              ? Icons.attach_money
                              : Icons.check,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        action.date != null
                            ? DateFormat(
                              'yyyy-MM-dd (E)',
                              'ko',
                            ).format(action.date!)
                            : '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      trailing: Icon(
                        action.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            action.done
                                ? const Color(0xFF6DD5FA)
                                : Colors.white24,
                        size: 28,
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
                    ),
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
