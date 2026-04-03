// lib/screens/commercant/add_review_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/review_service.dart';
import '../../widgets/rating_stars.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

class AddReviewScreen extends StatefulWidget {
  final int supplierId;
  final String supplierName;
  final Map<String, dynamic>? existingReview;

  const AddReviewScreen({
    Key? key,
    required this.supplierId,
    required this.supplierName,
    this.existingReview,
  }) : super(key: key);

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!['rating'];
      _commentController.text = widget.existingReview!['comment'] ?? '';
      _isAnonymous = widget.existingReview!['is_anonymous'] ?? false;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final localizations = AppLocalizations.of(context)!;

    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.selectRatingError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final reviewService = Provider.of<ReviewService>(context, listen: false);
    final result = await reviewService.submitReview(
      supplierId: widget.supplierId,
      rating: _rating,
      comment: _commentController.text.isEmpty ? null : _commentController.text,
      isAnonymous: _isAnonymous,
    );

    setState(() => _isLoading = false);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? localizations.error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final localizations = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteReviewTitle),
        content: Text(localizations.deleteReviewConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final reviewService = Provider.of<ReviewService>(context, listen: false);
      final success = await reviewService.deleteReview(widget.existingReview!['id']);

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.reviewDeleted),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  String _getRatingText(int rating, AppLocalizations localizations) {
    if (rating == 0) {
      return localizations.tapToRate;
    }
    // Utiliser la clé sans paramètre et formater manuellement
    if (rating == 1) {
      return '${localizations.youRated} 1 ${localizations.star}';
    } else {
      return '${localizations.youRated} $rating ${localizations.stars}';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              widget.supplierName,
              style: const TextStyle(
                color: Color(0xFF2D3A4F),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.existingReview == null
                  ? localizations.addReview
                  : localizations.editReview,
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
          if (widget.existingReview != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _confirmDelete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Carte de notation
            Container(
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
                  Text(
                    localizations.yourRating,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sélecteur d'étoiles
                  StarRatingSelector(
                    rating: _rating,
                    onRatingChanged: (value) {
                      setState(() {
                        _rating = value;
                      });
                    },
                    size: 40,
                  ),

                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(_rating, localizations),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Commentaire
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.yourCommentOptional,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: localizations.commentHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Options anonyme
            Container(
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
              child: Row(
                children: [
                  Switch(
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.publishAnonymously,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          localizations.yourNameWillNotAppear,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton de soumission
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.existingReview == null
                      ? localizations.publishReview
                      : localizations.updateReview,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}