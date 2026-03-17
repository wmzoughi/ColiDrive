// lib/screens/commercant/product_reviews_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/rating_stars.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';
import 'add_review_screen.dart';
import '../../models/review.dart';
import '../../widgets/product_image.dart';

class ProductReviewsScreen extends StatefulWidget {
  final Product product;

  const ProductReviewsScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadReviews({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
    }

    final reviewService = Provider.of<ReviewService>(context, listen: false);
    await reviewService.getSupplierReviews(widget.product.supplierId!, page: _currentPage);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final reviewService = Provider.of<ReviewService>(context, listen: false);
      if (reviewService.supplierReviews != null &&
          _currentPage < reviewService.supplierReviews!.pagination.lastPage) {
        setState(() {
          _currentPage++;
        });
        _loadReviews();
      }
    }
  }

  Future<void> _checkUserReview() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final reviewService = Provider.of<ReviewService>(context, listen: false);

    if (!authService.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    final result = await reviewService.checkReview(widget.product.supplierId!);

    if (result['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddReviewScreen(
            supplierId: widget.product.supplierId!,
            supplierName: widget.product.supplierName ?? 'Fournisseur',
            existingReview: result['review'],
          ),
        ),
      ).then((_) => _loadReviews(reset: true));
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion requise'),
        content: const Text('Vous devez être connecté pour laisser un avis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewService = Provider.of<ReviewService>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.product.name,
              style: const TextStyle(
                color: Color(0xFF2D3A4F),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Avis sur ce produit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3A4F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline, color: AppColors.primary),
            onPressed: _checkUserReview,
          ),
        ],
      ),
      body: reviewService.isLoading && reviewService.supplierReviews == null
          ? const Center(child: CircularProgressIndicator())
          : reviewService.supplierReviews == null
          ? _buildErrorState(reviewService)
          : RefreshIndicator(
        onRefresh: () => _loadReviews(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // En-tête du produit
            SliverToBoxAdapter(
              child: _buildProductHeader(),
            ),

            // En-tête des statistiques
            SliverToBoxAdapter(
              child: _buildStatsHeader(reviewService.supplierReviews!.supplier),
            ),

            // Liste des avis
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  if (index == reviewService.supplierReviews!.reviews.length) {
                    return _buildLoadingIndicator();
                  }
                  final review = reviewService.supplierReviews!.reviews[index];
                  return _buildReviewCard(review);
                },
                childCount: reviewService.supplierReviews!.reviews.length +
                    (reviewService.supplierReviews!.pagination.currentPage <
                        reviewService.supplierReviews!.pagination.lastPage
                        ? 1
                        : 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          // Image du produit - ✅ Utilisez ProductImage
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ProductImage(
              productId: widget.product.id,
              imageUrl: widget.product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.supplierName ?? 'Fournisseur',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.product.currentPrice.toStringAsFixed(2)} MAD',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(SupplierInfo supplier) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A4F),
                    ),
                  ),
                  RatingStars(
                    rating: supplier.averageRating,
                    size: 20,
                    showNumber: false,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${supplier.reviewsCount} avis',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Note globale',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 32),

          // Distribution des notes
          ...List.generate(5, (index) {
            int star = 5 - index;
            int count = supplier.ratingDistribution[star] ?? 0;
            double percentage = supplier.reviewsCount > 0
                ? (count / supplier.reviewsCount) * 100
                : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$star ⭐',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          star >= 4 ? Colors.green :
                          star >= 3 ? Colors.orange : Colors.red,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          review.merchantName[0].toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.merchantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            review.createdAt,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              RatingStars(
                rating: review.rating.toDouble(),
                size: 14,
                showNumber: false,
              ),
            ],
          ),

          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorState(ReviewService reviewService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reviewService.error ?? 'Une erreur est survenue',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadReviews(reset: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}