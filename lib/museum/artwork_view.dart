import 'package:flutter/material.dart';

import 'halftone_art.dart';
import 'museum_api.dart';
import 'visit_ticket.dart';

enum _ArtworkMode { original, halftone }

class ArtworkImage extends StatelessWidget {
  const ArtworkImage(
    this.art, {
    this.fit = BoxFit.cover,
    this.localOnly = false,
    super.key,
  });

  final Artwork art;
  final BoxFit fit;
  final bool localOnly;

  @override
  Widget build(BuildContext context) {
    final asset = art.imageAsset;
    if (asset != null && (localOnly || art.imageUrl == asset)) {
      return _localImage(asset);
    }
    return Image.network(
      art.imageUrl,
      fit: fit,
      semanticLabel: art.title,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) =>
          asset == null ? _unavailable : _localImage(asset),
    );
  }

  Widget _localImage(String asset) => Image.asset(
    asset,
    fit: fit,
    semanticLabel: art.title,
    errorBuilder: (_, _, _) => _unavailable,
  );

  static const _unavailable = ColoredBox(
    color: Color(0xff30281e),
    child: Center(child: Icon(Icons.image_not_supported_outlined)),
  );
}

class ArtworkView extends StatefulWidget {
  const ArtworkView({
    required this.works,
    required this.start,
    this.onTicket,
    super.key,
  });

  final List<Artwork> works;
  final int start;
  final VoidCallback? onTicket;

  @override
  State<ArtworkView> createState() => _ArtworkViewState();
}

class _ArtworkViewState extends State<ArtworkView> {
  late int _index = widget.start;
  late final _pages = PageController(initialPage: widget.start);
  _ArtworkMode _mode = _ArtworkMode.original;
  late final _visited = <int>{widget.start};
  bool _ticketSaved = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ficha de obra'),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(widget.onTicket == null ? 2 : 50),
        child: Column(
          children: [
            if (widget.onTicket != null)
              TextButton.icon(
                onPressed: _showStops,
                icon: const Icon(Icons.route_outlined),
                label: Text(
                  'Paradas · ${_index + 1} de ${widget.works.length}',
                ),
              ),
            LinearProgressIndicator(
              value: (_index + 1) / widget.works.length,
              minHeight: 2,
              semanticsLabel: 'Progreso del recorrido',
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Obra anterior',
          onPressed: _index == 0 ? null : () => _step(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Obra siguiente',
          onPressed: _index == widget.works.length - 1 ? null : () => _step(1),
          icon: const Icon(Icons.chevron_right),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Text('${_index + 1} / ${widget.works.length}'),
        ),
      ],
    ),
    bottomNavigationBar:
        widget.onTicket != null && _visited.length == widget.works.length
        ? SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton.icon(
              onPressed: _ticketSaved ? null : _collectTicket,
              icon: const Icon(Icons.confirmation_number_outlined),
              label: Text(_ticketSaved ? 'Boleto guardado' : 'Recoger boleto'),
            ),
          )
        : null,
    body: SafeArea(
      child: PageView.builder(
        controller: _pages,
        itemCount: widget.works.length,
        physics: _mode == _ArtworkMode.halftone
            ? const NeverScrollableScrollPhysics()
            : null,
        onPageChanged: (index) => setState(() {
          _index = index;
          _visited.add(index);
          if (widget.works[index].imageAsset == null) {
            _mode = _ArtworkMode.original;
          }
        }),
        itemBuilder: (context, index) {
          final art = widget.works[index];
          final canReveal = art.imageAsset != null;
          final reveal =
              canReveal && index == _index && _mode == _ArtworkMode.halftone;
          final image = ArtworkImage(
            art,
            fit: BoxFit.contain,
            localOnly: reveal,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            children: [
              if (canReveal) ...[
                Center(
                  child: SegmentedButton<_ArtworkMode>(
                    segments: const [
                      ButtonSegment(
                        value: _ArtworkMode.original,
                        icon: Icon(Icons.image_outlined),
                        label: Text('Original'),
                      ),
                      ButtonSegment(
                        value: _ArtworkMode.halftone,
                        icon: Icon(Icons.blur_on),
                        label: Text('Trama'),
                      ),
                    ],
                    selected: {
                      reveal ? _ArtworkMode.halftone : _ArtworkMode.original,
                    },
                    onSelectionChanged: (selection) =>
                        setState(() => _mode = selection.single),
                  ),
                ),
                const SizedBox(height: 8),
                if (reveal)
                  const Text(
                    'Mueve el cursor o arrastra para revelar detalles. También puedes usar las flechas.',
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: (MediaQuery.sizeOf(context).height * .48).clamp(
                  210.0,
                  540.0,
                ),
                child: reveal
                    ? HalftoneArt(
                        key: ValueKey(art.id),
                        asset: art.imageAsset!,
                        original: image,
                      )
                    : InteractiveViewer(
                        maxScale: 4,
                        child: Center(child: image),
                      ),
              ),
              const Divider(color: Color(0xffff665e)),
              const SizedBox(height: 12),
              Text(
                art.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'Anton', fontSize: 26),
              ),
              const SizedBox(height: 8),
              Text(
                '${art.artist} · ${art.period}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (art.observation.isNotEmpty)
                ExpansionTile(
                  key: PageStorageKey(art.id),
                  leading: const Icon(Icons.visibility_outlined),
                  title: const Text('Mira de cerca'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [Text(art.observation)],
                ),
              const Text('The Met · Open Access', textAlign: TextAlign.center),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _showStops() async {
    final stop = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          for (final (index, art) in widget.works.indexed)
            ListTile(
              selected: index == _index,
              leading: CircleAvatar(child: Text('${index + 1}')),
              trailing: _visited.contains(index)
                  ? const Icon(Icons.check)
                  : null,
              title: Text(art.title),
              onTap: () => Navigator.pop(context, index),
            ),
        ],
      ),
    );
    if (mounted && stop != null) _pages.jumpToPage(stop);
  }

  Future<void> _collectTicket() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => const VisitTicket(),
    );
    if (!mounted || saved != true) return;
    widget.onTicket?.call();
    setState(() => _ticketSaved = true);
  }

  void _step(int offset) {
    final page = _index + offset;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  }
}
