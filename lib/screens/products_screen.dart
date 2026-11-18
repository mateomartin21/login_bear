import 'package:flutter/material.dart';
import 'package:login_bear/services/product_service.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final products = snap.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(products[i].name),
              subtitle: Text('Stock: ${products[i].stock}'),
              trailing: Text('\$${products[i].price.toStringAsFixed(2)}'),
            ),
          );
        },
      ),
    );
  }
}
