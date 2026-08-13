import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/academy_album/data/academy_album_service.dart';
import 'package:basketball_academy/features/academy_album/data/album_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

/// عارض ملء الشاشة: تكبير/تشغيل فيديو + سحب بين الصور (PageView) +
/// مشاركة/حفظ + إعجاب/تعليق. مشترك بين المدير واللاعب.
class AlbumViewerScreen extends StatefulWidget {
  final List<AlbumImage> images;
  final int initialIndex;
  /// اللاعب يستخدم /player/album/... بدل /academy-album/...
  final bool playerSide;

  const AlbumViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    this.playerSide = false,
  });

  @override
  State<AlbumViewerScreen> createState() => _AlbumViewerScreenState();
}

class _AlbumViewerScreenState extends State<AlbumViewerScreen> {
  late final PageController _controller;
  late int _index;
  late List<AlbumImage> _items;
  bool _sharing = false;
  bool _liking = false;
  VideoPlayerController? _videoController;

  AcademyAlbumService get _service => sl<AcademyAlbumService>();

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _items = List.of(widget.images);
    _controller = PageController(initialPage: _index);
    _initVideoIfNeeded();
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  AlbumImage get _current => _items[_index];

  void _initVideoIfNeeded() {
    _videoController?.dispose();
    _videoController = null;
    final img = _current;
    if (!img.isVideo) return;
    final controller = VideoPlayerController.networkUrl(Uri.parse(img.imageUrl));
    _videoController = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      controller.play();
    });
  }

  void _onPageChanged(int i) {
    setState(() => _index = i);
    _initVideoIfNeeded();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final img = _current;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (kIsWeb) {
        // على الويب لا نظام ملفات محلي — نشارك الرابط.
        await Share.share(img.imageUrl, subject: img.title);
      } else {
        // نزّل الملف إلى مسار مؤقت ثم شاركه كملف (يتيح "حفظ" من ورقة المشاركة).
        final dir = await getTemporaryDirectory();
        final ext = img.isVideo ? 'mp4' : 'jpg';
        final path = '${dir.path}/album_${img.id}.$ext';
        await Dio().download(img.imageUrl, path);
        await Share.shareXFiles([XFile(path)], text: img.title);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذّرت المشاركة. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    setState(() => _liking = true);
    // تحديث متفائل فوري، ثم تصحيحه من رد الخادم.
    final before = _current;
    setState(() {
      _items[_index] = before.copyWith(
        isLiked: !before.isLiked,
        likesCount: before.isLiked ? before.likesCount - 1 : before.likesCount + 1,
      );
    });
    try {
      final updated = await _service.toggleLike(before.id, playerSide: widget.playerSide);
      if (mounted) setState(() => _items[_index] = updated);
    } catch (_) {
      if (mounted) setState(() => _items[_index] = before);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر تسجيل الإعجاب. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _openComments() async {
    final capturedIndex = _index;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        item: _current,
        service: _service,
        playerSide: widget.playerSide,
        onUpdated: (updated) {
          if (mounted) setState(() => _items[capturedIndex] = updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final img = _current;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${_items.length}'),
        actions: [
          IconButton(
            tooltip: 'مشاركة',
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, i) {
                final it = _items[i];
                if (it.isVideo) {
                  final vc = i == _index ? _videoController : null;
                  return Center(
                    child: vc != null && vc.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: vc.value.aspectRatio,
                            child: GestureDetector(
                              onTap: () => setState(
                                () => vc.value.isPlaying ? vc.pause() : vc.play(),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(vc),
                                  if (!vc.value.isPlaying)
                                    const Icon(Icons.play_circle_fill,
                                        color: Colors.white70, size: 64),
                                ],
                              ),
                            ),
                          )
                        : const CircularProgressIndicator(color: Colors.white),
                  );
                }
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: it.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.black,
            child: Row(
              children: [
                IconButton(
                  onPressed: _liking ? null : _toggleLike,
                  icon: Icon(
                    img.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: img.isLiked ? Colors.redAccent : Colors.white,
                  ),
                ),
                Text('${img.likesCount}', style: const TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _openComments,
                  icon: const Icon(Icons.mode_comment_outlined, color: Colors.white),
                ),
                Text('${img.commentsCount}', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          if (img.title.isNotEmpty || img.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (img.title.isNotEmpty)
                    Text(img.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  if (img.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(img.description,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ورقة سفلية لعرض التعليقات وإضافة تعليق جديد.
class _CommentsSheet extends StatefulWidget {
  final AlbumImage item;
  final AcademyAlbumService service;
  final bool playerSide;
  final void Function(AlbumImage updated) onUpdated;

  const _CommentsSheet({
    required this.item,
    required this.service,
    required this.playerSide,
    required this.onUpdated,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _textCtrl = TextEditingController();
  late AlbumImage _item;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final updated = await widget.service.addComment(_item.id, text, playerSide: widget.playerSide);
      setState(() {
        _item = updated;
        _textCtrl.clear();
      });
      widget.onUpdated(updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّرت إضافة التعليق. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(AlbumComment c) async {
    try {
      final updated =
          await widget.service.deleteComment(_item.id, c.id, playerSide: widget.playerSide);
      setState(() => _item = updated);
      widget.onUpdated(updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر حذف التعليق.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text('التعليقات (${_item.commentsCount})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Expanded(
                  child: _item.comments.isEmpty
                      ? const Center(child: Text('لا توجد تعليقات بعد'))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _item.comments.length,
                          itemBuilder: (_, i) {
                            final c = _item.comments[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(c.authorName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text(c.text),
                              trailing: c.isMine
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.error, size: 20),
                                      onPressed: () => _delete(c),
                                    )
                                  : (c.createdAt != null
                                      ? Text(
                                          intl.DateFormat('HH:mm').format(c.createdAt!),
                                          style: const TextStyle(
                                              color: AppColors.grey500, fontSize: 11),
                                        )
                                      : null),
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText: 'اكتب تعليقاً...',
                              counterText: '',
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
