import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: const Color(0xFFF0F0F0),
                  child: const Center(child: Icon(Icons.image, size: 40, color: Color(0xFFCCCCCC))),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: const Color(0xFFF0F0F0),
                  child: const Center(child: Icon(Icons.broken_image, size: 40, color: Color(0xFFCCCCCC))),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (max 2 lines)
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  // Price row
                  Row(
                    children: [
                      Text(
                        '\$${product.displayPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6A00),
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 4),
                        Text(
                          '\$${product.priceUsd.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF999999),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (product.sales > 0)
                        Text(
                          '${product.sales} sold',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                        ),
                    ],
                  ),
                  if (onAddToCart != null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onAddToCart,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Add to Cart'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
