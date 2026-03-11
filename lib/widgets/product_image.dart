// lib/widgets/product_image.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../utils/constants.dart';

class ProductImage extends StatefulWidget {
  final int? productId;           // ← CHANGEZ : rendez-le optionnel (avec ?)
  final String? imageUrl;          // ← GARDEZ
  final double width;
  final double height;
  final BoxFit fit;

  const ProductImage({
    Key? key,
    this.productId,                // ← CHANGEZ : plus de "required"
    this.imageUrl,                 // ← GARDEZ
    this.width = 100,
    this.height = 100,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String baseUrl = AppConstants.baseUrl.replaceFirst('/api', '');
      String fullUrl;

      // ✅ 1. PRIORITÉ à l'URL directe si fournie
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        if (widget.imageUrl!.startsWith('http')) {
          fullUrl = widget.imageUrl!;
        } else if (widget.imageUrl!.startsWith('/')) {
          fullUrl = '$baseUrl${widget.imageUrl}';
        } else {
          fullUrl = '$baseUrl/${widget.imageUrl}';
        }
      }
      // ✅ 2. SINON, utiliser l'ID du produit
      else if (widget.productId != null) {
        fullUrl = '$baseUrl/products/${widget.productId}/image';
      }
      // ✅ 3. AUCUNE image
      else {
        setState(() {
          _error = 'Aucune image';
          _isLoading = false;
        });
        return;
      }

      print('📸 Chargement: $fullUrl');

      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Erreur affichage: $error');
          return _buildPlaceholder();
        },
      );
    }

    if (_isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey.shade400),
          if (widget.width > 50)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _error ?? 'Pas d\'image',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}