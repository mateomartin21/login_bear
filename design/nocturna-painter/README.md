# Pintor de Nocturna

El personaje se dibuja con curvas, elipses y formas rellenas. La jerarquía de nodos de `scene.rml` articula cabeza, ojos, boina, muñecas y manos. Una capa independiente controla el parpadeo y la respiración.

Desde la raíz del proyecto, ejecuta `python design/nocturna-painter/build_asset.py` para exportar `assets/nocturna-painter.riv`.

| Entrada | Respuesta |
| --- | --- |
| `isChecking` | Inclina el rostro hacia el correo. |
| `numLook` (0–100) | Desplaza las pupilas siguiendo la escritura. |
| `isHandsUp` | Alza ambas manos para cubrir los ojos y las baja al perder el foco. |
| `isSubmitting` | La muñeca mueve el pincel mientras responde Firebase. |
| `trigFail` | Niega con la cabeza. |
| `trigSuccess` | Inclina la cabeza y la boina. |

El evento `loginSuccessComplete` marca el final del saludo después de la autenticación.