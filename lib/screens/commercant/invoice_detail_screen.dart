// lib/screens/commercant/invoice_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/invoice_service.dart';
import '../../utils/constants.dart';
import '../../l10n/app_localizations.dart';
import 'package:open_file/open_file.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({
    Key? key,
    required this.invoiceId,
  }) : super(key: key);

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  bool _isLoading = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    final service = Provider.of<InvoiceService>(context, listen: false);
    await service.loadInvoiceDetail(widget.invoiceId);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    final localizations = AppLocalizations.of(context)!;

    setState(() => _isDownloading = true);

    try {
      final service = Provider.of<InvoiceService>(context, listen: false);
      final filePath = await service.downloadPdf(widget.invoiceId);

      if (mounted) {
        if (filePath != null) {
          // Afficher une snackbar avec le chemin et un bouton pour ouvrir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ ${localizations.pdfDownloadSuccess}'),
                  const SizedBox(height: 4),
                  Text(
                    '${localizations.path}: $filePath',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: localizations.open,
                textColor: Colors.white,
                onPressed: () {
                  _openPdf(filePath);
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.pdfDownloadError),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _openPdf(String path) {
    OpenFile.open(path);
  }

  Future<void> _sharePdf() async {
    if (_isDownloading) return;
    final localizations = AppLocalizations.of(context)!;

    setState(() => _isDownloading = true);

    try {
      final service = Provider.of<InvoiceService>(context, listen: false);
      final success = await service.sharePdf(widget.invoiceId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.pdfReadyToShare),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.pdfShareError),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.error}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _getPaymentStatusText(String status, AppLocalizations localizations) {
    return status == 'paid' ? localizations.invoice_paid : localizations.invoice_pending;
  }

  Color _getPaymentStatusColor(String status) {
    return status == 'paid' ? Colors.green : Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<InvoiceService>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          localizations.invoice_details,
          style: const TextStyle(
            color: Color(0xFF2D3A4F),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3A4F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.download, color: AppColors.primary),
            onPressed: _isDownloading ? null : _downloadPdf,
          ),
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.share, color: AppColors.primary),
            onPressed: _isDownloading ? null : _sharePdf,
          ),
        ],
      ),
      body: _isLoading || service.currentInvoice == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête facture
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                      Text(
                        service.currentInvoice!.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentStatusColor(service.currentInvoice!.paymentStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getPaymentStatusText(service.currentInvoice!.paymentStatus, localizations),
                          style: TextStyle(
                            color: _getPaymentStatusColor(service.currentInvoice!.paymentStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.invoice_date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.currentInvoice!.invoiceDate,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            localizations.invoice_total,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.currentInvoice!.formattedTotal,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informations client
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Row(
                    children: [
                      Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        localizations.invoice_customer,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    service.currentInvoice!.customer['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (service.currentInvoice!.customer['company'] != null)
                    Text(service.currentInvoice!.customer['company']),
                  Text(service.currentInvoice!.customer['email']),
                  if (service.currentInvoice!.customer['phone'] != null)
                    Text(service.currentInvoice!.customer['phone']),
                  if (service.currentInvoice!.customer['address'] != null) ...[
                    const SizedBox(height: 8),
                    Text(service.currentInvoice!.customer['address']),
                    Text('${service.currentInvoice!.customer['city']} ${service.currentInvoice!.customer['zip']}'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Liste des articles
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        localizations.invoice_items,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // En-tête tableau
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            localizations.product,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            localizations.invoice_quantity,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            localizations.invoice_price,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            localizations.invoice_total,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Liste des articles
                  ...service.currentInvoice!.items.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'],
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                if (item['sku'] != null && item['sku'] != 'N/A')
                                  Text(
                                    '${localizations.reference}: ${item['sku']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item['quantity']}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item['price']} ${localizations.currency}',
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item['subtotal']} ${localizations.currency}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Totaux
                  Container(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localizations.invoice_subtotal),
                            Text(service.currentInvoice!.formattedSubtotal),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localizations.invoice_tax),
                            Text(service.currentInvoice!.formattedTax),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localizations.invoice_shipping),
                            Text(service.currentInvoice!.formattedShipping),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              localizations.invoice_grand_total,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              service.currentInvoice!.formattedTotal,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _downloadPdf,
                    icon: _isDownloading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.download),
                    label: Text(localizations.download_pdf),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _sharePdf,
                    icon: _isDownloading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.share),
                    label: Text(localizations.share_pdf),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}