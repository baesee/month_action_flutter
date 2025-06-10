import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/action_model.dart' as model;
import 'action_viewmodel.dart';
import 'package:uuid/uuid.dart';

class ActionScreen extends StatelessWidget {
  const ActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActionViewModel()..loadActions(),
      child: Consumer<ActionViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('행동(액션) 관리'),
              automaticallyImplyLeading: false,
              leading:
                  ModalRoute.of(context)?.isFirst == true
                      ? null
                      : const BackButton(),
            ),
            body:
                vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.error != null
                    ? Center(child: Text(vm.error!))
                    : ListView.separated(
                      itemCount: vm.actions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final action = vm.actions[idx];
                        return ListTile(
                          title: Text(action.title),
                          subtitle: Text(action.description),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed:
                                    () => _showEditDialog(context, vm, action),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed:
                                    () =>
                                        _showDeleteDialog(context, vm, action),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddDialog(context, vm),
              tooltip: '행동 추가',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, ActionViewModel vm) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('행동 추가'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '설명'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final desc = descController.text.trim();
                  if (title.isNotEmpty) {
                    final newAction = model.Action(
                      id: const Uuid().v4(),
                      title: title,
                      description: desc,
                      date: DateTime.now(),
                    );
                    vm.addAction(newAction);
                    Navigator.pop(context);
                  }
                },
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    ActionViewModel vm,
    model.Action action,
  ) {
    final titleController = TextEditingController(text: action.title);
    final descController = TextEditingController(text: action.description);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('행동 수정'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '설명'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final desc = descController.text.trim();
                  if (title.isNotEmpty &&
                      (title != action.title || desc != action.description)) {
                    final updated = model.Action(
                      id: action.id,
                      title: title,
                      description: desc,
                      date: action.date,
                    );
                    vm.updateAction(updated);
                    Navigator.pop(context);
                  }
                },
                child: const Text('수정'),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ActionViewModel vm,
    model.Action action,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('행동 삭제'),
            content: Text('정말 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  vm.deleteAction(action.id);
                  Navigator.pop(context);
                },
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }
}
