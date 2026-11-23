import 'package:flutter/material.dart';

import 'museum_api.dart';

class ArtworkImage extends StatelessWidget {
  const ArtworkImage(this.art, {this.fit = BoxFit.cover, super.key});

  final Artwork art;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.network(
    art.imageUrl,
    fit: fit,
    semanticLabel: art.title,
    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: Color(0xff30281e),
      child: Center(child: Icon(Icons.image_not_supported_outlined)),
    ),
  );
}

class ArtworkView extends StatefulWidget {
  const ArtworkView({required this.works, required this.start, super.key});

  final List<Artwork> works;
  final int start;

  @override
  State<ArtworkView> createState() => _ArtworkViewState();
}

class _ArtworkViewState extends State<ArtworkView> {
  late int _index = widget.start;
  late final _pages = PageController(initialPage: widget.start);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${_index + 1} / ${widget.works.length}')),
    body: SafeArea(
      child: PageView.builder(
        controller: _pages,
        itemCount: widget.works.length,
        onPageChanged: (index) => setState(() => _index = index),
        itemBuilder: (context, index) {
          final art = widget.works[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.65, end: 1),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 420),
                        builder: (_, opacity, child) =>
                            Opacity(opacity: opacity, child: child),
                        child: ArtworkImage(art, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  art.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Georgia', fontSize: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  '${art.artist} · ${art.period}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'The Metropolitan Museum of Art · Open Access',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
