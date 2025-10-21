import 'package:flutter/material.dart';
import '../../model/collection.dart';
import '../../services/recipe_api_service.dart';
import '../../theme/app_theme.dart';

class CreateCollectionScreen extends StatefulWidget {
  const CreateCollectionScreen({super.key, this.collection});

  final Collection? collection;

  @override
  State<CreateCollectionScreen> createState() => _CreateCollectionScreenState();
}

class _CreateCollectionScreenState extends State<CreateCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = false;
  bool _isSaving = false;

  bool get _isEditMode => widget.collection != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.collection!.name;
      _descriptionController.text = widget.collection!.description;
      _isPublic = widget.collection!.isPublic;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      Collection result;
      if (_isEditMode) {
        result = await RecipeApiService.updateCollection(
          widget.collection!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isPublic: _isPublic,
        );
      } else {
        result = await RecipeApiService.createCollection(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          isPublic: _isPublic,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode ? 'Đã cập nhật bộ sưu tập' : 'Đã tạo bộ sưu tập',
          ),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Chỉnh sửa bộ sưu tập' : 'Tạo bộ sưu tập mới'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                _isEditMode ? 'Lưu' : 'Tạo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name Field
            const Text(
              'Tên bộ sưu tập',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditMode,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Món ăn sáng yêu thích',
                hintStyle: TextStyle(
                  color: AppTheme.textLight.withOpacity(0.6),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: AppTheme.lightCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryOrange,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.errorRed,
                    width: 1,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên bộ sưu tập';
                }
                if (value.trim().length < 3) {
                  return 'Tên phải có ít nhất 3 ký tự';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Description Field
            const Text(
              'Mô tả (tùy chọn)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Thêm mô tả ngắn về bộ sưu tập này...',
                hintStyle: TextStyle(
                  color: AppTheme.textLight.withOpacity(0.6),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: AppTheme.lightCream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryOrange,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Toggle
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lightCream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                value: _isPublic,
                onChanged: (value) {
                  setState(() => _isPublic = value);
                },
                title: const Text(
                  'Công khai',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                subtitle: Text(
                  _isPublic
                      ? 'Mọi người có thể xem'
                      : 'Chỉ bạn có thể xem',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight,
                  ),
                ),
                secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock_outline,
                  color: _isPublic ? AppTheme.primaryOrange : AppTheme.textLight,
                ),
                activeColor: AppTheme.primaryOrange,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Help Text
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.textLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bạn có thể thêm công thức vào bộ sưu tập sau khi tạo',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}