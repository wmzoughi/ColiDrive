// lib/widgets/product_image_gallery.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product_image.dart' as model;  // 👈 ALIAS pour le modèle
import '../services/product_image_service.dart';
import '../services/auth_service.dart';
import 'product_image.dart';  // 👈 Ceci est le widget

class ProductImageGallery extends StatefulWidget {
  final int productId;
  final List<model.ProductImage>? initialImages;  // 👈 Utilisez model.ProductImage

  const ProductImageGallery({
    Key? key,
    required this.productId,
    this.initialImages,
  }) : super(key: key);

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late ProductImageService _imageService;
  List<model.ProductImage> _images = [];  // 👈 Utilisez model.ProductImage
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _imageService = ProductImageService(authService);

    if (widget.initialImages != null) {
      _images = widget.initialImages!;
    } else {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    final images = await _imageService.loadProductImages(widget.productId);
    if (mounted) {
      setState(() => _images = images);
    }
  }

  Future<void> _pickAndUploadImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles == null || pickedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    final files = pickedFiles.map((xfile) => File(xfile.path)).toList();

    final result = await _imageService.uploadImages(
      widget.productId,
      files,
      primaryIndex: _images.isEmpty ? 0 : null,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (result['success']) {
        await _loadImages();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Images téléchargées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setPrimary(model.ProductImage image) async {  // 👈 Utilisez model.ProductImage
    final success = await _imageService.setPrimaryImage(widget.productId, image.id);
    if (success && mounted) {
      await _loadImages();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image principale mise à jour'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteImage(model.ProductImage image) async {  // 👈 Utilisez model.ProductImage
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'image'),
        content: const Text('Voulez-vous vraiment supprimer cette image ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _imageService.deleteImage(widget.productId, image.id);
      if (success && mounted) {
        await _loadImages();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image supprimée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Images du produit (${_images.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadImages,
              icon: _isUploading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.add_photo_alternate),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_images.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.photo_library, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Aucune image',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez des images pour votre produit',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ProductImage(  // 👈 Ceci est le WIDGET (pas le modèle)
                      imageUrl: image.fullUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (image.isPrimary)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Principale',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Row(
                      children: [
                        if (!image.isPrimary)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.star, size: 16),
                              color: Colors.amber,
                              onPressed: () => _setPrimary(image),
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete, size: 16),
                            color: Colors.red,
                            onPressed: () => _deleteImage(image),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}