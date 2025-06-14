import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/calendar_provider.dart';
import '../action/action_edit_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:month_action/data/models/action_model.dart';
import 'package:month_action/presentation/widgets/animated_card.dart';
import 'package:month_action/presentation/widgets/custom_empty_error_loading.dart';

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
                    onPressed: () => _goToPrevDay(context),
                  ),
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020, 1),
                            lastDate: DateTime(2100, 12),
                            locale: const Locale('ko'),
                          );
                          if (picked != null && picked != selectedDate) {
                            onDateChanged?.call(picked);
                            Provider.of<CalendarProvider>(
                              context,
                              listen: false,
                            ).setSelectedDate(picked);
                          }
                        },
                        child: Text(
                          DateFormat(
                            'yyyy년 M월 d일 (E)',
                            'ko',
                          ).format(selectedDate),
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
                    onPressed: () => _goToNextDay(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.today, color: Colors.white),
                    onPressed: () => _goToToday(context),
                  ),
                ],
              ),
            ),
          ),
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
                return RefreshIndicator(
                  onRefresh: () => _refresh(context),
                  child:
                      actions.isEmpty
                          ? const CustomEmpty(
                            message: '등록된 행동이 없습니다.',
                            emoji: '📅',
                          )
                          : ListView.separated(
                            itemCount: actions.length,
                            separatorBuilder:
                                (_, __) => const SizedBox.shrink(),
                            itemBuilder: (context, idx) {
                              final action = actions[idx];
                              return AnimatedCard(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(action.title),
                                  subtitle:
                                      action.category == CategoryType.expense
                                          ? Text(
                                            '${NumberFormat('#,###').format(action.amount)}원',
                                          )
                                          : (action.description?.isNotEmpty ==
                                                  true
                                              ? Text(
                                                action.description ?? '',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              )
                                              : const SizedBox.shrink()),
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
                                ),
                              );
                            },
                          ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
