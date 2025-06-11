import 'package:flutter/material.dart';
import '../../data/models/action_model.dart' as model;
import '../../data/repositories/action_repository.dart';

class ActionViewModel extends ChangeNotifier {
  final ActionRepository _repository;
  List<model.Action> _actions = [];
  bool _isLoading = false;
  String? _error;

  List<model.Action> get actions => _actions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ActionViewModel({ActionRepository? repository})
    : _repository = repository ?? ActionRepository();

  Future<void> loadActions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _actions = await _repository.getActionsSortedByDate();
    } catch (e) {
      _error = '액션 불러오기 실패: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAction(model.Action action) async {
    try {
      await _repository.addAction(action);
      await loadActions();
    } catch (e) {
      _error = '액션 추가 실패: $e';
      notifyListeners();
    }
  }

  Future<void> updateAction(model.Action action) async {
    try {
      await _repository.updateAction(action);
      await loadActions();
    } catch (e) {
      _error = '액션 수정 실패: $e';
      notifyListeners();
    }
  }

  Future<void> deleteAction(String id) async {
    try {
      await _repository.deleteAction(id);
      await loadActions();
    } catch (e) {
      _error = '액션 삭제 실패: $e';
      notifyListeners();
    }
  }

  Future<void> deleteActionsByRepeatGroupId(String repeatGroupId) async {
    try {
      await _repository.deleteActionsByRepeatGroupId(repeatGroupId);
      await loadActions();
    } catch (e) {
      _error = '반복 액션 삭제 실패: $e';
      notifyListeners();
    }
  }
}
