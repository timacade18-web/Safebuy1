import 'dart:convert';

class ProductVariant {
  final String color;
  final String size;
  final double priceCny;
  final int stock;

  ProductVariant({this.color = '', this.size = '', this.priceCny = 0, this.stock = 0});

  double get priceUsd => priceCny / 6.7;
}

class Product {
  final String itemId;
  final String title;
  final String imageUrl;
  final double priceCny;
  final double priceUsd;
  final double? promotionPriceCny;
  final double? promotionPriceUsd;
  final int sales;
  final String platform;
  final String shopName;
  final List<String> colors;
  final List<String> sizes;
  final List<ProductVariant> variants;
  final List<String> descImages;
  final List<String> galleryImages;
  final String? desc;
  final double weight;

  Product({
    required this.itemId,
    required this.title,
    required this.imageUrl,
    this.priceCny = 0,
    this.priceUsd = 0,
    this.promotionPriceCny,
    this.promotionPriceUsd,
    this.sales = 0,
    this.platform = 'taobao',
    this.shopName = '',
    this.colors = const [],
    this.sizes = const [],
    this.variants = const [],
    this.descImages = const [],
    this.galleryImages = const [],
    this.desc,
    this.weight = 0.5,
  });

  double get displayPrice => promotionPriceUsd ?? priceUsd;
  double get displayPriceCny => promotionPriceCny ?? priceCny;
  bool get hasDiscount => promotionPriceUsd != null && promotionPriceUsd! < priceUsd;

  factory Product.fromOneBound(Map<String, dynamic> json) {
    final price = (json['price'] is String ? double.tryParse(json['price']) : json['price']) ?? 0.0;
    final promo = (json['promotion_price'] is String ? double.tryParse(json['promotion_price']) : json['promotion_price']);
    return Product(
      itemId: json['num_iid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['pic_url']?.toString() ?? '',
      priceCny: price is double ? price : (price as num).toDouble(),
      priceUsd: price is double ? price / 6.7 : (price as num).toDouble() / 6.7,
      promotionPriceCny: promo != null ? (promo is double ? promo : (promo as num).toDouble()) : null,
      promotionPriceUsd: promo != null ? (promo is double ? promo / 6.7 : (promo as num).toDouble() / 6.7) : null,
      sales: int.tryParse(json['sales']?.toString() ?? '0') ?? 0,
      platform: 'taobao',
    );
  }

  factory Product.fromOneBoundDetail(Map<String, dynamic> json) {
    final price = (json['price'] is String ? double.tryParse(json['price']) : json['price']) ?? 0.0;
    final promo = (json['promotion_price'] is String ? double.tryParse(json['promotion_price']) : json['promotion_price']);
    final pPrice = price is double ? price : (price as num).toDouble();
    final pPromo = promo != null ? (promo is double ? promo : (promo as num).toDouble()) : null;

    // Parse colors and sizes from props_list
    final List<String> colors = [];
    final List<String> sizes = [];
    final propsList = json['props_list'] as Map<String, dynamic>? ?? {};

    propsList.forEach((key, value) {
      final val = value.toString();
      final parts = val.split(':');
      final cleanVal = parts.length > 1 ? parts.sublist(1).join(':') : val;
      final low = val.toLowerCase();

      if (low.contains('color') || low.contains('colour') || val.contains('色') || val.contains('颜色')) {
        if (!colors.contains(cleanVal)) colors.add(cleanVal);
      } else if (low.contains('size') || val.contains('尺码') || val.contains('尺寸') ||
          val.contains('规格') || RegExp(r'^[SMLX]L?$').hasMatch(cleanVal) || RegExp(r'^\d+').hasMatch(cleanVal)) {
        if (!sizes.contains(cleanVal)) sizes.add(cleanVal);
      }
    });

    // Parse SKUs
    final List<ProductVariant> variants = [];
    final skus = json['skus'] as Map<String, dynamic>?;
    final skuArr = skus?['sku'];
    if (skuArr is List) {
      for (final sku in skuArr) {
        final propStr = sku['properties']?.toString() ?? '';
        final parts = propStr.split(';');
        String color = '', size = '';
        for (final p in parts) {
          if (colors.any((c) => p.contains(c))) color = p;
          if (sizes.any((s) => p.contains(s))) size = p;
        }
        variants.add(ProductVariant(
          color: color,
          size: size,
          priceCny: (sku['price'] is String ? double.tryParse(sku['price']) : sku['price']) ?? 0.0,
          stock: int.tryParse(sku['quantity']?.toString() ?? '0') ?? 0,
        ));
      }
    }

    // Description images
    final List<String> descImgs = [];
    final descImgsRaw = json['desc_img'];
    if (descImgsRaw is List) {
      for (final e in descImgsRaw) {
        if (e is Map) {
          final u = e['url']?.toString() ?? '';
          if (u.isNotEmpty) descImgs.add(u);
        } else {
          final s = e.toString();
          if (s.isNotEmpty) descImgs.add(s);
        }
      }
    } else if (descImgsRaw is String && descImgsRaw.isNotEmpty) {
      descImgs.addAll(descImgsRaw.split(',').where((s) => s.isNotEmpty));
    }

    // Gallery images (item_imgs)
    final List<String> galleryImgs = [];
    final galleryRaw = json['item_imgs'];
    if (galleryRaw is List) {
      for (final e in galleryRaw) {
        if (e is Map) {
          final u = e['url']?.toString() ?? '';
          if (u.isNotEmpty) galleryImgs.add(u);
        } else {
          final s = e.toString();
          if (s.isNotEmpty) galleryImgs.add(s);
        }
      }
    }

    return Product(
      itemId: json['num_iid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['pic_url']?.toString() ?? json['picUrl']?.toString() ?? '',
      priceCny: pPrice,
      priceUsd: pPrice / 6.7,
      promotionPriceCny: pPromo,
      promotionPriceUsd: pPromo != null ? pPromo / 6.7 : null,
      sales: int.tryParse(json['sales']?.toString() ?? json['sold']?.toString() ?? '0') ?? 0,
      colors: colors,
      sizes: sizes,
      variants: variants,
      descImages: descImgs,
      galleryImages: galleryImgs,
      desc: json['desc']?.toString() ?? json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'title': title,
    'imageUrl': imageUrl,
    'priceUsd': priceUsd,
    'displayPrice': displayPrice,
    'sales': sales,
  };

  @override
  String toString() => '$title (\$${displayPrice.toStringAsFixed(2)})';
}
