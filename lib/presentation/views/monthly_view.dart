import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calendar_provider.dart';
import 'daily_calendar_view.dart';
import 'weekly_calendar_view.dart';
import 'calendar_view.dart';
import '../action/action_edit_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:month_action/data/models/action_model.dart';

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

class MonthlyView extends StatelessWidget {
  final DateTime focusedMonth;
  const MonthlyView({super.key, required this.focusedMonth});

  @override
  Widget build(BuildContext context) {
    // build 시 선택된 월 전체 데이터를 fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForMonth(focusedMonth);
    });
    return Consumer<CalendarProvider>(
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
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 18,
                  ),
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF23262F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd (E)', 'ko').format(date),
                    style: const TextStyle(
                      color: Color(0xFFBFC4CE),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                ...dayActions.map(
                  (action) => ListTile(
                    title: Text(action.title),
                    subtitle: _buildSubtitle(action),
                    trailing: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Provider.of<CalendarProvider>(
                          context,
                          listen: false,
                        ).updateAction(
                          action.copyWith(done: !action.done),
                          month: focusedMonth,
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
                        provider.fetchActionsForMonth(focusedMonth);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
      onTap: () async {
        final result = await Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (_) => ActionEditScreen(action: action)),
        );
        if (result == true) {
          final provider = Provider.of<CalendarProvider>(
            context,
            listen: false,
          );
          provider.fetchActionsForMonth(focusedMonth);
        }
      },
    );
  }
}
