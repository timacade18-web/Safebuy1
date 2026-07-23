import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Consumer<CartService>(
        builder: (_, cart, __) {
          if (cart.items.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Color(0xFFDDDDDD)),
              SizedBox(height: 12),
              Text('Your cart is empty', style: TextStyle(fontSize: 15, color: Color(0xFF999999))),
            ]));
          }
          return Column(children: [
            Expanded(child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final item = cart.items[i];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: Image.network(item.product.imageUrl, width: 72, height: 72, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: const Color(0xFFF0F0F0), child: const Center(child: Text('📷')))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
                      const SizedBox(height: 4),
                      Text('\$${item.product.priceUsd.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFF0036))),
                    ])),
                    // Qty controls
                    Row(children: [
                      GestureDetector(
                        onTap: () => cart.updateQty(i, item.qty - 1),
                        child: Container(width: 28, height: 28, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDD)), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.remove, size: 14, color: Color(0xFF666666))),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${item.qty}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                      GestureDetector(
                        onTap: () => cart.updateQty(i, item.qty + 1),
                        child: Container(width: 28, height: 28, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDD)), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.add, size: 14, color: Color(0xFF666666))),
                      ),
                    ]),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => cart.removeItem(i),
                      child: const Icon(Icons.delete_outline, color: Color(0xFFCCCCCC), size: 20),
                    ),
                  ]),
                );
              },
            )),
            // Checkout bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${cart.itemCount} items', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  Text('\$${cart.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFF0036))),
                ]),
                const Spacer(),
                SizedBox(width: 140, child: ElevatedButton(
                  onPressed: () {
                    // Open web checkout
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening checkout...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5000), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  child: const Text('Checkout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                )),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
