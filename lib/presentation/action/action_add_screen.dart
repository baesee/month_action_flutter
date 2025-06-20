import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/action_model.dart' as model;
import '../viewmodels/calendar_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:month_action/presentation/widgets/gradient_button.dart';
import 'package:flutter/services.dart';

class ActionAddScreen extends StatefulWidget {
  const ActionAddScreen({super.key});

  @override
  State<ActionAddScreen> createState() => _ActionAddScreenState();
}

class _ActionAddScreenState extends State<ActionAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  model.CategoryType _selectedCategory = model.CategoryType.expense;
  model.RepeatType? _selectedRepeatType;
  final List<model.PushSchedule> _selectedPushSchedules = [
    model.PushSchedule.sameDay,
  ];
  model.PushSchedule? _selectedPushSchedule;
  int _amount = 0;
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  TimeOfDay? _notificationTime;

  void _focusByCategory() {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedCategory == model.CategoryType.expense) {
        _amountFocusNode.requestFocus();
      } else {
        _titleFocusNode.requestFocus();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedPushSchedule = null;
    _amountFocusNode.addListener(_onAmountFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusByCategory();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _onAmountFocusChange() {
    if (!_amountFocusNode.hasFocus) {
      final text = _amountController.text.replaceAll(',', '');
      if (text.isNotEmpty && int.tryParse(text) != null) {
        _amountController.text = _formatWithComma(int.parse(text));
      }
    }
  }

  String _formatWithComma(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime(2100, 12),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime ?? TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _notificationTime = picked;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final repeatType = _selectedRepeatType;
    final pushSchedules = List<model.PushSchedule>.from(_selectedPushSchedules);
    final amount =
        _selectedCategory == model.CategoryType.expense ? _amount : 0;
    final calendarProvider = Provider.of<CalendarProvider>(
      context,
      listen: false,
    );

    String? notificationTimeStr;
    DateTime? notificationDateTime;
    if (_selectedPushSchedule != null && _notificationTime != null) {
      notificationTimeStr = _notificationTime!.format(context);
      int daysBefore = 0;
      switch (_selectedPushSchedule!) {
        case model.PushSchedule.sameDay:
          daysBefore = 0;
          break;
        case model.PushSchedule.oneDayBefore:
          daysBefore = 1;
          break;
        case model.PushSchedule.threeDaysBefore:
          daysBefore = 3;
          break;
        case model.PushSchedule.sevenDaysBefore:
          daysBefore = 7;
          break;
      }
      final notifyDate = _selectedDate.subtract(Duration(days: daysBefore));
      notificationDateTime = DateTime(
        notifyDate.year,
        notifyDate.month,
        notifyDate.day,
        _notificationTime!.hour,
        _notificationTime!.minute,
      );
    } else {
      notificationTimeStr = null;
      notificationDateTime = null;
    }

    if (repeatType != null) {
      final repeatGroupId = const Uuid().v4();
      final dates = _generateRepeatDates(_selectedDate, repeatType);
      final futures = <Future>[];
      for (final date in dates) {
        DateTime? repeatNotificationDateTime;
        if (_selectedPushSchedule != null && _notificationTime != null) {
          int daysBefore = 0;
          switch (_selectedPushSchedule!) {
            case model.PushSchedule.sameDay:
              daysBefore = 0;
              break;
            case model.PushSchedule.oneDayBefore:
              daysBefore = 1;
              break;
            case model.PushSchedule.threeDaysBefore:
              daysBefore = 3;
              break;
            case model.PushSchedule.sevenDaysBefore:
              daysBefore = 7;
              break;
          }
          final notifyDate = date.subtract(Duration(days: daysBefore));
          repeatNotificationDateTime = DateTime(
            notifyDate.year,
            notifyDate.month,
            notifyDate.day,
            _notificationTime!.hour,
            _notificationTime!.minute,
          );
        }
        final action = model.Action(
          id: const Uuid().v4(),
          title: title,
          description: desc.isEmpty ? null : desc,
          category: _selectedCategory,
          date: date,
          repeatType: repeatType,
          pushSchedules: pushSchedules,
          done: false,
          amount: amount,
          repeatGroupId: repeatGroupId,
          notificationTime: notificationTimeStr,
          notificationDateTime: repeatNotificationDateTime,
        );
        futures.add(calendarProvider.addAction(action));
      }
      await Future.wait(futures);
    } else {
      final action = model.Action(
        id: const Uuid().v4(),
        title: title,
        description: desc.isEmpty ? null : desc,
        category: _selectedCategory,
        date: _selectedDate,
        repeatType: null,
        pushSchedules: pushSchedules,
        done: false,
        amount: amount,
        repeatGroupId: null,
        notificationTime: notificationTimeStr,
        notificationDateTime: notificationDateTime,
      );
      await calendarProvider.addAction(action);
    }
    if (mounted) {
      Future.microtask(() => Navigator.pop(context, _selectedDate));
    }
  }

  List<DateTime> _generateRepeatDates(DateTime start, model.RepeatType type) {
    final List<DateTime> dates = [];
    switch (type) {
      case model.RepeatType.weekly:
        // 최대 12개월(52주) 이내, 같은 요일
        for (int i = 0; i < 52; i++) {
          final d = start.add(Duration(days: 7 * i));
          if (d.difference(start).inDays > 365) break;
          dates.add(d);
        }
        break;
      case model.RepeatType.monthly:
        // 최대 12개월, 같은 일자
        for (int i = 0; i < 12; i++) {
          final d = DateTime(start.year, start.month + i, start.day);
          if (d.difference(start).inDays > 365) break;
          dates.add(d);
        }
        break;
      case model.RepeatType.quarterly:
        // 최대 24개월, 3개월마다
        for (int i = 0; i < 24; i += 3) {
          final d = DateTime(start.year, start.month + i, start.day);
          if (d.difference(start).inDays > 730) break;
          dates.add(d);
        }
        break;
      case model.RepeatType.halfYearly:
        // 최대 24개월, 6개월마다
        for (int i = 0; i < 24; i += 6) {
          final d = DateTime(start.year, start.month + i, start.day);
          if (d.difference(start).inDays > 730) break;
          dates.add(d);
        }
        break;
    }
    return dates;
  }

  void _onCategoryChanged(model.CategoryType type) {
    if (_selectedCategory == type) return;
    setState(() => _selectedCategory = type);
    _focusByCategory();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(fontSize: 15, color: Colors.grey);
    final inputPadding = const EdgeInsets.symmetric(vertical: 8);
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '행동 등록',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: true,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF23262F),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCategoryButton(model.CategoryType.expense, '지출'),
                    const SizedBox(width: 12),
                    _buildCategoryButton(model.CategoryType.todo, '할일'),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFormRow(
                  label: '날짜',
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '${_selectedDate.year}. ${_selectedDate.month}. ${_selectedDate.day}. (${['월', '화', '수', '목', '금', '토', '일'][_selectedDate.weekday - 1]})',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _pickDate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6DD5FA),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('변경', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
                if (_selectedCategory == model.CategoryType.expense) ...[
                  const SizedBox(height: 16),
                  _buildFormRow(
                    label: '금액',
                    child: TextFormField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Color(0xFF6DD5FA),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Color(0xFF23262F),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                      validator: (v) {
                        final raw = v?.replaceAll(',', '');
                        if (_selectedCategory == model.CategoryType.expense) {
                          if (raw == null || raw.trim().isEmpty)
                            return '금액을 입력하세요';
                          if (int.tryParse(raw) == null) return '숫자만 입력하세요';
                          if (int.parse(raw) < 0) return '0 이상 입력';
                        }
                        return null;
                      },
                      onChanged: (v) {
                        setState(() {
                          _amount = int.tryParse(v.replaceAll(',', '')) ?? 0;
                        });
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildFormRow(
                  label: '제목',
                  child: TextFormField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF6DD5FA),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFF23262F),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty ? '제목을 입력하세요' : null,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFormRow(
                  label: '설명',
                  child: TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF6DD5FA),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFF23262F),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFormRow(
                  label: '반복',
                  child: DropdownButtonFormField<model.RepeatType?>(
                    value: _selectedRepeatType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF6DD5FA),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFF23262F),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<model.RepeatType?>(
                        value: null,
                        child: Text('없음'),
                      ),
                      ...model.RepeatType.values.map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            _repeatTypeLabel(e),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedRepeatType = v),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFormRow(
                  label: '알림 일정',
                  child: DropdownButtonFormField<model.PushSchedule?>(
                    value: _selectedPushSchedule,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFF6DD5FA),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFF23262F),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<model.PushSchedule?>(
                        value: null,
                        child: Text('없음'),
                      ),
                      ...model.PushSchedule.values.map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            _pushScheduleLabel(e),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedPushSchedule = v;
                        _selectedPushSchedules.clear();
                        if (v != null) _selectedPushSchedules.add(v);
                      });
                    },
                  ),
                ),
                if (_selectedPushSchedule != null) ...[
                  const SizedBox(height: 16),
                  _buildFormRow(
                    label: '알림 시간',
                    child: GestureDetector(
                      onTap: _pickNotificationTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF23262F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          _notificationTime != null
                              ? _notificationTime!.format(context)
                              : '시간 선택',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onTap: _save,
                    height: 52,
                    borderRadius: 16,
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(model.CategoryType type, String label) {
    final isSelected = _selectedCategory == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedCategory != type) {
            _onCategoryChanged(type);
          }
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6DD5FA) : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  String _repeatTypeLabel(model.RepeatType e) {
    switch (e) {
      case model.RepeatType.weekly:
        return '매주';
      case model.RepeatType.monthly:
        return '매월';
      case model.RepeatType.quarterly:
        return '분기마다';
      case model.RepeatType.halfYearly:
        return '반기마다';
    }
  }

  String _pushScheduleLabel(model.PushSchedule e) {
    switch (e) {
      case model.PushSchedule.sameDay:
        return '당일';
      case model.PushSchedule.oneDayBefore:
        return '1일 전';
      case model.PushSchedule.threeDaysBefore:
        return '3일 전';
      case model.PushSchedule.sevenDaysBefore:
        return '7일 전';
    }
  }

  Widget _buildFormRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
