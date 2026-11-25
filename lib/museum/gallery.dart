import 'package:flutter/material.dart';

import 'artwork_view.dart';
import 'collection_view.dart';
import 'exhibition_editor.dart';
import 'museum_api.dart';
import 'night_art_card.dart';
import 'print_archive.dart';

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
  final _tickets = <String>{};
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
                    onTicket: (title) => setState(() => _tickets.add(title)),
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

  Widget _savedWorks(List<Artwork> works) => works.isEmpty && _tickets.isEmpty
      ? EmptyArchive(
          'Tu archivo de visita',
          'Toca el marcador de una obra para conservarla durante esta visita.',
          onExplore: () => setState(() => _tab = 0),
        )
      : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: ArchiveHeading("Guardados", count: works.length),
            ),
            if (_tickets.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final ticket in _tickets)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          avatar: const Icon(
                            Icons.confirmation_number_outlined,
                          ),
                          label: Text(ticket),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: GridView.builder(
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
              ),
            ),
          ],
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
          'No se pudieron cargar los álbumes.',
        );
      }
      final byId = {for (final art in works) art.id: art};
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ArchiveHeading('Mis álbumes', count: rooms.length),
          FilledButton.icon(
            onPressed: () => _edit(works),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo álbum'),
          ),
          if (rooms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Elige obras de la colección para crear tu primer álbum.',
              ),
            ),
          for (final room in rooms)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading:
                  room.artworkIds.isNotEmpty &&
                      byId[room.artworkIds.first] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: ArtworkImage(byId[room.artworkIds.first]!),
                      ),
                    )
                  : const Icon(Icons.collections),
              title: Text(
                room.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${room.artworkIds.length} obras'),
              onTap: () {
                final selection = room.artworkIds
                    .map((id) => byId[id])
                    .whereType<Artwork>()
                    .toList();
                if (selection.isNotEmpty) _visit(selection, 0);
              },
              trailing: IconButton(
                tooltip: 'Editar álbum',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _edit(works, room),
              ),
            ),
        ],
      );
    },
  );
}
