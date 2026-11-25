import 'package:flutter/material.dart';

import 'artwork_view.dart';
import 'museum_api.dart';
import 'print_archive.dart';

const nightLime = Color(0xffdcff13);
const nightCoral = Color(0xffff665e);

class NightArtCard extends StatelessWidget {
  const NightArtCard(
    this.art, {
    required this.saved,
    required this.onSave,
    required this.onOpen,
    this.featured = false,
    super.key,
  });

  final Artwork art;
  final bool featured, saved;
  final VoidCallback onSave, onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xff171717),
    borderRadius: BorderRadius.circular(featured ? 22 : 15),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ArtworkImage(art),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.3, 1],
              colors: [Colors.transparent, Color(0xff080808)],
            ),
          ),
        ),
        InkWell(
          onTap: onOpen,
          child: Padding(
            padding: EdgeInsets.all(featured ? 17 : 11),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (featured)
                  Text(
                    '${art.artist} · ${art.period}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: nightCoral,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        art.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Anton',
                          fontSize: featured ? 32 : 17,
                          height: 1.08,
                        ),
                      ),
                    ),
                    if (featured) ...[
                      const SizedBox(width: 8),
                      const CircleAvatar(
                        backgroundColor: nightLime,
                        foregroundColor: Colors.black,
                        child: Icon(Icons.arrow_forward),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: IconButton(
            tooltip: saved ? 'Quitar de guardados' : 'Guardar obra',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xdd131313),
            ),
            onPressed: onSave,
            icon: saved
                ? const PrintStamp(moving: true, size: 30)
                : const Icon(Icons.bookmark_border, color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
