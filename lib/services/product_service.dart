import 'dart:convert';
import 'package:http/http.dart' as http;

// 10.0.2.2 = localhost de la PC visto desde el emulador Android.
// Dispositivo físico: usar la IP LAN de la PC (ipconfig).
const apiBaseUrl = 'http://10.0.2.2:8090';

class Product {
  final int id;
  final String name;
  final double price;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['productId'] as int,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int,
      );
}

Future<List<Product>> fetchProducts() async {
  final res = await http
      .get(Uri.parse('$apiBaseUrl/products'))
      .timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) {
    throw Exception('API respondió ${res.statusCode}');
  }
  final list = jsonDecode(res.body) as List<dynamic>;
  return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
}
