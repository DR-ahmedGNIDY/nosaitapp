import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/utils/image_size_validator.dart';
import 'package:basketball_academy/features/academy_album/data/album_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// نتيجة نموذج الألبوم: عند الإضافة يحمل مسار الملف؛ عند التعديل لا يحمله.
class AlbumFormResult {
  final String? imagePath; // null عند التعديل
  final bool isVideo;
  final String title;
  final String description;
  const AlbumFormResult({
    this.imagePath,
    this.isVideo = false,
    required this.title,
    required this.description,
  });
}

/// نموذج موحّد: إضافة صورة/فيديو (اختيار من المعرض + عنوان + وصف) أو تعديل
/// (عنوان + وصف فقط). يعيد AlbumFormResult أو null عند الإلغاء.
class AlbumFormDialog extends StatefulWidget {
  final AlbumImage? existing; // null = إضافة
  const AlbumFormDialog({super.key, this.existing});

  @override
  State<AlbumFormDialog> createState() => _AlbumFormDialogState();
}

class _AlbumFormDialogState extends State<AlbumFormDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  XFile? _picked;
  bool _pickedIsVideo = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _titleCtrl.text = widget.existing!.title;
      _descCtrl.text = widget.existing!.description;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    final sizeError = await validateImageSize(img);
    if (sizeError != null) {
      setState(() => _error = sizeError);
      return;
    }
    setState(() {
      _picked = img;
      _pickedIsVideo = false;
      _error = null;
    });
  }

  Future<void> _pickVideo() async {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    final sizeError = await validateAlbumVideoSize(video);
    if (sizeError != null) {
      setState(() => _error = sizeError);
      return;
    }
    setState(() {
      _picked = video;
      _pickedIsVideo = true;
      _error = null;
    });
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'العنوان مطلوب');
      return;
    }
    if (!_isEdit && _picked == null) {
      setState(() => _error = 'اختر صورة أو فيديو أولاً');
      return;
    }
    Navigator.pop(
      context,
      AlbumFormResult(
        imagePath: _picked?.path,
        isVideo: _pickedIsVideo,
        title: title,
        description: _descCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل الصورة' : 'إضافة صورة أو فيديو'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isEdit) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _picked != null && !_pickedIsVideo ? 'تم اختيار الصورة' : 'صورة',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam_outlined),
                      label: Text(
                        _picked != null && _pickedIsVideo ? 'تم اختيار الفيديو' : 'فيديو',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _titleCtrl,
              maxLength: 150,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            TextField(
              controller: _descCtrl,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'الوصف (اختياري)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }
}
