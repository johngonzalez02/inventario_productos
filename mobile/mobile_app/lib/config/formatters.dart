String _miles(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Entero con separador de miles: 1234567 -> 1.234.567
String formatNumber(int value) => _miles(value);

/// Dinero estilo Colombia: 3200 -> $3.200   |   1500.5 -> $1.500,50
String formatMoney(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final entero = _miles(int.parse(parts[0]));
  final decimales = parts[1];
  return decimales == '00' ? '\$$entero' : '\$$entero,$decimales';
}
