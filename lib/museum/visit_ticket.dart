import 'package:flutter/material.dart';

class VisitTicket extends StatefulWidget {
  const VisitTicket({super.key});

  @override
  State<VisitTicket> createState() => _VisitTicketState();
}

class _VisitTicketState extends State<VisitTicket> {
  double _drag = 0;
  bool _torn = false;

  void _tear() {
    if (_torn) return;
    setState(() => _torn = true);
  }

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recorrido completo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: const Color(0xffe9ddbe),
              child: SizedBox(
                height: 76,
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'NOCTURNA',
                          style: TextStyle(
                            fontFamily: 'Anton',
                            color: Color(0xff23231d),
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onHorizontalDragUpdate: _torn
                          ? null
                          : (details) => setState(() {
                              _drag = (_drag + details.delta.dx).clamp(
                                0.0,
                                100.0,
                              );
                            }),
                      onHorizontalDragEnd: _torn
                          ? null
                          : (_) {
                              if (_drag >= 38) _tear();
                              setState(() => _drag = 0);
                            },
                      onHorizontalDragCancel: () => setState(() => _drag = 0),
                      child: AnimatedSlide(
                        duration: _drag > 0 && !_torn ? Duration.zero : motion,
                        offset: Offset(_torn ? 1.1 : _drag / 84, 0),
                        child: ExcludeSemantics(
                          child: ColoredBox(
                            color: const Color(0xffd6f64a),
                            child: SizedBox(
                              width: 84,
                              height: 76,
                              child: Row(
                                children: [
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      6,
                                      (_) => const Icon(
                                        Icons.circle,
                                        size: 4,
                                        color: Color(0xff677623),
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Icon(
                                      Icons.confirmation_number_outlined,
                                      color: Color(0xff23231d),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!_torn) ...[
            const Text('Desliza el talón a la derecha o pulsa el botón.'),
            const SizedBox(height: 8),
          ],
          FilledButton(
            onPressed: _torn ? () => Navigator.pop(context, true) : _tear,
            child: Text(_torn ? 'Guardar boleto' : 'Desprender boleto'),
          ),
        ],
      ),
    );
  }
}
