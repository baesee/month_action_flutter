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

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.action.title);
    _descController = TextEditingController(text: widget.action.description);
    _selectedDate = widget.action.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
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
      description: desc,
      date: _selectedDate,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('행동 수정'),
        automaticallyImplyLeading: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '제목'),
                validator:
                    (v) => v == null || v.trim().isEmpty ? '제목을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: '설명'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '날짜: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text('날짜 선택'),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('저장'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _delete,
                  child: const Text(
                    '삭제',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
