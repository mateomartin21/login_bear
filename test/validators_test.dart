import 'package:flutter_test/flutter_test.dart';
import 'package:login_bear/utils/validators.dart';

void main() {
  test('correo institucional', () {
    expect(isInstitutionalEmail('mateo.martin@tecdesoftware.edu.mx'), isTrue);
    expect(isInstitutionalEmail('Mateo@TecDeSoftware.edu.mx'), isTrue);
    expect(isInstitutionalEmail('mateo@gmail.com'), isFalse);
    expect(isInstitutionalEmail('mateo@tecdesoftware.edu.mx.evil.com'), isFalse);
    expect(isInstitutionalEmail('@tecdesoftware.edu.mx'), isFalse);
  });

  test('contraseña fuerte', () {
    expect(isStrongPassword('Bear2026!'), isTrue);
    expect(isStrongPassword('bear2026!'), isFalse); // sin mayúscula
    expect(isStrongPassword('BEAR2026!'), isFalse); // sin minúscula
    expect(isStrongPassword('Bearbear!'), isFalse); // sin número
    expect(isStrongPassword('Bear2026'), isFalse); // sin símbolo
    expect(isStrongPassword('Be2026!'), isFalse); // menos de 8
  });
}
