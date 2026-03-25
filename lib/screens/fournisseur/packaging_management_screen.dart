// lib/screens/fournisseur/packaging_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';

class PackagingManagementScreen extends StatefulWidget {
  final Product product;

  const PackagingManagementScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<PackagingManagementScreen> createState() => _PackagingManagementScreenState();
}

class _PackagingManagementScreenState extends State<PackagingManagementScreen> {
  List<Map<String, dynamic>> _packagings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackagings();
  }

  Future<void> _loadPackagings() async {
    setState(() => _isLoading = true);

    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      final packagings = await productService.getProductPackagings(widget.product.id);
      setState(() {
        _packagings = packagings.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addPackaging() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PackagingFormDialog(product: widget.product),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);

      final productService = Provider.of<ProductService>(context, listen: false);
      final response = await productService.addPackaging(widget.product.id, result);

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conditionnement ajouté'), backgroundColor: AppColors.success),
        );
        await _loadPackagings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['errors']?['general']?[0] ?? 'Erreur'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editPackaging(Map<String, dynamic> packaging) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PackagingFormDialog(
        product: widget.product,
        packaging: packaging,
      ),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);

      final productService = Provider.of<ProductService>(context, listen: false);
      final response = await productService.updatePackaging(
        widget.product.id,
        packaging['id'],
        result,
      );

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conditionnement modifié'), backgroundColor: AppColors.success),
        );
        await _loadPackagings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['errors']?['general']?[0] ?? 'Erreur'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletePackaging(int packagingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer ce conditionnement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);

      final productService = Provider.of<ProductService>(context, listen: false);
      final success = await productService.deletePackaging(widget.product.id, packagingId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conditionnement supprimé'), backgroundColor: AppColors.success),
        );
        await _loadPackagings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression'), backgroundColor: AppColors.error),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _getPackagingIcon(String type) {
    IconData icon;
    switch (type) {
      case 'box':
        icon = Icons.inbox;
        break;
      case 'pallet':
        icon = Icons.pallet;
        break;
      case 'pack':
        icon = Icons.inventory_2;
        break;
      case 'carton':
        icon = Icons.article;
        break;
      case 'bag':
        icon = Icons.shopping_bag;
        break;
      case 'bottle':
        icon = Icons.wine_bar;
        break;
      default:
        icon = Icons.inventory_2;
    }
    return Icon(icon, color: AppColors.primary, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text('Conditionnements - ${widget.product.name}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Informations de base
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Informations de base',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Unité de base', widget.product.baseUnit ?? 'Pièce'),
                _buildInfoRow('Quantité par défaut', '${widget.product.defaultPackagingQuantity ?? 1} pièces'),
                if (widget.product.unitWeight != null)
                  _buildInfoRow('Poids unitaire', '${widget.product.unitWeight} kg'),
                if (widget.product.unitVolume != null)
                  _buildInfoRow('Volume unitaire', '${widget.product.unitVolume} L'),
              ],
            ),
          ),

          // Liste des conditionnements
          Expanded(
            child: _packagings.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun conditionnement',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des conditionnements comme "Carton", "Palette", etc.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addPackaging,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un conditionnement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _packagings.length,
              itemBuilder: (context, index) {
                final p = _packagings[index];
                return _buildPackagingCard(p);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _packagings.isNotEmpty
          ? FloatingActionButton(
        onPressed: _addPackaging,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text('$label :', style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPackagingCard(Map<String, dynamic> packaging) {
    final isDefault = packaging['is_default'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _getPackagingIcon(packaging['type']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        packaging['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Par défaut',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${packaging['quantity']} pièces',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (packaging['price'] != null)
                    Text(
                      '${(packaging['price'] as num).toStringAsFixed(2)} MAD',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editPackaging(packaging),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePackaging(packaging['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Formulaire d'ajout/modification
class _PackagingFormDialog extends StatefulWidget {
  final Product product;
  final Map<String, dynamic>? packaging;

  const _PackagingFormDialog({required this.product, this.packaging});

  @override
  State<_PackagingFormDialog> createState() => _PackagingFormDialogState();
}

class _PackagingFormDialogState extends State<_PackagingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _barcodeController;
  String _selectedType = 'box';
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.packaging?['name']);
    _quantityController = TextEditingController(text: (widget.packaging?['quantity'] ?? 1).toString());
    _priceController = TextEditingController(text: widget.packaging?['price']?.toString());
    _barcodeController = TextEditingController(text: widget.packaging?['barcode']);
    _selectedType = widget.packaging?['type'] ?? 'box';
    _isDefault = widget.packaging?['is_default'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.packaging == null ? 'Ajouter un conditionnement' : 'Modifier le conditionnement'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  hintText: 'Ex: Carton, Palette, Pack',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'box', child: Text('Boîte')),
                  DropdownMenuItem(value: 'carton', child: Text('Carton')),
                  DropdownMenuItem(value: 'pallet', child: Text('Palette')),
                  DropdownMenuItem(value: 'pack', child: Text('Pack')),
                  DropdownMenuItem(value: 'bag', child: Text('Sac')),
                  DropdownMenuItem(value: 'bottle', child: Text('Bouteille')),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantité (pièces)',
                  hintText: 'Nombre d\'unités dans ce conditionnement',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Requis';
                  if (int.tryParse(v!) == null) return 'Nombre valide requis';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix (optionnel)',
                  hintText: 'Laisser vide pour utiliser le prix unitaire',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Code-barres (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Conditionnement par défaut'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(widget.packaging == null ? 'Ajouter' : 'Modifier'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text,
        'type': _selectedType,
        'quantity': int.parse(_quantityController.text),
        'price': _priceController.text.isNotEmpty ? double.parse(_priceController.text) : null,
        'barcode': _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
        'is_default': _isDefault,
      });
    }
  }
}