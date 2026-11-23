import 'package:flutter/material.dart';

import 'museum_api.dart';
import 'night_art_card.dart';

class CollectionView extends StatefulWidget {
  const CollectionView(
    this.works, {
    required this.onVisit,
    required this.saved,
    required this.onSave,
    required this.search,
    super.key,
  });

  final List<Artwork> works;
  final Set<int> saved;
  final ValueChanged<int> onSave;
  final void Function(List<Artwork>, int) onVisit;
  final bool search;

  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {
  static const _filters = ['Para ti', 'Van Gogh', 'Otros artistas'];
  final _searchFocus = FocusNode();
  String _query = '';
  int _filter = 0;

  @override
  void didUpdateWidget(CollectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.search && !oldWidget.search) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.search) _searchFocus.requestFocus();
      });
    }
    if (!widget.search) _query = '';
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  List<Artwork> get _visible => widget.works.where((work) {
    final vanGogh = work.artist == 'Vincent van Gogh';
    return (_filter == 0 || (_filter == 1 ? vanGogh : !vanGogh)) &&
        '${work.title} ${work.artist} ${work.period}'.toLowerCase().contains(
          _query,
        );
  }).toList();

  @override
  Widget build(BuildContext context) {
    final works = _visible;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.search)
                      TextField(
                        autofocus: true,
                        focusNode: _searchFocus,
                        onChanged: (value) =>
                            setState(() => _query = value.trim().toLowerCase()),
                        decoration: const InputDecoration(
                          labelText: 'Busca por obra, artista o año',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      Semantics(
                        header: true,
                        child: Text(
                          'La noche\nno se detiene.',
                          style: TextStyle(
                            fontFamily: 'Anton',
                            fontSize: wide ? 84 : 54,
                            height: 1.02,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 18,
                      children: [
                        for (final (index, label) in _filters.indexed)
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: _filter == index
                                  ? nightLime
                                  : Colors.white70,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () => setState(() => _filter = index),
                            child: Semantics(
                              selected: _filter == index,
                              child: Container(
                                padding: const EdgeInsets.only(bottom: 5),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _filter == index
                                          ? nightLime
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (works.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('No encontramos obras con esos filtros.'),
                ),
              )
            else ...[
              if (!widget.search)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: wide ? 396 : 334,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: works.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, index) => SizedBox(
                        width: wide
                            ? 570
                            : (MediaQuery.sizeOf(context).width * .83)
                                  .clamp(220, 430)
                                  .toDouble(),
                        child: NightArtCard(
                          works[index],
                          featured: true,
                          saved: widget.saved.contains(works[index].id),
                          onSave: () => widget.onSave(works[index].id),
                          onOpen: () => widget.onVisit(works, index),
                        ),
                      ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text.rich(
                    TextSpan(
                      text: widget.search
                          ? 'Resultados'
                          : 'Tu siguiente desvelo  ',
                      children: const [
                        TextSpan(
                          text: '//',
                          style: TextStyle(color: nightCoral),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wide ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: wide ? 250 : 205,
                  ),
                  itemCount: works.length,
                  itemBuilder: (_, index) => NightArtCard(
                    works[index],
                    saved: widget.saved.contains(works[index].id),
                    onSave: () => widget.onSave(works[index].id),
                    onOpen: () => widget.onVisit(works, index),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
