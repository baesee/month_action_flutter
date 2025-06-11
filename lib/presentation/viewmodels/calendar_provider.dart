import 'package:flutter/material.dart';
import '../../data/models/action_model.dart' as model;
import '../../data/repositories/action_repository.dart';

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

  Future<void> addAction(model.Action action) async {
    await _actionRepo.addAction(action);
    await fetchActionsForMonth(
      DateTime(_selectedDate.year, _selectedDate.month),
    );
    await fetchActionsForDate(_selectedDate);
  }

  Future<void> updateAction(model.Action action) async {
    await _actionRepo.updateAction(action);
    await fetchActionsForMonth(
      DateTime(_selectedDate.year, _selectedDate.month),
    );
    await fetchActionsForDate(_selectedDate);
  }

  Future<void> removeAction(String id) async {
    await _actionRepo.deleteAction(id);
    await fetchActionsForMonth(
      DateTime(_selectedDate.year, _selectedDate.month),
    );
    await fetchActionsForDate(_selectedDate);
  }

  Future<void> deleteActionsByRepeatGroupId(String repeatGroupId) async {
    await _actionRepo.deleteActionsByRepeatGroupId(repeatGroupId);
    await fetchActionsForMonth(
      DateTime(_selectedDate.year, _selectedDate.month),
    );
    await fetchActionsForDate(_selectedDate);
  }
}
