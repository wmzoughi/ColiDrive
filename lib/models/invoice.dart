// lib/models/invoice.dart

class Invoice {
  final int id;
  final String invoiceNumber;
  final int orderId;
  final String customerName;
  final String? customerCompany;
  final double total;
  final String formattedTotal;
  final String status;
  final String invoiceDate;
  final DateTime invoiceDateRaw;
  final String? pdfUrl;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.customerName,
    this.customerCompany,
    required this.total,
    required this.formattedTotal,
    required this.status,
    required this.invoiceDate,
    required this.invoiceDateRaw,
    this.pdfUrl,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      orderId: json['order_id'],
      customerName: json['customer_name'],
      customerCompany: json['customer_company'],
      total: json['total'].toDouble(),
      formattedTotal: json['formatted_total'],
      status: json['status'],
      invoiceDate: json['invoice_date'],
      invoiceDateRaw: DateTime.parse(json['invoice_date_raw']),
      pdfUrl: json['pdf_url'],
    );
  }
}

class InvoiceDetail {
  final int id;
  final String invoiceNumber;
  final int orderId;
  final Map<String, dynamic> customer;
  final double subtotal;
  final String formattedSubtotal;
  final double tax;
  final String formattedTax;
  final double shippingCost;
  final String formattedShipping;
  final double total;
  final String formattedTotal;
  final List<dynamic> items;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String invoiceDate;
  final String? dueDate;
  final String? pdfUrl;
  final String createdAt;

  InvoiceDetail({
    required this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.customer,
    required this.subtotal,
    required this.formattedSubtotal,
    required this.tax,
    required this.formattedTax,
    required this.shippingCost,
    required this.formattedShipping,
    required this.total,
    required this.formattedTotal,
    required this.items,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.invoiceDate,
    this.dueDate,
    this.pdfUrl,
    required this.createdAt,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    return InvoiceDetail(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      orderId: json['order_id'],
      customer: json['customer'],
      subtotal: json['subtotal'].toDouble(),
      formattedSubtotal: json['formatted_subtotal'],
      tax: json['tax'].toDouble(),
      formattedTax: json['formatted_tax'],
      shippingCost: json['shipping_cost'].toDouble(),
      formattedShipping: json['formatted_shipping'],
      total: json['total'].toDouble(),
      formattedTotal: json['formatted_total'],
      items: json['items'] ?? [],
      status: json['status'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      invoiceDate: json['invoice_date'],
      dueDate: json['due_date'],
      pdfUrl: json['pdf_url'],
      createdAt: json['created_at'],
    );
  }
}

class InvoiceResponse {
  final List<Invoice> invoices;
  final PaginationInfo pagination;

  InvoiceResponse({
    required this.invoices,
    required this.pagination,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceResponse(
      invoices: (json['invoices'] as List)
          .map((i) => Invoice.fromJson(i))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationInfo({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }
}