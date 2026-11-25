import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_bear/museum/print_archive.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('El sello usa el archivo local y respeta movimiento reducido', (
    tester,
  ) async {
    final composition = await tester.runAsync(
      () => AssetLottie('assets/estampa.json').load(),
    );
    expect(composition?.layers, hasLength(2));
    for (final reduced in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const PrintStamp(moving: true),
          ),
        ),
      );
      expect(
        tester.widget<LottieBuilder>(find.byType(LottieBuilder)).animate,
        !reduced,
      );
    }
  });

  testWidgets('El archivo vacío permite volver a explorar', (tester) async {
    var explored = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyArchive(
            'Tu archivo de visita',
            'Guarda una obra.',
            onExplore: () => explored = true,
          ),
        ),
      ),
    );
    expect(
      tester.widget<LottieBuilder>(find.byType(LottieBuilder)).animate,
      false,
    );
    await tester.tap(find.text('Explorar obras'));
    expect(explored, true);
  });
}
