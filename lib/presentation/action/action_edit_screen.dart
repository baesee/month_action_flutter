import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/action_model.dart' as model;
import '../viewmodels/calendar_provider.dart';
import 'package:month_action/presentation/widgets/gradient_button.dart';

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
  final _titleFocusNode = FocusNode();

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
    final repeatGroupId = widget.action.repeatGroupId;
    if (repeatGroupId != null) {
      final result = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('반복 행동 삭제'),
              content: const Text('이 행동은 반복 등록된 일정입니다.\n반복 등록된 모든 일정을 삭제할까요?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('아니오'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('네, 모두 삭제'),
                ),
              ],
            ),
      );
      if (result == true) {
        await calendarProvider.deleteActionsByRepeatGroupId(repeatGroupId);
        if (mounted) Navigator.pop(context, true);
        return;
      }
    }
    // 반복 없음 또는 '아니오' 선택 시 단일 삭제
    await calendarProvider.removeAction(widget.action.id);
    if (mounted) {
      Navigator.pop(context, true);
    }
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
          '행동 수정',
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
                          '$_selectedDate.year. $_selectedDate.month. $_selectedDate.day. (${['월', '화', '수', '목', '금', '토', '일'][_selectedDate.weekday - 1]})',
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
        onTap: () => _onCategoryChanged(type),
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
