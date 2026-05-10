import 'package:flutter/material.dart';
import '../core/constants.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String? originalPrice;
  final String imageUrl;
  final String? promoLabel;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    this.originalPrice,
    this.promoLabel,
    required this.imageUrl,
    required this.onTap,
  });

  Widget _buildErrorIcon() {
    return Container(
      color: AppColors.surfaceWhite,
      child: const Icon(Icons.image, color: AppColors.borderGray),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isEmpty 
                    ? _buildErrorIcon()
                    : imageUrl.startsWith('assets/') 
                      ? Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
                        ),
                  if (promoLabel != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          promoLabel!,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          color: promoLabel != null ? Colors.orange.shade800 : AppColors.textLight, 
                          fontSize: 11,
                          fontWeight: promoLabel != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (originalPrice != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          originalPrice!,
                          style: const TextStyle(
                            color: AppColors.textLight, 
                            fontSize: 9,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
