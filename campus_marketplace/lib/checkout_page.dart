import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน')),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('ไม่มีสินค้าในตะกร้า'))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return ListTile(
                        title: Text(item.title),
                        trailing: Text('฿${item.price.toStringAsFixed(0)}'),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ยอดรวม', style: TextStyle(fontSize: 18)),
                    Text(
                      '฿${cart.totalValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty
                        ? null
                        : () {
                            context.read<CartModel>().clear();
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('สั่งซื้อสำเร็จ ขอบคุณที่ใช้บริการ'),
                              ),
                            );
                          },
                    child: const Text('ยืนยันการสั่งซื้อ'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
