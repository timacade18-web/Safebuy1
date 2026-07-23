import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _p;
  bool _loading = true;
  Product? _detailedProduct;
  int _qty = 1;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _p = widget.product;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    final d = await Provider.of<ApiService>(context, listen: false).getProductDetail(_p.itemId, platform: _p.platform);
    if (mounted) setState(() { _detailedProduct = d; _loading = false; });
  }

  void _addToCart() {
    context.read<CartService>().addItem(_p, priceUsd: _p.priceUsd, qty: _qty);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart ✔'), duration: Duration(seconds: 1)),
    );
  }

  void _buyNow() {
    _addToCart();
    Navigator.pushNamed(context, '/cart');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      appBar: AppBar(title: const Text('Product Detail')),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5000)))
        : SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Image
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Center(child: Image.network(_p.imageUrl, height: 280, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(height: 200, color: const Color(0xFFF0F0F0), child: const Center(child: Text('📷', style: TextStyle(fontSize: 48)))),
                )),
              ),
              // Price & title
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('\$${_p.priceUsd.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFFFF0036))),
                    const SizedBox(width: 8),
                    Text('≈¥${_p.priceCny.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                    const Spacer(),
                    if (_p.sales > 0) Text('${_p.sales} sold', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  ]),
                  const SizedBox(height: 8),
                  Text(_p.title, style: const TextStyle(fontSize: 15, color: Color(0xFF333333), height: 1.4)),
                  const SizedBox(height: 8),
                  if (_p.shopName.isNotEmpty)
                    Text('🏪 ${_p.shopName}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ]),
              ),
              const SizedBox(height: 8),
              // Specs / description
              if (_detailedProduct != null && (_detailedProduct!.desc ?? '').isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(_detailedProduct!.desc!, style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
                  ]),
                ),
              const SizedBox(height: 80),
            ]),
          ),
      // Buy bar
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFEEEEEE)))),
        child: Row(children: [
          // Qty
          Row(children: [
            GestureDetector(onTap: () { if (_qty > 1) setState(() => _qty--); },
              child: Container(width: 32, height: 32, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDD)), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.remove, size: 16, color: Color(0xFF666666))),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            GestureDetector(onTap: () => setState(() => _qty++),
              child: Container(width: 32, height: 32, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDDD)), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.add, size: 16, color: Color(0xFF666666))),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFF2E8), foregroundColor: const Color(0xFFFF5000), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFFF5000)))),
            child: const Text('🛒 Add to Cart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(
            onPressed: _buyNow,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5000), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
            child: const Text('⚡ Buy Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }
}
