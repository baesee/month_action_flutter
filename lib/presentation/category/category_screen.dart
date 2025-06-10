import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/category_model.dart';
import 'category_viewmodel.dart';
import 'package:uuid/uuid.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryViewModel()..loadCategories(),
      child: Consumer<CategoryViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('카테고리 관리'),
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
                      itemCount: vm.categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final category = vm.categories[idx];
                        return ListTile(
                          title: Text(category.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed:
                                    () =>
                                        _showEditDialog(context, vm, category),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed:
                                    () => _showDeleteDialog(
                                      context,
                                      vm,
                                      category,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddDialog(context, vm),
              tooltip: '카테고리 추가',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, CategoryViewModel vm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('카테고리 추가'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    final newCategory = Category(
                      id: const Uuid().v4(),
                      name: name,
                    );
                    vm.addCategory(newCategory);
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
    CategoryViewModel vm,
    Category category,
  ) {
    final controller = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('카테고리 수정'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty && name != category.name) {
                    final updated = Category(id: category.id, name: name);
                    vm.updateCategory(updated);
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
    CategoryViewModel vm,
    Category category,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('카테고리 삭제'),
            content: Text('정말 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  vm.deleteCategory(category.id);
                  Navigator.pop(context);
                },
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }
}
