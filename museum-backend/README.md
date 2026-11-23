# Museo nocturno

Galería Flutter y API local de Spring Boot. El catálogo inicial contiene seis obras de dominio público de [The Met Open Access](https://www.metmuseum.org/hubs/open-access). Las fichas se sirven localmente y las imágenes se descargan del museo al recorrer la galería.

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

Selecciona **Crear cuenta** en el login para registrar un correo de prueba terminado en `@tecdesoftware.edu.mx`. El emulador conserva las cuentas hasta que se detiene. Para probar en Chrome contra un proyecto real, omite la bandera del emulador y proporciona las opciones web de Firebase por `--dart-define-from-file` con las claves `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID` y `FIREBASE_PROJECT_ID`.

Para Android, arranca un emulador y usa `flutter run -t lib/museum_main.dart`. Sin la bandera del emulador se usa la configuración de Firebase de Android. La app usa `10.0.2.2:8091` como dirección del museo. En un celular físico, configura `MUSEUM_BIND=0.0.0.0` para el backend y pasa `--dart-define=MUSEUM_API=http://IP_DE_TU_PC:8091` a Flutter. La API de la demo guarda las salas en un espacio compartido y no autentica solicitudes.

Por defecto se guardan los cambios en `museum-backend/data/` con H2. Para usar PostgreSQL, crea una base vacía, define `MUSEUM_DB_URL` con su URL JDBC y configura `MUSEUM_DB_USER` y `MUSEUM_DB_PASSWORD` en el entorno del backend.

En **Colección**, abre una obra y desliza para pasar a la siguiente. En **Exposiciones**, crea una sala, elige obras, ajusta el orden y guarda. Toca la sala para recorrerla y usa el lápiz para editarla o borrarla.
