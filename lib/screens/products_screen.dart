import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_bear/screens/login_screens.dart';
import 'package:login_bear/services/product_service.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreens()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
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
              subtitle: Text('${products[i].category} · Stock: ${products[i].stock}'),
              trailing: Text('\$${products[i].price.toStringAsFixed(2)}'),
            ),
          );
        },
      ),
    );
  }
}
