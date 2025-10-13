import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';

class RecipeFormScreen extends StatefulWidget {
  final String? recipeId; // null => create, else edit
  const RecipeFormScreen({super.key, this.recipeId});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _prep = TextEditingController(text: '0');
  final _cook = TextEditingController(text: '0');
  final _servings = TextEditingController(text: '1');
  String _difficulty = 'medium';
  String _category = 'other';
  String _imageDataUri = '';
  final _tags = TextEditingController();
  bool _isPublic = false;

  final List<Map<String, String>> _ingredients = [
    {'name': '', 'quantity': '', 'unit': ''},
  ];
  final List<Map<String, dynamic>> _instructions = [
    {'step': 1, 'description': ''},
  ];

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipeId != null) {
      _loadInitial(widget.recipeId!);
    }
  }

  Future<void> _loadInitial(String id) async {
    setState(() => _busy = true);
    try {
      final r = await RecipeApiService.getMyRecipeDetail(id);
      _title.text = r.title;
      _desc.text = r.description;
      _prep.text = r.prepTime.toString();
      _cook.text = r.cookTime.toString();
      _servings.text = r.servings.toString();
      _difficulty = r.difficulty;
      _category = r.category;
      _tags.text = r.tags.join(',');
      _isPublic = true; // không có cờ trong model, tùy chỉnh theo UI
      // map ingredients/instructions
      _ingredients
        ..clear()
        ..addAll(r.ingredients.map((e) => {
              'name': e.name,
              'quantity': e.quantity,
              'unit': e.unit,
            }));
      _instructions
        ..clear()
        ..addAll(r.instructions.map((e) => {
              'step': e.step,
              'description': e.description,
            }));
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không tải được công thức: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 85);
    if (picked == null) return;
    final mime = picked.mimeType ?? 'image/jpeg';
    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() => _imageDataUri = 'data:$mime;base64,$b64');
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final desc = _desc.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề và mô tả')));
      return;
    }
    if (_ingredients.where((e) => (e['name'] ?? '').trim().isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm ít nhất 1 nguyên liệu')));
      return;
    }
    if (_instructions.where((e) => (e['description'] ?? '').trim().isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm ít nhất 1 bước hướng dẫn')));
      return;
    }

    setState(() => _busy = true);
    try {
      final tagList = _tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final imgUpload = _imageDataUri.isNotEmpty ? _imageDataUri : null;
      final ing = _ingredients.where((e) => (e['name'] ?? '').trim().isNotEmpty).toList();
      final steps = _instructions
          .where((e) => (e['description'] ?? '').trim().isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((entry) => {'step': entry.key + 1, 'description': entry.value['description']})
          .toList();

      if (widget.recipeId == null) {
        await RecipeApiService.createRecipeFromFields(
          title: title,
          description: desc,
          category: _category,
          prepTime: int.tryParse(_prep.text) ?? 0,
          cookTime: int.tryParse(_cook.text) ?? 0,
          servings: int.tryParse(_servings.text) ?? 1,
          difficulty: _difficulty,
          imageUpload: imgUpload,
          tags: tagList,
          ingredients: ing,
          instructions: steps,
          isPublic: _isPublic,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo công thức')));
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context, true);
        } else {
          // On root tab, just reset form to allow creating another
          setState(() {
            _title.clear();
            _desc.clear();
            _prep.text = '0';
            _cook.text = '0';
            _servings.text = '1';
            _difficulty = 'medium';
            _category = 'other';
            _imageDataUri = '';
            _tags.clear();
            _isPublic = false;
            _ingredients
              ..clear()
              ..add({'name': '', 'quantity': '', 'unit': ''});
            _instructions
              ..clear()
              ..add({'step': 1, 'description': ''});
          });
        }
      } else {
        await RecipeApiService.updateRecipeFromFields(
          widget.recipeId!,
          title: title,
          description: desc,
          category: _category,
          prepTime: int.tryParse(_prep.text),
          cookTime: int.tryParse(_cook.text),
          servings: int.tryParse(_servings.text),
          difficulty: _difficulty,
          imageUpload: imgUpload,
          tags: tagList,
          ingredients: ing,
          instructions: steps,
          isPublic: _isPublic,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật công thức')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeId == null ? 'Tạo công thức' : 'Sửa công thức'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Tiêu đề')), const SizedBox(height: 12),
            TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Mô tả')), const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _prep, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Chuẩn bị (phút)'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _cook, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nấu (phút)'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _servings, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Khẩu phần'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DropdownField<String>(
                label: 'Độ khó',
                value: _difficulty,
                items: const ['easy', 'medium', 'hard'],
                onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _DropdownField<String>(
                label: 'Danh mục',
                value: _category,
                items: const ['breakfast', 'lunch', 'dinner', 'dessert', 'snack', 'beverage', 'other'],
                onChanged: (v) => setState(() => _category = v ?? 'other'),
              )),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _tags, decoration: const InputDecoration(labelText: 'Tags (phân tách bởi dấu phẩy)')),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text('Chọn ảnh')),
              const SizedBox(width: 12),
              if (_imageDataUri.isNotEmpty) const Icon(Icons.check_circle, color: AppTheme.successGreen),
            ]),
            const SizedBox(height: 12),
            SwitchListTile(value: _isPublic, onChanged: (v) => setState(() => _isPublic = v), title: const Text('Công khai')),  
            const SizedBox(height: 12),
            Text('Nguyên liệu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._ingredients.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(children: [
                  Expanded(child: TextField(onChanged: (v) => _ingredients[i]['name'] = v, decoration: const InputDecoration(hintText: 'Tên'))),
                  const SizedBox(width: 8),
                  SizedBox(width: 90, child: TextField(onChanged: (v) => _ingredients[i]['quantity'] = v, decoration: const InputDecoration(hintText: 'SL'))),
                  const SizedBox(width: 8),
                  SizedBox(width: 80, child: TextField(onChanged: (v) => _ingredients[i]['unit'] = v, decoration: const InputDecoration(hintText: 'ĐVT'))),
                  IconButton(onPressed: () => setState(() => _ingredients.removeAt(i)), icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorRed))
                ]),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(onPressed: () => setState(() => _ingredients.add({'name': '', 'quantity': '', 'unit': ''})), icon: const Icon(Icons.add), label: const Text('Thêm nguyên liệu')),
            ),
            const SizedBox(height: 12),
            Text('Hướng dẫn', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._instructions.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(children: [
                  SizedBox(width: 36, child: Text('${i + 1}', textAlign: TextAlign.center)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(onChanged: (v) => _instructions[i]['description'] = v, decoration: const InputDecoration(hintText: 'Mô tả bước'))),
                  IconButton(onPressed: () => setState(() => _instructions.removeAt(i)), icon: const Icon(Icons.remove_circle_outline, color: AppTheme.errorRed))
                ]),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(onPressed: () => setState(() => _instructions.add({'step': _instructions.length + 1, 'description': ''})), icon: const Icon(Icons.add), label: const Text('Thêm bước')),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _busy ? null : _submit, child: Text(widget.recipeId == null ? 'Tạo công thức' : 'Lưu thay đổi')),
            )
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label; final T value; final List<T> items; final ValueChanged<T?> onChanged;
  const _DropdownField({required this.label, required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString()))).toList(),
        ),
      ),
    );
  }
}
