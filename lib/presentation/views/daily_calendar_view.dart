import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calendar_provider.dart';
import '../action/action_edit_screen.dart';
import 'package:flutter/widgets.dart';

typedef DateChangedCallback = void Function(DateTime date);

class DailyCalendarView extends StatelessWidget {
  final DateTime selectedDate;
  final DateChangedCallback? onDateChanged;
  const DailyCalendarView({
    super.key,
    required this.selectedDate,
    this.onDateChanged,
  });

  void _goToPrevDay(BuildContext context) {
    final prev = selectedDate.subtract(const Duration(days: 1));
    onDateChanged?.call(prev);
    Provider.of<CalendarProvider>(context, listen: false).setSelectedDate(prev);
  }

  void _goToNextDay(BuildContext context) {
    final next = selectedDate.add(const Duration(days: 1));
    onDateChanged?.call(next);
    Provider.of<CalendarProvider>(context, listen: false).setSelectedDate(next);
  }

  void _goToToday(BuildContext context) {
    final today = DateTime.now();
    onDateChanged?.call(today);
    Provider.of<CalendarProvider>(
      context,
      listen: false,
    ).setSelectedDate(today);
  }

  Future<void> _refresh(BuildContext context) async {
    await Provider.of<CalendarProvider>(
      context,
      listen: false,
    ).fetchActionsForDate(selectedDate);
  }

  void _toggleDone(BuildContext context, int idx) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final action = provider.dayActions[idx];
    provider.updateAction(
      action.copyWith(done: !action.done),
      date: selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CalendarProvider>(
        context,
        listen: false,
      ).fetchActionsForDate(selectedDate);
    });
    return Consumer<CalendarProvider>(
      builder: (context, provider, _) {
        final actions = provider.dayActions;
        final isLoading = provider.isLoading;
        final error = provider.error;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _goToPrevDay(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat(
                          'yyyy년 M월 d일 (E)',
                          'ko',
                        ).format(selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _goToNextDay(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.today),
                    onPressed: () => _goToToday(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                      ? Center(child: Text('에러: $error'))
                      : RefreshIndicator(
                        onRefresh: () => _refresh(context),
                        child:
                            actions.isEmpty
                                ? ListView(
                                  children: const [
                                    SizedBox(height: 80),
                                    Center(
                                      child: Text(
                                        '등록된 행동이 없습니다.',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                )
                                : ListView.separated(
                                  itemCount: actions.length,
                                  separatorBuilder:
                                      (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, idx) {
                                    final action = actions[idx];
                                    return ListTile(
                                      title: Text(action.title),
                                      subtitle: Text(
                                        action.date != null
                                            ? DateFormat(
                                              'HH:mm',
                                            ).format(action.date!)
                                            : '',
                                      ),
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
                                            color:
                                                action.done
                                                    ? Colors.green
                                                    : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      onTap: () async {
                                        final result = await Navigator.of(
                                          context,
                                          rootNavigator: true,
                                        ).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ActionEditScreen(
                                                  action: action,
                                                ),
                                          ),
                                        );
                                        if (result == true) {
                                          final provider =
                                              Provider.of<CalendarProvider>(
                                                context,
                                                listen: false,
                                              );
                                          provider.fetchActionsForDate(
                                            selectedDate,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                      ),
            ),
          ],
        );
      },
    );
  }
}
