import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtl = TextEditingController();
  String _plat = '1688';
  List<Product> _trending = [];
  bool _loadingTrending = true;
  int _bannerIdx = 0;
  bool _initialized = false;

  static const _cats = [
    {'icon': '👗', 'label': 'Dresses', 'color': 0xFFFFF0E6, 'q': 'dresses'},
    {'icon': '👟', 'label': 'Shoes', 'color': 0xFFFFEAEC, 'q': 'shoes'},
    {'icon': '👜', 'label': 'Bags', 'color': 0xFFE8F8F0, 'q': 'bags'},
    {'icon': '📱', 'label': 'Mobiles', 'color': 0xFFFFF5E0, 'q': 'phones'},
    {'icon': '💄', 'label': 'Beauty', 'color': 0xFFF4EDFF, 'q': 'beauty'},
    {'icon': '💻', 'label': 'Computers', 'color': 0xFFEDF2FF, 'q': 'laptops'},
    {'icon': '🧸', 'label': 'Toys', 'color': 0xFFFFF0F5, 'q': 'toys'},
    {'icon': '⌚', 'label': 'Watches', 'color': 0xFFE6F7FF, 'q': 'watches'},
    {'icon': '🧥', 'label': 'Jackets', 'color': 0xFFF0FFF4, 'q': 'jackets'},
    {'icon': '🎽', 'label': 'Sport', 'color': 0xFFFFF9E6, 'q': 'sport'},
  ];

  static const _banners = [
    {'title': 'Shop China', 'sub': 'Delivered to Your Door', 'color': 0xFF1a1a2e},
    {'title': 'Fast Shipping', 'sub': 'Air 7-15 · Express 3-7 · Sea 25-40 days', 'color': 0xFF16213e},
    {'title': 'New Arrivals', 'sub': 'Fresh trends from China daily', 'color': 0xFF0f3460},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadTrending();
    }
  }

  Future<void> _loadTrending() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final items = await api.getTrending();
    if (mounted) setState(() { _trending = items; _loadingTrending = false; });
  }

  void _doSearch(String q) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SearchResultsScreen(query: q, platform: _plat),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverToBoxAdapter(child: _buildAppBar()),
            // Search
            SliverToBoxAdapter(child: _buildSearch()),
            // Notice
            SliverToBoxAdapter(child: Container(
              color: const Color(0xFF1B2A4A),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Text('🔥 China → Somalia Express Route Active · 5-15 day delivery',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            )),
            // Banner
            SliverToBoxAdapter(child: _buildBanner()),
            // Platform tabs
            SliverToBoxAdapter(child: _buildPlatTabs()),
            // Categories
            SliverToBoxAdapter(child: _buildCategories()),
            // Trending header
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Row(children: [
                const Text('🔥 Trending Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                const Spacer(),
                Container(width: 8, height: 14, decoration: BoxDecoration(color: const Color(0xFFFF5000), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                const Text('HOT', style: TextStyle(fontSize: 11, color: Color(0xFFFF5000), fontWeight: FontWeight.w700)),
              ]),
            )),
            // Products
            _loadingTrending
              ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFFF5000)))))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.62, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => ProductCard(
                        product: _trending[i],
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(product: _trending[i]),
                        )),
                        onAddToCart: () {
                              final p = _trending[i];
                              context.read<CartService>().addItem(p, priceUsd: p.priceUsd);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart ✔'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                      childCount: _trending.length,
                    ),
                  ),
                ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildLogo()),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SAFEBUY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFF5000))),
          Text('Shop China → Africa', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
        ]),
        const Spacer(),
        Consumer<CartService>(builder: (_, cart, __) {
          return Badge(
            isLabelVisible: cart.itemCount > 0,
            label: Text('${cart.itemCount}', style: const TextStyle(fontSize: 10, color: Colors.white)),
            backgroundColor: const Color(0xFFFF0036),
            child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF333333)),
          );
        }),
        const SizedBox(width: 16),
        const Icon(Icons.person_outline, color: Color(0xFF333333)),
      ]),
    );
  }

  Widget _buildLogo() {
    final url = ApiService.appLogoUrl;
    if (url != null) {
      return Image.network(url, height: 36, width: 36, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/icon-192.png', height: 36, width: 36));
    }
    return Image.asset('assets/icon-192.png', height: 36, width: 36);
  }

  Widget _buildSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6A00), Color(0xFFFF5000)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFFFF5000).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          const SizedBox(width: 18),
          Expanded(child: TextField(
            controller: _searchCtl,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              border: InputBorder.none, hintText: 'Search products...',
              hintStyle: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            onSubmitted: (q) { if (q.trim().isNotEmpty) _doSearch(q.trim()); },
          )),
          GestureDetector(
            onTap: () => _doSearch('📷'), // image search trigger
            child: Container(width: 36, height: 36, decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(18),
            ), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () { if (_searchCtl.text.trim().isNotEmpty) _doSearch(_searchCtl.text.trim()); },
            child: Container(width: 36, height: 36, decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18),
            ), child: const Icon(Icons.search, color: Color(0xFFFF5000), size: 20)),
          ),
          const SizedBox(width: 8),
        ]),
      ),
    );
  }

  Widget _buildBanner() {
    return SizedBox(
      height: 170,
      child: Stack(children: [
        PageView.builder(
          itemCount: _banners.length,
          onPageChanged: (i) => setState(() => _bannerIdx = i),
          itemBuilder: (ctx, i) {
            final b = _banners[i];
            return Container(
              color: Color(b['color'] as int),
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text((b['title'] as String?) ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text((b['sub'] as String?) ?? '', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
              ]),
            );
          },
        ),
        Positioned(bottom: 10, left: 0, right: 0,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_banners.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _bannerIdx == i ? 18 : 6, height: 6,
              decoration: BoxDecoration(
                color: _bannerIdx == i ? Colors.white : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          })),
        ),
      ]),
    );
  }

  Widget _buildPlatTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _platTab('Taobao', 'taobao'),
          _platTab('1688', '1688'),
        ],
      ),
    );
  }

  Widget _platTab(String label, String plat) {
    final active = _plat == plat;
    return GestureDetector(
      onTap: () => setState(() => _plat = plat),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? const Color(0xFFFF5000) : Colors.transparent, width: 3)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? const Color(0xFFFF5000) : const Color(0xFF999999),
        )),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.85),
        itemCount: _cats.length,
        itemBuilder: (ctx, i) {
          final c = _cats[i];
          return GestureDetector(
            onTap: () => _doSearch((c['q'] as String?) ?? ''),
            child: Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Color(c['color'] as int), borderRadius: BorderRadius.circular(22)),
                child: Center(child: Text((c['icon'] as String?) ?? '', style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(height: 4),
              Text((c['label'] as String?) ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF666666)), textAlign: TextAlign.center),
            ]),
          );
        },
      ),
    );
  }
}
