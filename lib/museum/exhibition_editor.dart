import 'package:flutter/material.dart';

import 'museum_api.dart';
import 'artwork_view.dart';
import 'print_archive.dart';

class ExhibitionEditor extends StatefulWidget {
  const ExhibitionEditor(this.api, this.works, this.exhibition, {super.key});

  final MuseumApi api;
  final List<Artwork> works;
  final Exhibition? exhibition;

  @override
  State<ExhibitionEditor> createState() => _ExhibitionEditorState();
}

class _ExhibitionEditorState extends State<ExhibitionEditor> {
  late final _title = TextEditingController(text: widget.exhibition?.title);
  late final _selected = [...?widget.exhibition?.artworkIds];
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit({bool delete = false}) async {
    final title = _title.text.trim();
    if (!delete && (title.isEmpty || _selected.isEmpty)) {
      _message('Escribe un título y elige al menos una obra.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (delete) {
        await widget.api.delete(widget.exhibition!.id);
      } else {
        await widget.api.save(widget.exhibition?.id, title, List.of(_selected));
      }
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).pop(true);
    } on Exception {
      if (!mounted) return;
      setState(() => _busy = false);
      _message('No se pudo completar el cambio. Intenta de nuevo.');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar álbum?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) await _submit(delete: true);
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final art in widget.works) art.id: art};
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.exhibition == null
                ? 'Nuevo álbum'
                : 'Editar álbum',
          ),
          actions: [
            if (widget.exhibition != null)
              IconButton(
                tooltip: 'Borrar álbum',
                onPressed: _busy ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _title,
              enabled: !_busy,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Título del álbum'),
            ),
            const SizedBox(height: 12),
            if (_selected.isNotEmpty) ...[
              const Text('Orden del recorrido'),
              for (final (index, id) in _selected.indexed)
                ListTile(
                  title: Text(byId[id]?.title ?? 'Obra #$id'),
                  leading: Text('${index + 1}'),
                  trailing: IconButton(
                    tooltip: 'Subir obra',
                    onPressed: _busy || index == 0
                        ? null
                        : () => setState(
                            () => _selected.insert(
                              index - 1,
                              _selected.removeAt(index),
                            ),
                          ),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ),
            ],
            ArchiveHeading('Seleccionar obras', count: widget.works.length),
            for (final art in widget.works)
              CheckboxListTile(
                secondary: SizedBox(
                  width: 48,
                  height: 48,
                  child: ArtworkImage(art),
                ),
                value: _selected.contains(art.id),
                title: Text(art.title),
                onChanged: _busy
                    ? null
                    : (checked) => setState(() {
                        if (checked == true) {
                          _selected.add(art.id);
                        } else {
                          _selected.remove(art.id);
                        }
                      }),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(20),
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Procesando…' : 'Guardar álbum'),
          ),
        ),
      ),
    );
  }
}
