import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';

class RecipeFormScreen extends StatefulWidget {
  final String? recipeId;
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
  String? _existingImageUrl;
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
      _existingImageUrl = (r.imageUrl.isNotEmpty) ? r.imageUrl : null;
      _imageDataUri = '';
      _isPublic = r.isPublic;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được công thức: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (picked == null) return;
    final mime = picked.mimeType ?? 'image/jpeg';
    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() {
      _existingImageUrl = null;
      _imageDataUri = 'data:$mime;base64,$b64';
    });
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final desc = _desc.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và mô tả')),
      );
      return;
    }
    if (_ingredients.where((e) => (e['name'] ?? '').trim().isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm ít nhất 1 nguyên liệu')),
      );
      return;
    }
    if (_instructions.where((e) => (e['description'] ?? '').trim().isNotEmpty).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm ít nhất 1 bước hướng dẫn')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo công thức')),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _title.clear();
            _desc.clear();
            _prep.text = '0';
            _cook.text = '0';
            _servings.text = '1';
            _difficulty = 'medium';
             _category = 'other';
            _imageDataUri = '';
            _existingImageUrl = null;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật công thức')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.recipeId == null ? 'Tạo công thức mới' : 'Chỉnh sửa công thức',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info Section
                _buildSection(
                  title: 'Thông tin cơ bản',
                  icon: Icons.info_outline,
                  children: [
                    _buildTextField(
                      controller: _title,
                      label: 'Tên món ăn',
                      hint: 'VD: Phở bò Hà Nội',
                      icon: Icons.restaurant_menu,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _desc,
                      label: 'Mô tả',
                      hint: 'Mô tả ngắn gọn về món ăn của bạn',
                      icon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _tags,
                      label: 'Tags',
                      hint: 'VD: nhanh, dễ làm, ít dầu mỡ',
                      icon: Icons.local_offer_outlined,
                      helperText: 'Phân tách bởi dấu phẩy',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Image Section
                _buildSection(
                  title: 'Hình ảnh',
                  icon: Icons.image_outlined,
                  children: [
                    _buildImagePicker(),
                  ],
                ),
                const SizedBox(height: 24),

                // Details Section
                _buildSection(
                  title: 'Chi tiết',
                  icon: Icons.tune,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _prep,
                            label: 'Chuẩn bị',
                            suffix: 'phút',
                            icon: Icons.access_time,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _cook,
                            label: 'Nấu',
                            suffix: 'phút',
                            icon: Icons.timer_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _servings,
                            label: 'Khẩu phần',
                            suffix: 'người',
                            icon: Icons.people_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Độ khó',
                            value: _difficulty,
                            icon: Icons.signal_cellular_alt,
                            items: const [
                              {'value': 'easy', 'label': 'Dễ'},
                              {'value': 'medium', 'label': 'Trung bình'},
                              {'value': 'hard', 'label': 'Khó'},
                            ],
                            onChanged: (v) => setState(() => _difficulty = v ?? 'medium'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Danh mục',
                            value: _category,
                            icon: Icons.category_outlined,
                            items: const [
                              {'value': 'breakfast', 'label': 'Sáng'},
                              {'value': 'lunch', 'label': 'Trưa'},
                              {'value': 'dinner', 'label': 'Tối'},
                              {'value': 'dessert', 'label': 'Tráng miệng'},
                              {'value': 'snack', 'label': 'Ăn vặt'},
                              {'value': 'beverage', 'label': 'Đồ uống'},
                              {'value': 'other', 'label': 'Khác'},
                            ],
                            onChanged: (v) => setState(() => _category = v ?? 'other'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPublicSwitch(),
                  ],
                ),
                const SizedBox(height: 24),

                // Ingredients Section
                _buildSection(
                  title: 'Nguyên liệu',
                  icon: Icons.shopping_basket_outlined,
                  children: [
                    ..._ingredients.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ingredient = entry.value;
                      return _buildIngredientRow(i, ingredient);
                    }),
                    const SizedBox(height: 8),
                    _buildAddButton(
                      label: 'Thêm nguyên liệu',
                      onPressed: () => setState(() {
                        _ingredients.add({'name': '', 'quantity': '', 'unit': ''});
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Instructions Section
                _buildSection(
                  title: 'Hướng dẫn',
                  icon: Icons.format_list_numbered,
                  children: [
                    ..._instructions.asMap().entries.map((entry) {
                      final i = entry.key;
                      final instruction = entry.value;
                      return _buildInstructionRow(i, instruction);
                    }),
                    const SizedBox(height: 8),
                    _buildAddButton(
                      label: 'Thêm bước',
                      onPressed: () => setState(() {
                        _instructions.add({
                          'step': _instructions.length + 1,
                          'description': '',
                        });
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          // Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primaryOrange),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? helperText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required IconData icon,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    onChanged: onChanged,
                    items: items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    final preview = _resolveImagePreview();
    final hasImage = preview != null;

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? AppTheme.primaryOrange : Colors.grey[300]!,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage ? _buildSelectedImage(preview!) : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: AppTheme.primaryOrange,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Thêm ảnh món ăn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Nhấn để chọn từ thư viện',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget? _resolveImagePreview() {
    if (_imageDataUri.isNotEmpty) {
      return _buildDataImage(_imageDataUri);
    }
    final url = _existingImageUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      return _buildDataImage(url);
    }
    return _buildNetworkImage(url);
  }

  Widget? _buildDataImage(String dataUri) {
    final parts = dataUri.split(',');
    final encoded = parts.length > 1 ? parts.sublist(1).join(',') : dataUri;
    try {
      final bytes = base64Decode(encoded);
      return Image.memory(
        bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: AppTheme.errorRed),
        );
      },
    );
  }

  Widget _buildSelectedImage(Widget child) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppTheme.successGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPublicSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SwitchListTile(
        value: _isPublic,
        onChanged: (v) => setState(() => _isPublic = v),
        title: const Text(
          'Công khai công thức',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _isPublic ? 'Mọi người có thể xem' : 'Chỉ bạn có thể xem',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        activeColor: AppTheme.primaryOrange,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildIngredientRow(int index, Map<String, String> ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: ingredient['name'])
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: ingredient['name']?.length ?? 0),
                    ),
                  onChanged: (v) => _ingredients[index]['name'] = v,
                  decoration: InputDecoration(
                    hintText: 'Tên nguyên liệu',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _ingredients.removeAt(index)),
                icon: const Icon(Icons.close, size: 20),
                color: AppTheme.errorRed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: TextEditingController(text: ingredient['quantity'])
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: ingredient['quantity']?.length ?? 0),
                    ),
                  onChanged: (v) => _ingredients[index]['quantity'] = v,
                  decoration: InputDecoration(
                    hintText: 'Số lượng',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: TextEditingController(text: ingredient['unit'])
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: ingredient['unit']?.length ?? 0),
                    ),
                  onChanged: (v) => _ingredients[index]['unit'] = v,
                  decoration: InputDecoration(
                    hintText: 'Đơn vị',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(int index, Map<String, dynamic> instruction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: instruction['description'])
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: instruction['description']?.length ?? 0),
                ),
              onChanged: (v) => _instructions[index]['description'] = v,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Mô tả bước thực hiện...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _instructions.removeAt(index)),
            icon: const Icon(Icons.close, size: 20),
            color: AppTheme.errorRed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryOrange, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              color: AppTheme.primaryOrange,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.recipeId == null ? Icons.add : Icons.save,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.recipeId == null ? 'Tạo công thức' : 'Lưu thay đổi',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
