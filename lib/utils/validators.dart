// Solo se usan en el registro; el login NO valida formato (OWASP A07).
bool isInstitutionalEmail(String email) =>
    RegExp(r'^[^\s@]+@tecdesoftware\.edu\.mx$', caseSensitive: false)
        .hasMatch(email);

// mínimo 8, una mayúscula, una minúscula, un dígito y un símbolo
bool isStrongPassword(String pass) =>
    RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$')
        .hasMatch(pass);
