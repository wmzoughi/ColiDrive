// lib/screens/fournisseur/add_edit_product_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';
import '../../widgets/product_image.dart';
import '../../l10n/app_localizations.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final VoidCallback onProductAdded;

  const AddEditProductScreen({
    Key? key,
    this.product,
    required this.categories,
    required this.onProductAdded,
  }) : super(key: key);

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _packagingController = TextEditingController();
  final _codeController = TextEditingController();
  final _promoPriceController = TextEditingController();
  final _promoStartController = TextEditingController();
  final _promoEndController = TextEditingController();

  File? _imageFile;
  final picker = ImagePicker();

  int? _selectedCategoryId;
  bool _isPromotion = false;
  bool _isLoading = false;
  bool _isAddingCategory = false;
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Forcer le chargement des catégories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productService = Provider.of<ProductService>(context, listen: false);
      if (productService.categories.isEmpty) {
        productService.loadCategories();
      }
    });


    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description ?? '';
      _priceController.text = widget.product!.listPrice.toString();
      _packagingController.text = widget.product!.packaging ?? '';
      _codeController.text = widget.product!.defaultCode ?? '';
      _selectedCategoryId = widget.product!.categoryId;
      _isPromotion = widget.product!.isPromotion;
      if (widget.product!.promotionPrice != null) {
        _promoPriceController.text = widget.product!.promotionPrice!.toString();
      }
      if (widget.product!.promotionStart != null) {
        _promoStartController.text =
        '${widget.product!.promotionStart!.year}-${widget.product!.promotionStart!.month.toString().padLeft(2, '0')}-${widget.product!.promotionStart!.day.toString().padLeft(2, '0')}';
      }
      if (widget.product!.promotionEnd != null) {
        _promoEndController.text =
        '${widget.product!.promotionEnd!.year}-${widget.product!.promotionEnd!.month.toString().padLeft(2, '0')}-${widget.product!.promotionEnd!.day.toString().padLeft(2, '0')}';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _packagingController.dispose();
    _codeController.dispose();
    _promoPriceController.dispose();
    _promoStartController.dispose();
    _promoEndController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _showImageSourceBottomSheet() {
    final localizations = AppLocalizations.of(context)!;

    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    localizations.add,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3A4F),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(localizations.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _checkPermissionAndPickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text(localizations.chooseFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _checkPermissionAndPickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: Text(localizations.cancel),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkPermissionAndPickImage(ImageSource source) async {
    final localizations = AppLocalizations.of(context)!;

    if (source == ImageSource.camera) {
      if (await Permission.camera.request().isGranted) {
        _pickImage(source);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.cameraPermissionDenied),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      // Pour la galerie
      bool granted = false;

      if (Platform.isAndroid) {
        // Essayer d'abord Permission.storage
        if (await Permission.storage.request().isGranted) {
          granted = true;
        }
        // Sinon essayer Permission.photos (Android 13+)
        else if (await Permission.photos.request().isGranted) {
          granted = true;
        }
      } else {
        // iOS
        granted = await Permission.photos.request().isGranted;
      }

      if (granted) {
        _pickImage(source);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.galleryPermissionDenied),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final localizations = AppLocalizations.of(context)!;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.error}: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _addNewCategory() async {
    final localizations = AppLocalizations.of(context)!;

    if (_newCategoryController.text.isEmpty) return;

    setState(() {
      _isAddingCategory = true;
    });

    final productService = Provider.of<ProductService>(context, listen: false);
    final result = await productService.addCategory({
      'name': _newCategoryController.text,
    });

    setState(() {
      _isAddingCategory = false;
    });

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.categoryAdded),
          backgroundColor: AppColors.success,
        ),

      );
      _newCategoryController.clear();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['errors']?['general']?[0] ?? localizations.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddCategoryDialog() {
    final localizations = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.addCategory),
          content: TextField(
            controller: _newCategoryController,
            decoration: InputDecoration(
              hintText: localizations.categoryName,
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: _addNewCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: _isAddingCategory
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(localizations.add),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadImage(int productId) async {
    final localizations = AppLocalizations.of(context)!;

    if (_imageFile == null) return;

    final productService = Provider.of<ProductService>(context, listen: false);
    final result = await productService.uploadProductImage(productId, _imageFile!);

    if (result['success'] && mounted) {
      await productService.loadProducts(reset: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.imageUploaded),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _saveProduct() async {
    final localizations = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final productData = {
      'name': _nameController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'list_price': double.parse(_priceController.text),
      'packaging': _packagingController.text.isEmpty ? null : _packagingController.text,
      'is_promotion': _isPromotion ? 1 : 0,
      'categ_id': _selectedCategoryId,
      'default_code': _codeController.text.isEmpty ? null : _codeController.text,
    };

    if (_isPromotion) {
      productData['promotion_price'] = double.parse(_promoPriceController.text);
      productData['promotion_start'] = _promoStartController.text;
      productData['promotion_end'] = _promoEndController.text;
    }

    final productService = Provider.of<ProductService>(context, listen: false);
    Map<String, dynamic> result;

    if (widget.product == null) {
      result = await productService.addProduct(productData);
      if (result['success'] && _imageFile != null && mounted) {
        final newProductId = result['product'].id;
        await _uploadImage(newProductId);
      }
    } else {
      result = await productService.updateProduct(widget.product!.id, productData);
      if (result['success'] && _imageFile != null && mounted) {
        await _uploadImage(widget.product!.id);
      }
    }

    setState(() => _isLoading = false);

    if (result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null
              ? localizations.productAdded
              : localizations.productUpdated),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onProductAdded();

      // 👇 Petit délai de 100ms avant de fermer
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['errors']?['general']?[0] ?? localizations.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.product == null ? localizations.addProduct : localizations.editProduct,
          style: const TextStyle(
            color: Color(0xFF2D3A4F),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code produit
              Text(
                localizations.productCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A4F),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  hintText: localizations.productCodeHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nom du produit
              Text(
                '${localizations.products} *',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A4F),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: localizations.productNameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                localizations.description,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A4F),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: localizations.descriptionHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Catégorie
              Text(
                '${localizations.category} *',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A4F),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Consumer<ProductService>(
                      builder: (context, productService, child) {
                        // 👇 Vérifier si les catégories sont en cours de chargement
                        if (productService.isLoading) {
                          return const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        // 👇 Si pas de catégories, afficher un message
                        if (productService.categories.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Aucune catégorie disponible',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          hint: Text(localizations.selectCategory),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: productService.categories.map((category) {
                            return DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategoryId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return localizations.fieldRequired;
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: AppColors.primary),
                      onPressed: _showAddCategoryDialog,
                      tooltip: localizations.addCategory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Prix
              Text(
                localizations.price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A4F),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      localizations.currency,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.fieldRequired;
                  }
                  if (double.tryParse(value) == null) {
                    return localizations.invalidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Conditionnement (Quantité)
              Text(
                localizations.packaging,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3A4F),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _packagingController,
                decoration: InputDecoration(
                  hintText: localizations.packagingHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Promotion
              Row(
                children: [
                  Checkbox(
                    value: _isPromotion,
                    onChanged: (value) {
                      setState(() {
                        _isPromotion = value ?? false;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  Text(
                    localizations.inPromotion,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3A4F),
                    ),
                  ),
                ],
              ),

              if (_isPromotion) ...[
                const SizedBox(height: 16),
                // Prix promotionnel
                Text(
                  localizations.promotionPrice,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A4F),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _promoPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        localizations.currency,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (_isPromotion && (value == null || value.isEmpty)) {
                      return localizations.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date début promotion
                Text(
                  localizations.promotionStart,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A4F),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _promoStartController,
                  readOnly: true,
                  onTap: () => _selectDate(_promoStartController),
                  decoration: InputDecoration(
                    hintText: localizations.dateFormat,
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (_isPromotion && (value == null || value.isEmpty)) {
                      return localizations.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date fin promotion
                Text(
                  localizations.promotionEnd,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3A4F),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _promoEndController,
                  readOnly: true,
                  onTap: () => _selectDate(_promoEndController),
                  decoration: InputDecoration(
                    hintText: localizations.dateFormat,
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (_isPromotion && (value == null || value.isEmpty)) {
                      return localizations.fieldRequired;
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Section Image
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.productImage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3A4F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                width: 150,
                                height: 150,
                              ),
                            )
                                : (widget.product?.imageUrl != null
                                ? ProductImage(
                              productId: widget.product!.id,
                              imageUrl: widget.product!.imageUrl,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            )
                                : Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 50,
                              color: Colors.grey,
                            )),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                onPressed: _showImageSourceBottomSheet,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_imageFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            '${localizations.selectedImage}: ${_imageFile!.path.split('/').last}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Bouton sauvegarder
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    widget.product == null ? localizations.add : localizations.save,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}