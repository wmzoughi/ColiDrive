// lib/screens/fournisseur/add_edit_product_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/product_image.dart';
import '../../widgets/product_image_gallery.dart';
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
  final _barcodeController = TextEditingController();
  final _promoPriceController = TextEditingController();
  final _promoStartController = TextEditingController();
  final _promoEndController = TextEditingController();

  final _stockQuantityController = TextEditingController();
  final _minStockAlertController = TextEditingController();
  final _maxStockAlertController = TextEditingController();

  final _baseUnitController = TextEditingController();
  final _defaultPackagingQuantityController = TextEditingController();
  final _unitWeightController = TextEditingController();
  final _unitVolumeController = TextEditingController();

  // 👉 CHANGEMENT: List<File> au lieu de File?
  List<File> _imageFiles = [];
  final picker = ImagePicker();

  int? _selectedCategoryId;
  bool _isPromotion = false;
  bool _isLoading = false;
  bool _isAddingCategory = false;
  bool? _barcodeExists;
  Timer? _barcodeDebounceTimer;

  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();

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
      _barcodeController.text = widget.product!.barcode ?? '';
      _selectedCategoryId = widget.product!.categoryId;
      _isPromotion = widget.product!.isPromotion;

      _stockQuantityController.text = widget.product!.stockQuantity?.toString() ?? '0';
      _minStockAlertController.text = widget.product!.minStockAlert?.toString() ?? '5';
      _maxStockAlertController.text = widget.product!.maxStockAlert?.toString() ?? '100';

      _baseUnitController.text = widget.product!.baseUnit ?? 'piece';
      _defaultPackagingQuantityController.text = widget.product!.defaultPackagingQuantity?.toString() ?? '1';
      _unitWeightController.text = widget.product!.unitWeight?.toString() ?? '';
      _unitVolumeController.text = widget.product!.unitVolume?.toString() ?? '';

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
    } else {
      _stockQuantityController.text = '0';
      _minStockAlertController.text = '5';
      _maxStockAlertController.text = '100';
      _baseUnitController.text = 'piece';
      _defaultPackagingQuantityController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _packagingController.dispose();
    _codeController.dispose();
    _barcodeController.dispose();
    _promoPriceController.dispose();
    _promoStartController.dispose();
    _promoEndController.dispose();
    _stockQuantityController.dispose();
    _minStockAlertController.dispose();
    _maxStockAlertController.dispose();
    _baseUnitController.dispose();
    _defaultPackagingQuantityController.dispose();
    _unitWeightController.dispose();
    _unitVolumeController.dispose();
    _newCategoryController.dispose();
    _barcodeDebounceTimer?.cancel();
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

  Future<void> _scanBarcode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Scanner le code-barres'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            body: MobileScanner(
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.noDuplicates,
              ),
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                final code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  Navigator.pop(context, code);
                }
              },
            ),
          ),
        ),
      );

      if (result != null && result.toString().isNotEmpty) {
        setState(() {
          _barcodeController.text = result.toString();
          _barcodeExists = null;
        });
        _checkBarcodeUniqueness(result.toString());
      }
    } catch (e) {
      print('Erreur scan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du scan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _generateBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000;
    final supplierId = widget.product?.supplierId ??
        Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 1;
    final supplierCode = supplierId.toString().padLeft(5, '0');
    final productCode = random.toString().padLeft(4, '0');
    final baseCode = '590$supplierCode$productCode';
    final checksum = _calculateEAN13Checksum(baseCode);
    final barcode = '$baseCode$checksum';

    setState(() {
      _barcodeController.text = barcode;
      _barcodeExists = null;
    });
    _checkBarcodeUniqueness(barcode);
  }

  int _calculateEAN13Checksum(String code) {
    if (code.length != 12) return 0;
    int sum = 0;
    for (int i = 0; i < code.length; i++) {
      int digit = int.parse(code[i]);
      if (i % 2 == 0) {
        sum += digit * 1;
      } else {
        sum += digit * 3;
      }
    }
    return (10 - (sum % 10)) % 10;
  }

  bool _validateEAN13(String barcode) {
    if (barcode.length != 13) return true;
    final code = barcode.substring(0, 12);
    final providedChecksum = int.parse(barcode[12]);
    final calculatedChecksum = _calculateEAN13Checksum(code);
    return providedChecksum == calculatedChecksum;
  }

  Future<void> _checkBarcodeUniqueness(String barcode) async {
    if (barcode.length != 13) return;
    if (!_validateEAN13(barcode)) return;

    _barcodeDebounceTimer?.cancel();
    _barcodeDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      try {
        final response = await http.get(
          Uri.parse('${AppConstants.baseUrl}/products/check-barcode/$barcode'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        final data = json.decode(response.body);

        if (mounted) {
          setState(() {
            if (widget.product != null && data['product_id'] == widget.product!.id) {
              _barcodeExists = false;
            } else if (data['exists'] && data['supplier_id'] == widget.product?.supplierId) {
              _barcodeExists = true;
            } else {
              _barcodeExists = false;
            }
          });
        }
      } catch (e) {
        print('Erreur vérification code-barres: $e');
      }
    });
  }

  // 👉 NOUVELLE MÉTHODE: Sélectionner plusieurs images
  Future<void> _showImageSourceBottomSheet() async {
    final localizations = AppLocalizations.of(context)!;

    final result = await showModalBottomSheet<int>(
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
                onTap: () => Navigator.pop(context, 0),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text(localizations.chooseFromGallery),
                onTap: () => Navigator.pop(context, 1),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: Text(localizations.cancel),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        );
      },
    );

    if (result == 0) {
      await _checkPermissionAndPickImages(ImageSource.camera);
    } else if (result == 1) {
      await _checkPermissionAndPickImages(ImageSource.gallery);
    }
  }

  // 👉 NOUVELLE MÉTHODE: Sélectionner plusieurs images
  Future<void> _checkPermissionAndPickImages(ImageSource source) async {
    final localizations = AppLocalizations.of(context)!;

    if (source == ImageSource.camera) {
      if (await Permission.camera.request().isGranted) {
        await _pickMultipleImages(source);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.cameraPermissionDenied),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } else {
      bool granted = false;
      if (Platform.isAndroid) {
        if (await Permission.storage.request().isGranted) {
          granted = true;
        } else if (await Permission.photos.request().isGranted) {
          granted = true;
        }
      } else {
        granted = await Permission.photos.request().isGranted;
      }
      if (granted) {
        await _pickMultipleImages(source);
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

  // 👉 NOUVELLE MÉTHODE: Choisir plusieurs images
  Future<void> _pickMultipleImages(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        // Pour la caméra, on ne peut prendre qu'une photo à la fois
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          setState(() {
            _imageFiles.add(File(pickedFile.path));
          });
        }
      } else {
        // Pour la galerie, on peut sélectionner plusieurs images
        final List<XFile> pickedFiles = await picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (pickedFiles.isNotEmpty) {
          setState(() {
            _imageFiles.addAll(pickedFiles.map((xfile) => File(xfile.path)));
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // 👉 NOUVELLE MÉTHODE: Supprimer une image de la liste
  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
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

  // 👉 NOUVELLE MÉTHODE: Uploader plusieurs images
  Future<void> _uploadMultipleImages(int productId) async {
    if (_imageFiles.isEmpty) return;

    final productService = Provider.of<ProductService>(context, listen: false);

    for (int i = 0; i < _imageFiles.length; i++) {
      final result = await productService.uploadProductImage(productId, _imageFiles[i]);
      if (result['success'] && mounted) {
        print('✅ Image ${i + 1} téléchargée avec succès');
      } else {
        print('❌ Erreur image ${i + 1}: ${result['message']}');
      }
    }

    await productService.loadSupplierProducts(reset: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_imageFiles.length} image(s) téléchargée(s) avec succès'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Map<String, dynamic> _getStockStatus() {
    int stock = int.tryParse(_stockQuantityController.text) ?? 0;
    int minAlert = int.tryParse(_minStockAlertController.text) ?? 5;

    if (stock <= 0) {
      return {
        'color': Colors.red,
        'icon': Icons.error,
        'status': 'Rupture de stock',
        'message': 'Plus en stock'
      };
    } else if (stock <= minAlert) {
      return {
        'color': Colors.orange,
        'icon': Icons.warning,
        'status': 'Stock faible',
        'message': 'Bientôt épuisé'
      };
    } else {
      return {
        'color': Colors.green,
        'icon': Icons.check_circle,
        'status': 'Stock suffisant',
        'message': 'Disponible'
      };
    }
  }

  Future<void> _saveProduct() async {
    final localizations = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    int stockQuantity = int.tryParse(_stockQuantityController.text) ?? 0;
    int minStockAlert = int.tryParse(_minStockAlertController.text) ?? 5;
    int maxStockAlert = int.tryParse(_maxStockAlertController.text) ?? 100;
    int defaultPackagingQuantity = int.tryParse(_defaultPackagingQuantityController.text) ?? 1;
    double? unitWeight = _unitWeightController.text.isNotEmpty ? double.tryParse(_unitWeightController.text) : null;
    double? unitVolume = _unitVolumeController.text.isNotEmpty ? double.tryParse(_unitVolumeController.text) : null;

    final productData = {
      'name': _nameController.text,
      'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
      'list_price': double.parse(_priceController.text),
      'packaging': _packagingController.text.isEmpty ? null : _packagingController.text,
      'is_promotion': _isPromotion ? 1 : 0,
      'categ_id': _selectedCategoryId,
      'default_code': _codeController.text.isEmpty ? null : _codeController.text,
      'barcode': _barcodeController.text.isEmpty ? null : _barcodeController.text,
      'stock_quantity': stockQuantity,
      'min_stock_alert': minStockAlert,
      'max_stock_alert': maxStockAlert,
      'base_unit': _baseUnitController.text,
      'default_packaging_quantity': defaultPackagingQuantity,
      'unit_weight': unitWeight,
      'unit_volume': unitVolume,
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
      if (result['success'] && _imageFiles.isNotEmpty && mounted) {
        final newProductId = result['product'].id;
        await _uploadMultipleImages(newProductId);
      }
    } else {
      result = await productService.updateProduct(widget.product!.id, productData);
      if (result['success'] && _imageFiles.isNotEmpty && mounted) {
        await _uploadMultipleImages(widget.product!.id);
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
            icon: Icon(
              isArabic ? Icons.arrow_forward : Icons.arrow_back,
              color: AppColors.textDark,
            ),
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
                // Nom du produit
                _buildLabel('${localizations.products} *'),
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
                _buildLabel(localizations.description),
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
                _buildLabel('${localizations.category} *'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Consumer<ProductService>(
                        builder: (context, productService, child) {
                          if (productService.isLoading) {
                            return const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

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
                _buildLabel(localizations.price),
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

                // Conditionnement simple
                _buildLabel(localizations.packaging),
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

                // Section Conditionnements avancés
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Conditionnements avancés',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Unité de base'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _baseUnitController.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'piece', child: Text('Pièce')),
                          DropdownMenuItem(value: 'kg', child: Text('Kilogramme (kg)')),
                          DropdownMenuItem(value: 'g', child: Text('Gramme (g)')),
                          DropdownMenuItem(value: 'liter', child: Text('Litre (L)')),
                          DropdownMenuItem(value: 'ml', child: Text('Millilitre (ml)')),
                        ],
                        onChanged: (value) => setState(() => _baseUnitController.text = value!),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Quantité par défaut (pièces)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _defaultPackagingQuantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '1',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                          helperText: 'Nombre d\'unités dans le conditionnement standard',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Poids unitaire (optionnel)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _unitWeightController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ex: 0.500',
                          prefixIcon: const Icon(Icons.fitness_center, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                          suffixText: _baseUnitController.text == 'kg' ? 'kg' :
                          (_baseUnitController.text == 'g' ? 'g' : 'kg'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Volume unitaire (optionnel)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _unitVolumeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Ex: 1.5',
                          prefixIcon: const Icon(Icons.photo_size_select_small, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                          suffixText: _baseUnitController.text == 'liter' ? 'L' :
                          (_baseUnitController.text == 'ml' ? 'ml' : 'L'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vous pourrez ajouter plusieurs conditionnements (carton, palette, pack) après la création du produit.',
                                style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Code-barres
                _buildLabel('Code-barres'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Entrez le code-barres',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^\d+$').hasMatch(value)) {
                              return 'Le code-barres ne doit contenir que des chiffres';
                            }
                            if (value.length == 13 && !_validateEAN13(value)) {
                              return 'Code-barres EAN-13 invalide';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _checkBarcodeUniqueness(value);
                          } else {
                            setState(() {
                              _barcodeExists = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Scanner un code-barres',
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                          onPressed: _scanBarcode,
                          iconSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Générer automatiquement (EAN-13)',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.auto_awesome, color: Colors.green),
                          onPressed: _generateBarcode,
                          iconSize: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_barcodeExists != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Row(
                      children: [
                        Icon(
                          _barcodeExists == true ? Icons.warning : Icons.check_circle,
                          size: 14,
                          color: _barcodeExists == true ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _barcodeExists == true
                              ? 'Ce code-barres est déjà utilisé par un autre produit'
                              : 'Code-barres disponible',
                          style: TextStyle(
                            fontSize: 11,
                            color: _barcodeExists == true ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // SECTION STOCK
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Gestion de stock',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Quantité en stock *'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _stockQuantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixIcon: const Icon(Icons.inventory_2, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La quantité en stock est requise';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Veuillez entrer un nombre valide';
                          }
                          if (int.parse(value) < 0) {
                            return 'La quantité ne peut pas être négative';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Seuil d\'alerte minimum'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _minStockAlertController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '5',
                          prefixIcon: const Icon(Icons.warning, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          helperText: 'En dessous de ce seuil, une alerte sera affichée',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Stock maximum'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _maxStockAlertController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '100',
                          prefixIcon: const Icon(Icons.trending_up, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          helperText: 'Quantité maximale recommandée',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProductService>(
                        builder: (context, productService, child) {
                          final stockStatus = _getStockStatus();
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: stockStatus['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: stockStatus['color'].withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  stockStatus['icon'],
                                  color: stockStatus['color'],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stockStatus['status'],
                                        style: TextStyle(
                                          color: stockStatus['color'],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        stockStatus['message'],
                                        style: TextStyle(
                                          color: stockStatus['color'].withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${_stockQuantityController.text} en stock',
                                  style: TextStyle(
                                    color: stockStatus['color'],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                  _buildLabel(localizations.promotionPrice),
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
                  _buildLabel(localizations.promotionStart),
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
                  _buildLabel(localizations.promotionEnd),
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

                // 👉 SECTION IMAGES MULTIPLES POUR NOUVEAU PRODUIT
                if (widget.product == null)
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Images du produit (${_imageFiles.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3A4F),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showImageSourceBottomSheet,
                              icon: const Icon(Icons.add_photo_alternate, size: 18),
                              label: const Text('Ajouter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_imageFiles.isEmpty)
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
                                  'Aucune image sélectionnée',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ajoutez une ou plusieurs images pour votre produit',
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
                            itemCount: _imageFiles.length,
                            itemBuilder: (context, index) {
                              final imageFile = _imageFiles[index];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      imageFile,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (index == 0)
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
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 16),
                                        color: Colors.white,
                                        onPressed: () => _removeImage(index),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'La première image sera automatiquement définie comme image principale.',
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Section Images Multiples pour modification
                if (widget.product != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ProductImageGallery(
                      productId: widget.product!.id,
                      initialImages: widget.product!.images,
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2D3A4F),
      ),
    );
  }
}