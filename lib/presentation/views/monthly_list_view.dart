import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calendar_provider.dart';
import 'daily_calendar_view.dart';
import 'weekly_calendar_view.dart';
import 'monthly_calendar_view.dart';
import '../action/action_edit_screen.dart';
import 'package:flutter/widgets.dart';

enum MonthlyListViewType { date, category }

enum CalendarViewType { daily, weekly, monthlyList, monthlyCalendar }

class ActionItem {
  final String id;
  final String title;
  final String categoryId;
  final DateTime date;
  bool isDone;

  ActionItem({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.date,
    this.isDone = false,
  });
}

class CategoryItem {
  final String id;
  final String name;

  CategoryItem({required this.id, required this.name});
}

class MonthlyView extends StatefulWidget {
  final DateTime focusedMonth;
  const MonthlyView({super.key, required this.focusedMonth});

  @override
  State<MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends State<MonthlyView> {
  @override
  void didUpdateWidget(covariant MonthlyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedMonth != widget.focusedMonth) {
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForMonth(widget.focusedMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthStr = DateFormat('yyyy년 M월', 'ko').format(widget.focusedMonth);
    return Column(
      children: [
        Expanded(
          child: Consumer<CalendarProvider>(
            builder: (context, provider, _) {
              final actions = provider.monthActions;
              final grouped = groupByDate(actions);
              final sortedDates = grouped.keys.toList()..sort();
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
                        (action) => ListTile(
                          title: Text(action.title),
                          subtitle: Text(
                            DateFormat('HH:mm').format(action.date),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              Provider.of<CalendarProvider>(
                                context,
                                listen: false,
                              ).updateAction(
                                action.copyWith(done: !action.done),
                              );
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
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (_) => ActionEditScreen(action: action),
                              ),
                            );
                            if (result == true) {
                              Provider.of<CalendarProvider>(
                                context,
                                listen: false,
                              ).fetchActionsForMonth(widget.focusedMonth);
                            }
                          },
                        ),
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

  Map<DateTime, List> groupByDate(List actions) {
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
      leading: Checkbox(
        value: action.done,
        onChanged: (_) {
          Provider.of<CalendarProvider>(
            context,
            listen: false,
          ).updateAction(action.copyWith(done: !action.done));
        },
      ),
      title: Text(action.title),
      subtitle: Text(DateFormat('HH:mm').format(action.date)),
      trailing: Icon(
        action.done ? Icons.check_circle : Icons.radio_button_unchecked,
        color: action.done ? Colors.green : Colors.grey,
      ),
      onTap: () {
        Provider.of<CalendarProvider>(
          context,
          listen: false,
        ).updateAction(action.copyWith(done: !action.done));
      },
    );
  }
}
