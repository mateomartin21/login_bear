# Museo nocturno

Galería Flutter y API local de Spring Boot. La colección reúne pinturas, grabados y objetos de [The Met Open Access](https://www.metmuseum.org/hubs/open-access). Explora por técnica, sigue los recorridos temáticos y abre las pistas de observación en las fichas.

El catálogo entrega la URL pública HTTPS de cada imagen en The Met como `imageUrl`. Flutter usa `imageAsset` como respaldo local si falla la descarga y para procesar el efecto Trama.

## Ejecutar

Con Java 21 y Maven, desde `museum-backend/`:

```sh
mvn verify
java -jar target/museum-backend-0.1.0.jar
```

Para probar el login completo en local, inicia Firebase Auth Emulator desde `museum-backend/`:

```sh
npx firebase-tools emulators:start --only auth --project demo-museo-nocturno
```

Desde la raíz del repositorio, en otro terminal:

```sh
flutter run -d chrome --web-hostname localhost --web-port 7357 -t lib/museum_main.dart --dart-define=MUSEUM_AUTH_EMULATOR=true
```

Para servir una compilación web existente desde `build/web`, ejecuta
`python museum-backend/serve_demo.py` desde la raíz del repositorio.

Selecciona **Crear cuenta** en el login para registrar un correo de prueba terminado en `@tecdesoftware.edu.mx`. El emulador conserva las cuentas hasta que se detiene. Para probar en Chrome contra un proyecto real, omite la bandera del emulador y proporciona las opciones web de Firebase por `--dart-define-from-file` con las claves `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID` y `FIREBASE_PROJECT_ID`.

Para Android, inicia el dispositivo virtual y ejecuta `flutter run -t lib/museum_main.dart --dart-define=MUSEUM_AUTH_EMULATOR=true`. La app usa `10.0.2.2:8091` para el catálogo y `10.0.2.2:9099` para la autenticación local. En un celular físico con Firebase configurado, puedes exponer la API en tu red local con `MUSEUM_BIND=0.0.0.0` y pasar `--dart-define=MUSEUM_API=http://IP_DE_TU_PC:8091` a Flutter. La API local almacena los álbumes en un espacio compartido y admite solicitudes sin autenticación.

Por defecto se guardan los cambios en `museum-backend/data/` con H2. Para usar PostgreSQL, crea una base vacía, define `MUSEUM_DB_URL` con su URL JDBC y configura `MUSEUM_DB_USER` y `MUSEUM_DB_PASSWORD` en el entorno del backend.

En **Explorar**, abre una obra o inicia un recorrido guiado. En **Álbumes**, elige obras, ajusta el orden y guarda el álbum. Usa el lápiz para editarlo o borrarlo.
