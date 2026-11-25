import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef _ArtworkPrint = ({ui.Picture picture, Size size});

Future<_ArtworkPrint> _printArtwork(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    targetWidth: 80,
  );
  try {
    final sample = (await codec.getNextFrame()).image;
    try {
      final pixels = (await sample.toByteData())!;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final ink = Paint();
      final width = sample.width.toDouble();
      final height = sample.height.toDouble();
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width, height),
        Paint()..color = const Color(0xff151412),
      );
      for (var y = 0; y < sample.height; y++) {
        for (var x = 0; x < sample.width; x++) {
          final i = (y * sample.width + x) * 4;
          final red = pixels.getUint8(i);
          final green = pixels.getUint8(i + 1);
          final blue = pixels.getUint8(i + 2);
          final luminance = (red * .21 + green * .72 + blue * .07) / 255;
          ink.color = Color.lerp(
            Color.fromARGB(255, red, green, blue),
            const Color(0xfff1dfbc),
            .30,
          )!;
          canvas.drawCircle(Offset(x + .5, y + .5), .14 + .41 * luminance, ink);
        }
      }
      return (picture: recorder.endRecording(), size: Size(width, height));
    } finally {
      sample.dispose();
    }
  } finally {
    codec.dispose();
  }
}

class HalftoneArt extends StatefulWidget {
  const HalftoneArt({required this.asset, required this.original, super.key});

  final String asset;
  final Widget original;

  @override
  State<HalftoneArt> createState() => _HalftoneArtState();
}

class _HalftoneArtState extends State<HalftoneArt> {
  final _spot = ValueNotifier(const Offset(.5, .5));
  final _focus = FocusNode();
  late final Future<_ArtworkPrint> _print;
  ui.Picture? _picture;
  bool _requestedFocus = false;

  @override
  void initState() {
    super.initState();
    _print = _printArtwork(widget.asset).then((result) {
      if (mounted) {
        _picture = result.picture;
      } else {
        result.picture.dispose();
      }
      return result;
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _spot.dispose();
    _picture?.dispose();
    super.dispose();
  }

  void _move(Offset next) =>
      _spot.value = Offset(next.dx.clamp(0.0, 1.0), next.dy.clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _print,
    builder: (context, snapshot) {
      final picture = snapshot.data;
      if (picture == null) return widget.original;
      if (!_requestedFocus) {
        _requestedFocus = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus.requestFocus();
        });
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          void point(Offset position) => _move(
            Offset(position.dx / size.width, position.dy / size.height),
          );
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
                  _move(_spot.value - const Offset(.08, 0)),
              const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
                  _move(_spot.value + const Offset(.08, 0)),
              const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                  _move(_spot.value - const Offset(0, .08)),
              const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                  _move(_spot.value + const Offset(0, .08)),
            },
            child: Focus(
              focusNode: _focus,
              child: Semantics(
                label: 'Explorar la trama con las teclas de flecha',
                child: MouseRegion(
                  cursor: SystemMouseCursors.precise,
                  onHover: (event) => point(event.localPosition),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      _focus.requestFocus();
                      point(details.localPosition);
                    },
                    onPanStart: (details) => point(details.localPosition),
                    onPanUpdate: (details) => point(details.localPosition),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        foregroundPainter: _InkReveal(picture, _spot),
                        child: SizedBox.expand(child: widget.original),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _InkReveal extends CustomPainter {
  _InkReveal(this.print, this.spot) : super(repaint: spot);

  final _ArtworkPrint print;
  final ValueNotifier<Offset> spot;

  @override
  void paint(Canvas canvas, Size size) {
    final fit = applyBoxFit(BoxFit.contain, print.size, size);
    final bounds = Alignment.center.inscribe(
      fit.destination,
      Offset.zero & size,
    );
    final center = Offset(
      spot.value.dx * size.width,
      spot.value.dy * size.height,
    );
    final radius = math.min(size.shortestSide * .30, 135.0);
    canvas.saveLayer(bounds, Paint());
    canvas.save();
    canvas.clipRect(bounds);
    canvas.translate(bounds.left, bounds.top);
    canvas.scale(
      bounds.width / print.size.width,
      bounds.height / print.size.height,
    );
    canvas.drawPicture(print.picture);
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [Colors.black, Colors.black, Colors.transparent],
          [0, .63, 1],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InkReveal oldDelegate) => oldDelegate.print != print;
}
