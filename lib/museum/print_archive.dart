import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PrintStamp extends StatelessWidget {
  const PrintStamp({this.moving = false, this.size = 80, super.key});
  final bool moving;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Lottie.asset(
      'assets/estampa.json',
      width: size,
      height: size,
      animate: moving && !MediaQuery.disableAnimationsOf(context),
      repeat: false,
    ),
  );
}

class ArchiveHeading extends StatelessWidget {
  const ArchiveHeading(this.title, {this.count, super.key});
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Anton',
                fontSize: 38,
                height: 1.18,
              ),
            ),
          ),
        ),
        if (count != null)
          Text(
            count.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Color(0xffff8981),
              fontFamily: 'Anton',
              fontSize: 25,
            ),
          ),
      ],
    ),
  );
}

class EmptyArchive extends StatelessWidget {
  const EmptyArchive(
    this.title,
    this.detail, {
    required this.onExplore,
    super.key,
  });
  final String title, detail;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PrintStamp(size: 110),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Anton', fontSize: 30),
          ),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onExplore,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Explorar obras'),
          ),
        ],
      ),
    ),
  );
}
