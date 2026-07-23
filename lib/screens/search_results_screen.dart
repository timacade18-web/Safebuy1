import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final String platform;
  const SearchResultsScreen({super.key, required this.query, required this.platform});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final _scroll = ScrollController();
  List<Product> _items = [];
  bool _loading = true, _hasMore = true;
  int _page = 1;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 && !_loading && _hasMore) _search();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _search();
    }
  }

  Future<void> _search() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final items = await api.searchProducts(widget.query, plat: widget.platform, page: _page);
    if (mounted) setState(() {
      if (_page == 1) _items = items; else _items.addAll(items);
      _hasMore = items.length >= 20;
      _page++;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.query)),
      body: _items.isEmpty && _loading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5000)))
        : _items.isEmpty
          ? const Center(child: Text('No results found', style: TextStyle(color: Color(0xFF999999))))
          : Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                controller: _scroll,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: _items.length + (_hasMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i >= _items.length) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFFFF5000))));
                  final p = _items[i];
                  return ProductCard(
                    product: p,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                    onAddToCart: () {
                      context.read<CartService>().addItem(p, priceUsd: p.priceUsd);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart ✔'), duration: Duration(seconds: 1)));
                    },
                  );
                },
              ),
            ),
    );
  }
}
