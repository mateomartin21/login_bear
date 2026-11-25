import 'package:flutter/material.dart';

import 'artwork_view.dart';
import 'museum_api.dart';

class CuratedRoutes extends StatelessWidget {
  const CuratedRoutes(this.works, {required this.onTicket, super.key});

  final List<Artwork> works;
  final ValueChanged<String> onTicket;

  static const _routes = [
    (
      title: 'Lo que esconde el azul',
      description: 'Olas, flores y un hipopótamo del antiguo Egipto.',
      ids: [45434, 544227, 436528],
    ),
    (
      title: 'Luces después del anochecer',
      description: 'Del resplandor del circo a las sombras de Rembrandt.',
      ids: [437654, 437394],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final catalog = {for (final work in works) work.id: work};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recorridos guiados',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (final route in _routes)
          if (route.ids.every(catalog.containsKey))
            _RouteCard(
              title: route.title,
              description: route.description,
              cover: catalog[route.ids.first]!,
              onOpen: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => _RouteIntro(
                    title: route.title,
                    description: route.description,
                    works: [for (final id in route.ids) catalog[id]!],
                    onTicket: () => onTicket(route.title),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _RouteCard extends StatefulWidget {
  const _RouteCard({
    required this.title,
    required this.description,
    required this.cover,
    required this.onOpen,
  });

  final String title, description;
  final Artwork cover;
  final VoidCallback onOpen;

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _focused = false;
  bool _pressed = false;
  Alignment? _light;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => MouseRegion(
      onHover: (event) => setState(() {
        _light = Alignment(event.localPosition.dx / size.maxWidth * 2 - 1, 0);
      }),
      onExit: (_) => setState(() => _light = null),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: _light ?? Alignment.centerLeft,
              radius: .95,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(
                  alpha: _focused || _pressed || _light != null ? .21 : .05,
                ),
                Colors.transparent,
              ],
            ),
          ),
          child: InkWell(
            onTap: widget.onOpen,
            onFocusChange: (value) => setState(() => _focused = value),
            onHighlightChanged: (value) => setState(() => _pressed = value),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox.square(
                  dimension: 50,
                  child: ExcludeSemantics(
                    child: ArtworkImage(widget.cover, localOnly: true),
                  ),
                ),
              ),
              title: Text(widget.title),
              subtitle: Text(widget.description),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RouteIntro extends StatefulWidget {
  const _RouteIntro({
    required this.title,
    required this.description,
    required this.works,
    required this.onTicket,
  });

  final String title, description;
  final List<Artwork> works;
  final VoidCallback onTicket;

  @override
  State<_RouteIntro> createState() => _RouteIntroState();
}

class _RouteIntroState extends State<_RouteIntro> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recorrido guiado')),
    body: ListView(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        AnimatedBuilder(
          animation: _scroll,
          child: ArtworkImage(widget.works.first, localOnly: true),
          builder: (context, child) {
            final progress =
                MediaQuery.disableAnimationsOf(context) || !_scroll.hasClients
                ? 0.0
                : (_scroll.offset / 72).clamp(0.0, 1.0);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * (1 - progress)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20 * (1 - progress)),
                child: SizedBox(
                  height: (MediaQuery.sizeOf(context).height * .62).clamp(
                    290.0,
                    620.0,
                  ),
                  child: child,
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(widget.description),
            ],
          ),
        ),
        for (final (index, work) in widget.works.indexed)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            leading: Text('${index + 1}'),
            title: Text(work.title),
            subtitle: Text(work.artist),
          ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: FilledButton.icon(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Iniciar recorrido'),
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ArtworkView(
              works: widget.works,
              start: 0,
              onTicket: widget.onTicket,
            ),
          ),
        ),
      ),
    ),
  );
}
