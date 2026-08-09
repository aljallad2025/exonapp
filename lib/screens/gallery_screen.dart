import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';
import '../widgets/empty_state.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final data = await _client
          .from('gallery_images')
          .select('id, title, description, image_url, album, created_at')
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() {
          _images = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openImage(Map<String, dynamic> img) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: img['image_url'] ?? '',
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 60),
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            if ((img['title'] as String?)?.isNotEmpty == true)
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Text(
                    img['title'],
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تجميع الصور حسب الألبوم (لو موجود)
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final img in _images) {
      final album = (img['album'] as String?)?.trim();
      final key = (album == null || album.isEmpty) ? 'صور عامة' : album;
      grouped.putIfAbsent(key, () => []).add(img);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المعرض')),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _images.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 80),
                    EmptyState(
                        icon: Icons.photo_library_outlined,
                        message: 'لا توجد صور حاليًا')
                  ])
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: grouped.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: entry.value.length,
                              itemBuilder: (context, i) {
                                final img = entry.value[i];
                                return GestureDetector(
                                  onTap: () => _openImage(img),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: img['image_url'] ?? '',
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                          color: AppColors.border),
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.border,
                                        child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
