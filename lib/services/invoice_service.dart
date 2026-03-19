// lib/services/invoice_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../utils/constants.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceService extends ChangeNotifier {
  final AuthService _authService;

  List<Invoice> _invoices = [];
  InvoiceDetail? _currentInvoice;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // 👇 NOUVEAU : Pour le badge de notification
  int _newInvoicesCount = 0;
  DateTime? _lastViewedAt;

  List<Invoice> get invoices => List.unmodifiable(_invoices);
  InvoiceDetail? get currentInvoice => _currentInvoice;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // 👇 NOUVEAU : Getter pour le badge
  int get newInvoicesCount => _newInvoicesCount;
  bool get hasNewInvoices => _newInvoicesCount > 0;

  InvoiceService(this._authService) {
    _loadLastViewed();
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authService.token != null) 'Authorization': 'Bearer ${_authService.token}',
  };

  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  // 👇 NOUVEAU : Charger la dernière date de consultation
  Future<void> _loadLastViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('invoices_last_viewed');
    if (saved != null) {
      _lastViewedAt = DateTime.parse(saved);
    }
  }

  // 👇 NOUVEAU : Sauvegarder la date de consultation
  Future<void> _saveLastViewed() async {
    _lastViewedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invoices_last_viewed', _lastViewedAt!.toIso8601String());
  }

  // 👇 NOUVEAU : Calculer les nouvelles factures
  void _updateNewInvoicesCount() {
    if (_lastViewedAt == null) {
      _newInvoicesCount = _invoices.length;
    } else {
      _newInvoicesCount = _invoices
          .where((inv) => inv.invoiceDateRaw.isAfter(_lastViewedAt!))
          .length;
    }
    _safeNotify();
  }

  // 👇 MODIFIÉ : Marquer comme consulté
  Future<void> markInvoicesAsViewed() async {
    await _saveLastViewed();
    _newInvoicesCount = 0;
    _safeNotify();
  }

  // Charger la liste des factures (MODIFIÉ)
  Future<bool> loadInvoices({bool reset = false}) async {
    if (reset) {
      _invoices = [];
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return false;

    _isLoading = true;
    _safeNotify();

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/invoices?page=$_currentPage'),
        headers: _headers,
      );

      print('📥 Factures - Statut: ${response.statusCode}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final responseData = InvoiceResponse.fromJson(data['data']);

        _invoices.addAll(responseData.invoices);
        _currentPage++;
        _hasMore = _currentPage <= responseData.pagination.lastPage;

        // ✅ Mettre à jour le compteur de nouvelles factures
        _updateNewInvoicesCount();

        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _error = data['message'] ?? 'Erreur';
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } catch (e) {
      _error = 'Erreur réseau: ${e.toString()}';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  // Charger le détail d'une facture
  Future<bool> loadInvoiceDetail(int invoiceId) async {
    _isLoading = true;
    _safeNotify();

    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/invoices/$invoiceId'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _currentInvoice = InvoiceDetail.fromJson(data['data']);
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _error = data['message'] ?? 'Erreur';
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } catch (e) {
      _error = 'Erreur réseau: ${e.toString()}';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  // Télécharger le PDF
  Future<String?> downloadPdf(int invoiceId) async {
    try {
      print('📥 Téléchargement PDF facture: $invoiceId');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/invoices/$invoiceId/download'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
          'Accept': 'application/pdf',
        },
      );

      if (response.statusCode == 200) {
        // Pour Android, essaie de sauvegarder dans Downloads
        Directory? downloadsDir;

        if (Platform.isAndroid) {
          // Essayer d'obtenir le dossier Téléchargements
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!await downloadsDir.exists()) {
            // Fallback sur le dossier documents
            downloadsDir = await getApplicationDocumentsDirectory();
          }
        } else {
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        final file = File('${downloadsDir.path}/facture_$invoiceId.pdf');
        await file.writeAsBytes(response.bodyBytes);

        print('✅ PDF sauvegardé: ${file.path}');
        return file.path;
      }
      return null;
    } catch (e) {
      print('❌ Erreur téléchargement: $e');
      return null;
    }
  }

  // Partager le PDF
  Future<bool> sharePdf(int invoiceId) async {
    try {
      final filePath = await downloadPdf(invoiceId);
      if (filePath != null) {
        await Share.shareXFiles([XFile(filePath)], text: 'Facture');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Voir le PDF dans une nouvelle vue
  Future<String?> getPdfUrl(int invoiceId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/invoices/$invoiceId/view'),
        headers: {
          'Authorization': 'Bearer ${_authService.token}',
        },
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/invoice_view_$invoiceId.pdf');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Rafraîchir la liste
  Future<void> refresh() async {
    await loadInvoices(reset: true);
  }

  // Obtenir la dernière facture
  Future<Map<String, dynamic>?> getLatestInvoice() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/invoices/latest'),
        headers: _headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}