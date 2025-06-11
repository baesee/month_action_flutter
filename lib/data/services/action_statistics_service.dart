import '../models/action_model.dart';
import '../models/action_history_model.dart';
import 'package:collection/collection.dart';

class ActionStatisticsService {
  /// 일별 완료 수 집계 (Map<yyyy-MM-dd, count>)
  Map<String, int> getDailyCompletionCount(List<ActionHistory> histories) {
    final map = <String, int>{};
    for (final h in histories) {
      final key = _dateKey(h.completedAt);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// 주별 완료 수 집계 (Map<yyyy-ww, count>)
  Map<String, int> getWeeklyCompletionCount(List<ActionHistory> histories) {
    final map = <String, int>{};
    for (final h in histories) {
      final week = _weekKey(h.completedAt);
      map[week] = (map[week] ?? 0) + 1;
    }
    return map;
  }

  /// 월별 완료 수 집계 (Map<yyyy-MM, count>)
  Map<String, int> getMonthlyCompletionCount(List<ActionHistory> histories) {
    final map = <String, int>{};
    for (final h in histories) {
      final key =
          '${h.completedAt.year}-${h.completedAt.month.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  /// 카테고리별 완료 수/비율
  Map<String, int> getCategoryCompletionStats(
    List<ActionHistory> histories,
    List<Action> actions,
  ) {
    final actionMap = {for (var a in actions) a.id: a};
    final map = <String, int>{};
    for (final h in histories) {
      final action = actionMap[h.actionId];
      if (action == null) continue;
      final cat = action.category.name;
      map[cat] = (map[cat] ?? 0) + 1;
    }
    return map;
  }

  /// 연속 완료 일수(스트릭)
  int getStreak(List<ActionHistory> histories) {
    if (histories.isEmpty) return 0;
    final days =
        histories.map((h) => _dateKey(h.completedAt)).toSet().toList()..sort();
    int streak = 1;
    for (int i = days.length - 1; i > 0; i--) {
      final prev = DateTime.parse(days[i - 1]);
      final curr = DateTime.parse(days[i]);
      if (curr.difference(prev).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// 가장 자주 완료한 행동 TOP N
  List<MapEntry<String, int>> getTopActions(
    List<ActionHistory> histories,
    int n,
  ) {
    final map = <String, int>{};
    for (final h in histories) {
      map[h.actionId] = (map[h.actionId] ?? 0) + 1;
    }
    final sorted =
        map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// 시간대별(오전/오후/야간) 완료 분포
  Map<String, int> getHourlyDistribution(List<ActionHistory> histories) {
    final map = <String, int>{'morning': 0, 'afternoon': 0, 'evening': 0};
    for (final h in histories) {
      final hour = h.completedAt.hour;
      if (hour < 12) {
        map['morning'] = (map['morning'] ?? 0) + 1;
      } else if (hour < 18) {
        map['afternoon'] = (map['afternoon'] ?? 0) + 1;
      } else {
        map['evening'] = (map['evening'] ?? 0) + 1;
      }
    }
    return map;
  }

  /// 월별/주별 완료율 변화 추이 (Map<yyyy-MM, rate>)
  Map<String, double> getCompletionTrend({
    required List<ActionHistory> histories,
    required List<Action> actions,
    required String period, // 'month' or 'week'
  }) {
    final total = actions.length;
    if (total == 0) return {};
    final group =
        period == 'week'
            ? groupBy(histories, (h) => _weekKey(h.completedAt))
            : groupBy(
              histories,
              (h) =>
                  '${h.completedAt.year}-${h.completedAt.month.toString().padLeft(2, '0')}',
            );
    return group.map((k, v) => MapEntry(k, v.length / total));
  }

  /// Helper: yyyy-MM-dd
  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Helper: yyyy-ww
  String _weekKey(DateTime dt) {
    final firstDayOfYear = DateTime(dt.year, 1, 1);
    final days = dt.difference(firstDayOfYear).inDays;
    final week = (days / 7).floor() + 1;
    return '${dt.year}-W${week.toString().padLeft(2, '0')}';
  }
}
