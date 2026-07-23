import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  final int qty;
  final String color;
  final String size;
  final double priceUsd;

  CartItem({
    required this.product,
    this.qty = 1,
    this.color = '',
    this.size = '',
    this.priceUsd = 0,
  });

  double get subtotal => (priceUsd > 0 ? priceUsd : product.displayPrice) * qty;
  double get weight => product.weight * qty;

  String get spec {
    if (color.isNotEmpty && size.isNotEmpty) return '$color / $size';
    if (color.isNotEmpty) return color;
    if (size.isNotEmpty) return size;
    return 'Default';
  }

  Map<String, dynamic> toJson() => {
    'itemId': product.itemId,
    'title': product.title,
    'imageUrl': product.imageUrl,
    'priceCny': product.priceCny,
    'priceUsd': product.priceUsd,
    'promotionPriceCny': product.promotionPriceCny,
    'promotionPriceUsd': product.promotionPriceUsd,
    'sales': product.sales,
    'platform': product.platform,
    'weight': product.weight,
    'colors': product.colors,
    'sizes': product.sizes,
    'qty': qty,
    'color': color,
    'size': size,
    'priceUsdOverride': priceUsd,
  };

  static CartItem fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product(
        itemId: json['itemId'] ?? '',
        title: json['title'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        priceCny: (json['priceCny'] ?? 0).toDouble(),
        priceUsd: (json['priceUsd'] ?? 0).toDouble(),
        promotionPriceCny: json['promotionPriceCny']?.toDouble(),
        promotionPriceUsd: json['promotionPriceUsd']?.toDouble(),
        sales: json['sales'] ?? 0,
        platform: json['platform'] ?? 'taobao',
        weight: (json['weight'] ?? 0.5).toDouble(),
      ),
      qty: json['qty'] ?? 1,
      color: json['color'] ?? '',
      size: json['size'] ?? '',
      priceUsd: (json['priceUsdOverride'] ?? 0).toDouble(),
    );
  }
}

class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  static const String _storageKey = 'safebuy_cart';

  CartService() {
    _loadFromPrefs();
  }

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.qty);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalWeight => _items.fold(0, (sum, item) => sum + item.weight);

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored != null) {
        final list = (json.decode(stored) as List).cast<Map<String, dynamic>>();
        _items = list.map((j) => CartItem.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cart load failed: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = json.encode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Cart save failed: $e');
    }
  }

  void addItem(Product product, {String color = '', String size = '', double priceUsd = 0, int qty = 1}) {
    final idx = _items.indexWhere((i) =>
        i.product.itemId == product.itemId && i.color == color && i.size == size);
    if (idx >= 0) {
      _items[idx] = CartItem(
        product: product,
        qty: _items[idx].qty + qty,
        color: color,
        size: size,
        priceUsd: priceUsd,
      );
    } else {
      _items.add(CartItem(product: product, qty: qty, color: color, size: size, priceUsd: priceUsd));
    }
    notifyListeners();
    _saveToPrefs();
  }

  void removeItem(int index) {
    if (index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
      _saveToPrefs();
    }
  }

  void updateQty(int index, int qty) {
    if (index < _items.length && qty > 0) {
      final item = _items[index];
      _items[index] = CartItem(
        product: item.product,
        qty: qty,
        color: item.color,
        size: item.size,
        priceUsd: item.priceUsd,
      );
      notifyListeners();
      _saveToPrefs();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _saveToPrefs();
  }
}
