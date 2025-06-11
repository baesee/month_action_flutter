import 'package:flutter/material.dart';
import '../../data/models/action_model.dart' as model;
import '../../data/repositories/action_repository.dart';
import '../../data/repositories/action_history_repository.dart';
import '../../data/models/action_history_model.dart' as history_model;

class CalendarProvider extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  List<model.Action> _monthActions = [];
  List<model.Action> _dayActions = [];
  bool _isLoading = false;
  String? _error;

  DateTime get selectedDate => _selectedDate;
  List<model.Action> get monthActions => _monthActions;
  List<model.Action> get dayActions => _dayActions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ActionRepository _actionRepo = ActionRepository();
  final ActionHistoryRepository _actionHistoryRepo = ActionHistoryRepository();

  CalendarProvider() {
    fetchActionsForMonth(DateTime(_selectedDate.year, _selectedDate.month));
    fetchActionsForDate(_selectedDate);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchActionsForDate(date);
    notifyListeners();
  }

  Future<void> fetchActionsForDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dayActions = await _actionRepo.getActionsByDate(date);
    } catch (e) {
      _error = e.toString();
      _dayActions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActionsForMonth(DateTime month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _monthActions = await _actionRepo.getActionsByMonth(month);
    } catch (e) {
      _error = e.toString();
      _monthActions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActionsForWeek(DateTime weekStart, DateTime weekEnd) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _dayActions = await _actionRepo.getActionsByWeek(weekStart, weekEnd);
    } catch (e) {
      _error = e.toString();
      _dayActions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAction(model.Action action, {DateTime? month}) async {
    await _actionRepo.addAction(action);
    if (month != null) {
      await fetchActionsForMonth(month);
    } else {
      await fetchActionsForMonth(
        DateTime(_selectedDate.year, _selectedDate.month),
      );
    }
    await fetchActionsForDate(_selectedDate);
  }

  Future<void> updateAction(
    model.Action action, {
    DateTime? month,
    DateTime? date,
    DateTime? weekStart,
    DateTime? weekEnd,
  }) async {
    final prev = await _actionRepo.getAction(action.id);
    final prevDone = prev?.done ?? false;
    await _actionRepo.updateAction(action);
    if (prevDone != action.done) {
      if (action.done) {
        final history = history_model.ActionHistory(
          id: UniqueKey().toString(),
          actionId: action.id,
          completedAt: DateTime.now(),
        );
        await _actionHistoryRepo.addActionHistory(history);
        debugPrint('[ActionHistory] 완료 이력 추가: ${action.id}');
      } else {
        final histories = await _actionHistoryRepo.getHistoriesByActionId(
          action.id,
        );
        if (histories.isNotEmpty) {
          histories.sort((a, b) => b.completedAt.compareTo(a.completedAt));
          await _actionHistoryRepo.deleteActionHistory(histories.first.id);
          debugPrint('[ActionHistory] 완료 이력 삭제(Undo): ${action.id}');
        }
      }
    }
    if (month != null) {
      await fetchActionsForMonth(month);
    }
    if (weekStart != null && weekEnd != null) {
      await fetchActionsForWeek(weekStart, weekEnd);
    }
    if (date != null) {
      await fetchActionsForDate(date);
    }
  }

  Future<void> removeAction(String id, {DateTime? month}) async {
    await _actionRepo.deleteAction(id);
    final histories = await _actionHistoryRepo.getHistoriesByActionId(id);
    for (final h in histories) {
      await _actionHistoryRepo.deleteActionHistory(h.id);
    }
    if (month != null) {
      await fetchActionsForMonth(month);
    } else {
      await fetchActionsForMonth(
        DateTime(_selectedDate.year, _selectedDate.month),
      );
    }
    await fetchActionsForDate(_selectedDate);
  }

  Future<void> deleteActionsByRepeatGroupId(
    String repeatGroupId, {
    DateTime? month,
  }) async {
    await _actionRepo.deleteActionsByRepeatGroupId(repeatGroupId);
    if (month != null) {
      await fetchActionsForMonth(month);
    } else {
      await fetchActionsForMonth(
        DateTime(_selectedDate.year, _selectedDate.month),
      );
    }
    await fetchActionsForDate(_selectedDate);
  }
}
