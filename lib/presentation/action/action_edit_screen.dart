import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/action_model.dart' as model;
import '../viewmodels/calendar_provider.dart';

class ActionEditScreen extends StatefulWidget {
  final model.Action action;
  const ActionEditScreen({super.key, required this.action});

  @override
  State<ActionEditScreen> createState() => _ActionEditScreenState();
}

class _ActionEditScreenState extends State<ActionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _selectedDate;
  late model.CategoryType _selectedCategory;
  model.RepeatType? _selectedRepeatType;
  late List<model.PushSchedule> _selectedPushSchedules;
  model.PushSchedule? _selectedPushSchedule;
  int _amount = 0;
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.action.title);
    _descController = TextEditingController(text: widget.action.description);
    _selectedDate = widget.action.date ?? DateTime.now();
    _selectedCategory = widget.action.category;
    _selectedRepeatType = widget.action.repeatType;
    _selectedPushSchedules = List<model.PushSchedule>.from(
      widget.action.pushSchedules.isNotEmpty
          ? widget.action.pushSchedules
          : [model.PushSchedule.sameDay],
    );
    _selectedPushSchedule =
        _selectedPushSchedules.isNotEmpty ? _selectedPushSchedules.first : null;
    _amount = widget.action.amount;
    _amountController.text = _amount > 0 ? _formatWithComma(_amount) : '';
    _amountFocusNode.addListener(_onAmountFocusChange);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
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

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final updatedAction = widget.action.copyWith(
      title: title,
      description: desc.isEmpty ? null : desc,
      category: _selectedCategory,
      date: _selectedDate,
      repeatType: _selectedRepeatType,
      pushSchedules: _selectedPushSchedules,
      amount: _selectedCategory == model.CategoryType.expense ? _amount : 0,
    );
    final calendarProvider = Provider.of<CalendarProvider>(
      context,
      listen: false,
    );
    await calendarProvider.updateAction(updatedAction);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _delete() async {
    final calendarProvider = Provider.of<CalendarProvider>(
      context,
      listen: false,
    );
    await calendarProvider.removeAction(widget.action.id);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = const TextStyle(fontSize: 15, color: Colors.grey);
    final inputPadding = const EdgeInsets.symmetric(vertical: 8);
    return Scaffold(
      appBar: AppBar(
        title: const Text('행동 수정'),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 카테고리 버튼 스타일(라디오 버튼 UI 제거)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryButton(model.CategoryType.expense, '지출'),
                  const SizedBox(width: 12),
                  _buildCategoryButton(model.CategoryType.todo, '할일'),
                ],
              ),
              const SizedBox(height: 24),
              // 날짜
              Padding(
                padding: inputPadding,
                child: Row(
                  children: [
                    Text('날짜', style: labelStyle),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Text(
                        '${_selectedDate.year}. ${_selectedDate.month}. ${_selectedDate.day}. (${['월', '화', '수', '목', '금', '토', '일'][_selectedDate.weekday - 1]})',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickDate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('날짜 선택'),
                    ),
                  ],
                ),
              ),
              // 금액 입력란 (지출일 때만)
              if (_selectedCategory == model.CategoryType.expense) ...[
                const Divider(height: 24),
                Padding(
                  padding: inputPadding,
                  child: Row(
                    children: [
                      Text('금액', style: labelStyle),
                      const SizedBox(width: 24),
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '금액',
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 16),
                          validator: (v) {
                            final raw = v?.replaceAll(',', '');
                            if (_selectedCategory ==
                                model.CategoryType.expense) {
                              if (raw == null || raw.trim().isEmpty)
                                return '금액을 입력하세요';
                              if (int.tryParse(raw) == null) return '숫자만 입력하세요';
                              if (int.parse(raw) < 0) return '0 이상 입력';
                            }
                            return null;
                          },
                          onChanged: (v) {
                            setState(() {
                              _amount =
                                  int.tryParse(v.replaceAll(',', '')) ?? 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 24),
              // 제목
              Padding(
                padding: inputPadding,
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                  validator:
                      (v) => v == null || v.trim().isEmpty ? '제목을 입력하세요' : null,
                ),
              ),
              const Divider(height: 24),
              // 설명
              Padding(
                padding: inputPadding,
                child: TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: '설명',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                  maxLines: 2,
                ),
              ),
              const Divider(height: 24),
              // 반복
              Padding(
                padding: inputPadding,
                child: Row(
                  children: [
                    Text('반복', style: labelStyle),
                    const SizedBox(width: 24),
                    Expanded(
                      child: DropdownButtonFormField<model.RepeatType?>(
                        value: _selectedRepeatType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        items: [
                          const DropdownMenuItem<model.RepeatType?>(
                            value: null,
                            child: Text('없음'),
                          ),
                          ...model.RepeatType.values.map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(_repeatTypeLabel(e)),
                            ),
                          ),
                        ],
                        onChanged:
                            (v) => setState(() => _selectedRepeatType = v),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // 푸시 알림 일정
              Padding(
                padding: inputPadding,
                child: Row(
                  children: [
                    Text('푸시 알림 일정', style: labelStyle),
                    const SizedBox(width: 24),
                    Expanded(
                      child: DropdownButtonFormField<model.PushSchedule?>(
                        value: _selectedPushSchedule,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        items: [
                          const DropdownMenuItem<model.PushSchedule?>(
                            value: null,
                            child: Text('없음'),
                          ),
                          ...model.PushSchedule.values.map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(_pushScheduleLabel(e)),
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.15),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('저장', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _delete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.15),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: const Text('삭제', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ],
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
            setState(() => _selectedCategory = type);
          }
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                    : Colors.transparent,
            border: Border.all(
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color:
                  isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
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
        return '3개월';
      case model.RepeatType.halfYearly:
        return '6개월';
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
}
