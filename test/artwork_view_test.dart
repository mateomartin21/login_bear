import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_bear/museum/artwork_view.dart';
import 'package:login_bear/museum/halftone_art.dart';
import 'package:login_bear/museum/museum_api.dart';

void main() {
  testWidgets('Un recorrido habilita el boleto tras visitar todas las obras', (
    tester,
  ) async {
    final works = [
      for (final title in ['La gran ola', 'William'])
        Artwork({
          'id': title.length,
          'title': title,
          'artist': 'The Met',
          'period': 'Colección',
          'imageUrl': 'assets/met-45434.jpg',
        }),
    ];
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ArtworkView(works: works, start: 0, onTicket: () => saved = true),
      ),
    );
    expect(find.text('Recoger boleto'), findsNothing);
    await tester.tap(find.text('Paradas · 1 de 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('William').last);
    await tester.pumpAndSettle();
    expect(find.text('Paradas · 2 de 2'), findsOneWidget);
    await tester.tap(find.text('Recoger boleto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desprender boleto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar boleto'));
    await tester.pumpAndSettle();
    expect(saved, isTrue);
  });

  testWidgets('Trama is optional and Original restores the zoom viewer', (
    tester,
  ) async {
    final art = Artwork({
      'id': 45434,
      'title': 'La gran ola',
      'artist': 'Hokusai',
      'period': 'c. 1830',
      'imageUrl': 'assets/met-45434.jpg',
    });
    await tester.pumpWidget(
      MaterialApp(home: ArtworkView(works: [art], start: 0)),
    );
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.text('Trama'));
    await tester.pump();
    expect(find.byType(HalftoneArt), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
    await tester.tap(find.text('Original'));
    await tester.pump();
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });
}
