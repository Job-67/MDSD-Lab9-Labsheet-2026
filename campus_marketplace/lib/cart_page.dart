import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'checkout_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('ตะกร้าสินค้า')),
      body: cart.items.isEmpty
          ? const Center(child: Text('ยังไม่มีสินค้าในตะกร้า'))
          : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text('฿${item.price.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => context.read<CartModel>().remove(item),
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('มูลค่ารวม: ฿${cart.totalValue.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cart.items.isEmpty
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckoutPage()),
                        ),
                child: const Text('ไปหน้าชำระเงิน'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
