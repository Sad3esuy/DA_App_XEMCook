import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:test_ui_app/services/recipe_api_service.dart';
import 'package:test_ui_app/theme/app_theme.dart';
import 'package:dotted_border/dotted_border.dart';

class RecipeFormScreen extends StatefulWidget {
  final String? recipeId;
  const RecipeFormScreen({super.key, this.recipeId});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _prep = TextEditingController(text: '');
  final _cook = TextEditingController(text: '');
  final _servings = TextEditingController(text: '');
  String _difficulty = 'medium';
  String _category = 'other';
  String _imageDataUri = '';
  String? _existingImageUrl;
  final List<String> _tagList = [];
  final _tagInputController = TextEditingController();
  bool _isPublic = false;

  final List<Map<String, String>> _ingredients = [
    {'name': '', 'quantity': '', 'unit': ''},
  ];
  final List<Map<String, dynamic>> _instructions = [];

  Map<String, dynamic> _emptyInstruction({
    String? id,
    String description = '',
    String imageUrl = '',
    String imagePublicId = '',
  }) {
    return {
      'id': id,
      'description': description,
      'imageDataUri': '',
      'imageUrl': imageUrl,
      'imagePublicId': imagePublicId,
      'removeImage': false,
    };
  }

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _instructions.add(_emptyInstruction());
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
      _tagList.clear();
      _tagList.addAll(r.tags);
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
        ..addAll(r.instructions.map((e) => _emptyInstruction(
              id: e.id,
              description: e.description,
              imageUrl: e.imageUrl ?? '',
              imagePublicId: e.imagePublicId ?? '',
            )));
      if (_instructions.isEmpty) {
        _instructions.add(_emptyInstruction());
      }
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
    if (_ingredients
        .where((e) => (e['name'] ?? '').trim().isNotEmpty)
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm ít nhất 1 nguyên liệu')),
      );
      return;
    }
    if (_instructions
        .where((e) => (e['description'] ?? '').trim().isNotEmpty)
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm ít nhất 1 bước hướng dẫn')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final imgUpload = _imageDataUri.isNotEmpty ? _imageDataUri : null;
      final ing = _ingredients
          .where((e) => (e['name'] ?? '').trim().isNotEmpty)
          .toList();
      final filteredInstructions = _instructions
          .where((e) => ((e['description'] ?? '') as String).trim().isNotEmpty)
          .toList();
      final steps = <Map<String, dynamic>>[];
      for (var i = 0; i < filteredInstructions.length; i++) {
        final item = filteredInstructions[i];
        final desc = ((item['description'] ?? '') as String).trim();
        final payload = <String, dynamic>{
          'step': i + 1,
          'description': desc,
        };
        final id = item['id'];
        if (widget.recipeId != null && id is String && id.trim().isNotEmpty) {
          payload['id'] = id;
        }

        final dataUri = ((item['imageDataUri'] ?? '') as String).trim();
        if (dataUri.isNotEmpty) {
          payload['imageUpload'] = dataUri;
        } else if (item['removeImage'] == true) {
          payload['removeImage'] = true;
        } else {
          final imageUrl = ((item['imageUrl'] ?? '') as String).trim();
          if (imageUrl.isNotEmpty) {
            payload['imageUrl'] = imageUrl;
            final imagePublicId =
                ((item['imagePublicId'] ?? '') as String).trim();
            if (imagePublicId.isNotEmpty) {
              payload['imagePublicId'] = imagePublicId;
            }
          }
        }
        steps.add(payload);
      }

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
          tags: _tagList,
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
            _tagList.clear();
            _isPublic = false;
            _ingredients
              ..clear()
              ..add({'name': '', 'quantity': '', 'unit': ''});
            _instructions
              ..clear()
              ..add(_emptyInstruction());
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
          tags: _tagList,
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          widget.recipeId == null ? 'Tạo công thức mới' : 'Chỉnh sửa công thức',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image picker section
            _buildImageSection(),

            // Form content
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                children: [
                  // Basic Info
                  _buildCardSection(
                    children: [
                      _buildSectionHeader('Thông tin cơ bản', Icons.edit_note),
                      const SizedBox(height: 16),
                      _buildSimpleTextField(
                        controller: _title,
                        label: 'Tên món ăn',
                        hint: 'VD: Phở bò Hà Nội',
                      ),
                      const SizedBox(height: 12),
                      _buildSimpleTextField(
                        controller: _desc,
                        label: 'Mô tả',
                        hint: 'Mô tả ngắn gọn về món ăn...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildTagInput(),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Cooking details
                  _buildCardSection(
                    children: [
                      _buildSectionHeader('Chi tiết', Icons.schedule),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildNumberField(
                              controller: _prep,
                              label: 'Chuẩn bị',
                              unit: 'phút',
                              hint: '0',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNumberField(
                              controller: _cook,
                              label: 'Nấu',
                              unit: 'phút',
                              hint: '0',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildNumberField(
                              controller: _servings,
                              label: 'Khẩu phần',
                              unit: 'người',
                              hint: '1',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDifficultySelector(),
                      const SizedBox(height: 12),
                      _buildCategorySelector(),
                      const SizedBox(height: 12),
                      _buildPublicSwitch(),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Ingredients
                  _buildCardSection(
                    children: [
                      _buildSectionHeader(
                          'Nguyên liệu', Icons.shopping_basket_outlined),
                      const SizedBox(height: 12),
                      ..._ingredients.asMap().entries.map((entry) {
                        return _buildIngredientInput(entry.key, entry.value);
                      }),
                      const SizedBox(height: 8),
                      _buildAddButton(
                        label: 'Thêm nguyên liệu',
                        onPressed: () => setState(() {
                          _ingredients
                              .add({'name': '', 'quantity': '', 'unit': ''});
                        }),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Instructions
                  _buildCardSection(
                    children: [
                      _buildSectionHeader(
                          'Hướng dẫn nấu', Icons.format_list_numbered),
                      const SizedBox(height: 12),
                      ..._instructions.asMap().entries.map((entry) {
                        return _buildInstructionInput(entry.key, entry.value);
                      }),
                      const SizedBox(height: 8),
                      _buildAddButton(
                        label: 'Thêm bước',
                        onPressed: () => setState(() {
                          _instructions.add(_emptyInstruction());
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingSubmitButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        margin: const EdgeInsets.all(16),
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.04),
          //     blurRadius: 8,
          //     offset: const Offset(0, 2),
          //   ),
          // ],
        ),
        child: _resolveImagePreview() != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _resolveImagePreview(),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(135, 0, 0, 0),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit,
                              size: 16, color: AppTheme.primaryOrange),
                          SizedBox(width: 6),
                          Text(
                            'Thay đổi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  radius: const Radius.circular(16),
                  dashPattern: const [6, 3],
                  strokeWidth: 1.2,
                  color: AppTheme.primaryOrange,
                  // padding của nét viền vào child
                  padding: const EdgeInsets.all(1),
                ),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.04),
                    //     blurRadius: 8,
                    //     offset: const Offset(0, 2),
                    //   ),
                    // ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
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
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tối đa 12 MB',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCardSection({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryOrange),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required String hint,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    final difficulties = [
      {'value': 'easy', 'label': 'Dễ'},
      {'value': 'medium', 'label': 'Trung bình'},
      {'value': 'hard', 'label': 'Khó'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Độ khó',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        Row(
          children: difficulties.map((d) {
            final isSelected = _difficulty == d['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _difficulty = d['value'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryOrange.withOpacity(0.1)
                        : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    d['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'value': 'breakfast', 'label': 'Sáng'},
      {'value': 'lunch', 'label': 'Trưa'},
      {'value': 'dinner', 'label': 'Tối'},
      {'value': 'dessert', 'label': 'Tráng miệng'},
      {'value': 'snack', 'label': 'Ăn vặt'},
      {'value': 'beverage', 'label': 'Đồ uống'},
      {'value': 'other', 'label': 'Khác'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Danh mục',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: categories.map((c) {
            final isSelected = _category == c['value'];
            return GestureDetector(
              onTap: () => setState(() => _category = c['value'] as String),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryOrange.withOpacity(0.1)
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryOrange
                        : const Color(0xFFE5E7EB),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  c['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected ? AppTheme.primaryOrange : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPublicSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isPublic
            ? AppTheme.primaryOrange.withOpacity(0.05)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isPublic
              ? AppTheme.primaryOrange.withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _isPublic ? Icons.public : Icons.lock_outline,
                size: 18,
                color: _isPublic ? AppTheme.primaryOrange : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Công khai công thức',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  Text(
                    _isPublic ? 'Mọi người có thể xem' : 'Chỉ bạn có thể xem',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            activeColor: AppTheme.primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildTagInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${_tagList.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Input field to add new tag
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagInputController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Thêm tag (VD: món Việt, món chay...)',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  prefixIcon: Icon(Icons.label_outline, size: 18, color: Colors.grey[400]),
                ),
                onSubmitted: (value) {
                  _addTag(value);
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: () {
                  _addTag(_tagInputController.text);
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
        
        // Display tags as chips
        if (_tagList.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagList.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.label,
                      size: 14,
                      color: AppTheme.primaryOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _tagList.remove(tag);
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _addTag(String value) {
    final tag = value.trim();
    if (tag.isEmpty) return;
    if (_tagList.contains(tag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tag này đã tồn tại')),
      );
      return;
    }
    setState(() {
      _tagList.add(tag);
      _tagInputController.clear();
    });
  }

  Widget _buildIngredientInput(int index, Map<String, String> ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với số thứ tự và nút xóa
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nguyên liệu ${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (_ingredients.length > 1)
                InkWell(
                  onTap: () => setState(() => _ingredients.removeAt(index)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red[400],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Tên nguyên liệu
          TextField(
            controller: TextEditingController(text: ingredient['name'])
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: ingredient['name']?.length ?? 0),
              ),
            onChanged: (v) => _ingredients[index]['name'] = v,
            decoration: InputDecoration(
              hintText: 'Nhập tên nguyên liệu',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryOrange,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                Icons.restaurant,
                size: 20,
                color: Colors.grey[400],
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Số lượng và đơn vị
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: TextEditingController(
                      text: ingredient['quantity'])
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: ingredient['quantity']?.length ?? 0),
                    ),
                  onChanged: (v) => _ingredients[index]['quantity'] = v,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Số lượng',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryOrange,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAFA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryOrange,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionInput(int index, Map<String, dynamic> instruction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với số thứ tự và nút xóa
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Bước ${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (_instructions.length > 1)
                InkWell(
                  onTap: () => setState(() => _instructions.removeAt(index)),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red[400],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Mô tả bước
          TextField(
            controller: TextEditingController(text: instruction['description'])
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: instruction['description']?.length ?? 0),
              ),
            onChanged: (v) => _instructions[index]['description'] = v,
            maxLines: null,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập mô tả chi tiết cho bước này...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryOrange,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12, top: 14),
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildInstructionImagePicker(index, instruction),
        ],
      ),
    );
  }

  Future<void> _pickInstructionImage(int index) async {
    if (index < 0 || index >= _instructions.length) return;
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
      _instructions[index]['imageDataUri'] = 'data:$mime;base64,$b64';
      _instructions[index]['removeImage'] = false;
    });
  }

  void _removeInstructionImage(int index) {
    if (index < 0 || index >= _instructions.length) return;
    final currentUrl =
        ((_instructions[index]['imageUrl'] ?? '') as String).trim();
    final currentData =
        ((_instructions[index]['imageDataUri'] ?? '') as String).trim();
    final hadExisting = currentUrl.isNotEmpty && currentData.isEmpty;
    setState(() {
      _instructions[index]['imageDataUri'] = '';
      if (hadExisting) {
        _instructions[index]['imageUrl'] = '';
        _instructions[index]['imagePublicId'] = '';
      }
      _instructions[index]['removeImage'] = hadExisting;
    });
  }

  Widget? _resolveInstructionImagePreview(Map<String, dynamic> instruction) {
    final dataUri = ((instruction['imageDataUri'] ?? '') as String).trim();
    if (dataUri.isNotEmpty) {
      return _buildDataImage(dataUri);
    }
    final imageUrl = ((instruction['imageUrl'] ?? '') as String).trim();
    if (imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('data:image')) {
      return _buildDataImage(imageUrl);
    }
    return _buildNetworkImage(imageUrl);
  }

  Widget _buildInstructionImagePicker(
      int index, Map<String, dynamic> instruction) {
    final preview = _resolveInstructionImagePreview(instruction);
    final hasImage = preview != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.photo_outlined,
                size: 18,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ảnh minh họa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                // Nút thêm hoặc thay ảnh
                IconButton(
                  onPressed: () => _pickInstructionImage(index),
                  icon: Icon(
                    hasImage
                        ? Icons
                            .refresh_rounded // đổi thành icon refresh cho dễ hiểu
                        : Icons.add_photo_alternate_outlined,
                    size: 22,
                    color: AppTheme.primaryOrange,
                  ),
                  tooltip: hasImage
                      ? 'Thay ảnh'
                      : 'Thêm ảnh', // ✅ tooltip thân thiện
                ),

                // Nút xóa (chỉ hiển thị khi có ảnh)
                if (hasImage)
                  IconButton(
                    onPressed: () => _removeInstructionImage(index),
                    icon: const Icon(
                      Icons.close_outlined,
                      size: 22,
                      color: AppTheme.errorRed,
                    ),
                    tooltip:
                        'Xóa ảnh', // ✅ tooltip giúp người dùng hiểu rõ chức năng
                  ),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickInstructionImage(index),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: SizedBox.expand(child: preview),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 36,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhấn để thêm ảnh cho bước',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryOrange.withOpacity(0.05),
          border: Border.all(color: AppTheme.primaryOrange, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline,
                color: AppTheme.primaryOrange, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSubmitButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _busy ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
                  Text(
                    widget.recipeId == null ? 'Tạo công thức' : 'Lưu thay đổi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
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
          child:
              const Icon(Icons.broken_image_outlined, color: AppTheme.errorRed),
        );
      },
    );
  }
}
