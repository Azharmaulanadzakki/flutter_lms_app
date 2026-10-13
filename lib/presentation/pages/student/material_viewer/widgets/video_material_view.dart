import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../../../core/utils/external_link.dart';
import '../../../../../core/utils/media_links.dart';
import '../../../../widgets/app_snackbar.dart';
import 'unavailable_material_view.dart';

class VideoMaterialView extends StatefulWidget {
  const VideoMaterialView({super.key, required this.url});

  final String url;

  @override
  State<VideoMaterialView> createState() => _VideoMaterialViewState();
}

class _VideoMaterialViewState extends State<VideoMaterialView> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final id = extractYoutubeId(widget.url);
    if (id != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: false),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (widget.url.trim().isEmpty) {
      return const UnavailableMaterialView(
        message: 'Video belum tersedia.',
      );
    }
    if (controller == null) {
      return UnavailableMaterialView(
        message: 'Link video tidak valid.',
        url: widget.url,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: YoutubePlayer(controller: controller, aspectRatio: 16 / 9),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await openExternalUrl(widget.url);
            if (!ok && context.mounted) {
              showAppSnackBar(context, 'Link tidak bisa dibuka.', isError: true);
            }
          },
          icon: const Icon(Icons.open_in_new),
          label: const Text('Buka di YouTube'),
        ),
      ],
    );
  }
}