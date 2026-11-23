import 'package:flutter/material.dart';

import 'artwork_view.dart';
import 'collection_view.dart';
import 'exhibition_editor.dart';
import 'museum_api.dart';
import 'night_art_card.dart';

class Gallery extends StatefulWidget {
  const Gallery({this.onExit, super.key});

  final Future<void> Function()? onExit;

  @override
  State<Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {
  final _api = MuseumApi();
  late var _collection = _api.artworks();
  late var _exhibitions = _api.exhibitions();
  final _saved = <int>{};
  int _tab = 0;
  bool _search = false;

  void _toggleSaved(int id) => setState(() {
    if (!_saved.remove(id)) _saved.add(id);
  });

  void _visit(List<Artwork> works, int start) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ArtworkView(works: works, start: start),
    ),
  );

  Future<void> _edit(List<Artwork> works, [Exhibition? exhibition]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExhibitionEditor(_api, works, exhibition),
      ),
    );
    if (mounted && changed == true) {
      setState(() => _exhibitions = _api.exhibitions());
    }
  }

  Widget _retry(VoidCallback retry, String label) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        TextButton(onPressed: retry, child: const Text('Reintentar')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _collection,
    builder: (context, snapshot) {
      final works = snapshot.data;
      return Scaffold(
        appBar: AppBar(
          title: const Text.rich(
            TextSpan(
              text: 'NOCTURNA ',
              children: [
                TextSpan(
                  text: '//',
                  style: TextStyle(color: nightCoral),
                ),
              ],
            ),
            style: TextStyle(fontFamily: 'Anton', fontSize: 27),
          ),
          actions: [
            IconButton.filled(
              tooltip: _search ? 'Cerrar búsqueda' : 'Buscar obras',
              style: IconButton.styleFrom(
                backgroundColor: nightLime,
                foregroundColor: Colors.black,
              ),
              icon: Icon(_search ? Icons.close : Icons.search),
              onPressed: () => setState(() {
                _tab = 0;
                _search = !_search;
              }),
            ),
            if (widget.onExit != null)
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: widget.onExit,
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          indicatorColor: nightLime,
          onDestinationSelected: (tab) => setState(() {
            _tab = tab;
            _search = false;
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_outlined),
              label: 'Álbumes',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              label: 'Guardados',
            ),
          ],
        ),
        body: snapshot.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : works == null || works.isEmpty
            ? _retry(
                () => setState(() => _collection = _api.artworks()),
                'La colección no está disponible.',
              )
            : IndexedStack(
                index: _tab,
                children: [
                  CollectionView(
                    works,
                    onVisit: _visit,
                    saved: _saved,
                    onSave: _toggleSaved,
                    search: _search,
                  ),
                  _rooms(works),
                  _savedWorks(
                    works.where((art) => _saved.contains(art.id)).toList(),
                  ),
                ],
              ),
      );
    },
  );

  Widget _savedWorks(List<Artwork> works) => works.isEmpty
      ? const Center(
          child: Text('Guarda una obra para volver a ella durante la visita.'),
        )
      : GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 290,
            mainAxisExtent: 220,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: works.length,
          itemBuilder: (_, index) => NightArtCard(
            works[index],
            saved: true,
            onOpen: () => _visit(works, index),
            onSave: () => _toggleSaved(works[index].id),
          ),
        );

  Widget _rooms(List<Artwork> works) => FutureBuilder(
    future: _exhibitions,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final rooms = snapshot.data;
      if (rooms == null) {
        return _retry(
          () => setState(() => _exhibitions = _api.exhibitions()),
          'No se pudieron cargar las exposiciones.',
        );
      }
      final byId = {for (final art in works) art.id: art};
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FilledButton.icon(
            onPressed: () => _edit(works),
            icon: const Icon(Icons.add),
            label: const Text('Nueva exposición'),
          ),
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Elige obras de la colección para crear tu primera sala.',
              ),
            ),
          for (final room in rooms)
            ListTile(
              title: Text(room.title),
              subtitle: Text('${room.artworkIds.length} obras'),
              onTap: () {
                final selection = room.artworkIds
                    .map((id) => byId[id])
                    .whereType<Artwork>()
                    .toList();
                if (selection.isNotEmpty) _visit(selection, 0);
              },
              trailing: IconButton(
                tooltip: 'Editar exposición',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(works, room),
              ),
            ),
        ],
      );
    },
  );
}
