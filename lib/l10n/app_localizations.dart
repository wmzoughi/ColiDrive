import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'ColiDrive'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get hello;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'SE CONNECTER'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In fr, this message translates to:
  /// **'CRÉER UN COMPTE'**
  String get registerButton;

  /// No description provided for @or.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get or;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher...'**
  String get search;

  /// No description provided for @globalBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde global'**
  String get globalBalance;

  /// No description provided for @seeBalance.
  ///
  /// In fr, this message translates to:
  /// **'Voir le solde'**
  String get seeBalance;

  /// No description provided for @minimumThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil minimum'**
  String get minimumThreshold;

  /// No description provided for @promotions.
  ///
  /// In fr, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @seePromos.
  ///
  /// In fr, this message translates to:
  /// **'Voir les promos'**
  String get seePromos;

  /// No description provided for @mostOrderedProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits les plus commandés'**
  String get mostOrderedProducts;

  /// No description provided for @recentOrders.
  ///
  /// In fr, this message translates to:
  /// **'Dernières commandes'**
  String get recentOrders;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @paid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In fr, this message translates to:
  /// **'Impayée'**
  String get unpaid;

  /// No description provided for @myAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon Compte'**
  String get myAccount;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @company.
  ///
  /// In fr, this message translates to:
  /// **'Entreprise'**
  String get company;

  /// No description provided for @companyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'entreprise'**
  String get companyName;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @stats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get stats;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'SE DÉCONNECTER'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @totalOrders.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de commandes'**
  String get totalOrders;

  /// No description provided for @pendingOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes en attente'**
  String get pendingOrders;

  /// No description provided for @totalSales.
  ///
  /// In fr, this message translates to:
  /// **'Total ventes'**
  String get totalSales;

  /// No description provided for @outOfStockProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits en rupture'**
  String get outOfStockProducts;

  /// No description provided for @salesStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques des Ventes'**
  String get salesStats;

  /// No description provided for @recentTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions récentes'**
  String get recentTransactions;

  /// No description provided for @noTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transaction récente'**
  String get noTransactions;

  /// No description provided for @noProducts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit trouvé'**
  String get noProducts;

  /// No description provided for @noOrders.
  ///
  /// In fr, this message translates to:
  /// **'Aucune commande récente'**
  String get noOrders;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @inPromotion.
  ///
  /// In fr, this message translates to:
  /// **'En promo'**
  String get inPromotion;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre e-mail'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe'**
  String get passwordHint;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get passwordRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalidEmail;

  /// No description provided for @pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pending;

  /// No description provided for @delivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrée'**
  String get delivered;

  /// No description provided for @products.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get products;

  /// No description provided for @orders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes'**
  String get orders;

  /// No description provided for @min.
  ///
  /// In fr, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'MAD'**
  String get currency;

  /// No description provided for @packaging.
  ///
  /// In fr, this message translates to:
  /// **'Conditionnement'**
  String get packaging;

  /// No description provided for @promotionStart.
  ///
  /// In fr, this message translates to:
  /// **'Date début promotion'**
  String get promotionStart;

  /// No description provided for @promotionEnd.
  ///
  /// In fr, this message translates to:
  /// **'Date fin promotion'**
  String get promotionEnd;

  /// No description provided for @image.
  ///
  /// In fr, this message translates to:
  /// **'Image du produit'**
  String get image;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis la galerie'**
  String get chooseFromGallery;

  /// No description provided for @sortBestSelling.
  ///
  /// In fr, this message translates to:
  /// **'Le plus vendu'**
  String get sortBestSelling;

  /// No description provided for @sortPriceAsc.
  ///
  /// In fr, this message translates to:
  /// **'Prix croissant'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In fr, this message translates to:
  /// **'Prix décroissant'**
  String get sortPriceDesc;

  /// No description provided for @sortNewest.
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés'**
  String get sortNewest;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filterAll;

  /// No description provided for @filterPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get filterPending;

  /// No description provided for @filterConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmées'**
  String get filterConfirmed;

  /// No description provided for @filterDelivered.
  ///
  /// In fr, this message translates to:
  /// **'Livrées'**
  String get filterDelivered;

  /// No description provided for @timeAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a'**
  String get timeAgo;

  /// No description provided for @days.
  ///
  /// In fr, this message translates to:
  /// **'jour(s)'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In fr, this message translates to:
  /// **'heure(s)'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In fr, this message translates to:
  /// **'minute(s)'**
  String get minutes;

  /// No description provided for @addProduct.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un produit'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le produit'**
  String get editProduct;

  /// No description provided for @productCode.
  ///
  /// In fr, this message translates to:
  /// **'Code produit'**
  String get productCode;

  /// No description provided for @productCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: CAFE001'**
  String get productCodeHint;

  /// No description provided for @productNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Café Arabica'**
  String get productNameHint;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Description du produit'**
  String get descriptionHint;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une catégorie'**
  String get selectCategory;

  /// No description provided for @addCategory.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une catégorie'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie'**
  String get categoryName;

  /// No description provided for @categoryAdded.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie ajoutée avec succès'**
  String get categoryAdded;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente'**
  String get price;

  /// No description provided for @packagingHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Boîte de 100g'**
  String get packagingHint;

  /// No description provided for @promotionPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix promotionnel'**
  String get promotionPrice;

  /// No description provided for @dateFormat.
  ///
  /// In fr, this message translates to:
  /// **'YYYY-MM-DD'**
  String get dateFormat;

  /// No description provided for @productImage.
  ///
  /// In fr, this message translates to:
  /// **'Image du produit'**
  String get productImage;

  /// No description provided for @selectedImage.
  ///
  /// In fr, this message translates to:
  /// **'Image sélectionnée'**
  String get selectedImage;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est requis'**
  String get fieldRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Nombre invalide'**
  String get invalidNumber;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @productAdded.
  ///
  /// In fr, this message translates to:
  /// **'Produit ajouté avec succès'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Produit modifié avec succès'**
  String get productUpdated;

  /// No description provided for @imageUploaded.
  ///
  /// In fr, this message translates to:
  /// **'Image téléchargée avec succès'**
  String get imageUploaded;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission caméra refusée'**
  String get cameraPermissionDenied;

  /// No description provided for @galleryPermissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission galerie refusée'**
  String get galleryPermissionDenied;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @errorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorOccurred;

  /// No description provided for @cart.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get cart;

  /// No description provided for @checkoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Finaliser la commande'**
  String get checkoutTitle;

  /// No description provided for @orderSummary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif de votre commande'**
  String get orderSummary;

  /// No description provided for @itemsCount.
  ///
  /// In fr, this message translates to:
  /// **'article(s)'**
  String get itemsCount;

  /// No description provided for @subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In fr, this message translates to:
  /// **'TVA (20%)'**
  String get tax;

  /// No description provided for @shipping.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get shipping;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @shippingAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get shippingAddress;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @addressHint.
  ///
  /// In fr, this message translates to:
  /// **'Numéro et nom de rue'**
  String get addressHint;

  /// No description provided for @city.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get city;

  /// No description provided for @zipCode.
  ///
  /// In fr, this message translates to:
  /// **'Code postal'**
  String get zipCode;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMethod;

  /// No description provided for @cashOnDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Paiement à la livraison (Espèces)'**
  String get cashOnDelivery;

  /// No description provided for @cashSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Payez en espèces à la réception'**
  String get cashSubtitle;

  /// No description provided for @cardPayment.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get cardPayment;

  /// No description provided for @cardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Payez par carte (CIB, MasterCard, Visa)'**
  String get cardSubtitle;

  /// No description provided for @notes.
  ///
  /// In fr, this message translates to:
  /// **'Notes (optionnel)'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In fr, this message translates to:
  /// **'Instructions spéciales pour la livraison...'**
  String get notesHint;

  /// No description provided for @confirmOrder.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la commande'**
  String get confirmOrder;

  /// No description provided for @termsAccept.
  ///
  /// In fr, this message translates to:
  /// **'En confirmant votre commande, vous acceptez nos conditions générales de vente.'**
  String get termsAccept;

  /// No description provided for @orderSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Commande créée avec succès! Numéro: '**
  String get orderSuccess;

  /// No description provided for @orderError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création de la commande'**
  String get orderError;

  /// No description provided for @addressRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse est requise'**
  String get addressRequired;

  /// No description provided for @cityRequired.
  ///
  /// In fr, this message translates to:
  /// **'La ville est requise'**
  String get cityRequired;

  /// No description provided for @zipRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le code postal est requis'**
  String get zipRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de téléphone est requis'**
  String get phoneRequired;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantity;

  /// No description provided for @addToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get addToCart;

  /// No description provided for @confirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmée'**
  String get confirmed;

  /// No description provided for @preparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get preparing;

  /// No description provided for @delivering.
  ///
  /// In fr, this message translates to:
  /// **'En livraison'**
  String get delivering;

  /// No description provided for @cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulée'**
  String get cancelled;

  /// No description provided for @filterPreparing.
  ///
  /// In fr, this message translates to:
  /// **'En préparation'**
  String get filterPreparing;

  /// No description provided for @filterDelivering.
  ///
  /// In fr, this message translates to:
  /// **'En livraison'**
  String get filterDelivering;

  /// No description provided for @supplierOrders.
  ///
  /// In fr, this message translates to:
  /// **'Commandes fournisseur'**
  String get supplierOrders;

  /// No description provided for @client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @totalRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires'**
  String get totalRevenue;

  /// No description provided for @moreProducts.
  ///
  /// In fr, this message translates to:
  /// **'autre(s) produit(s)'**
  String get moreProducts;

  /// No description provided for @confirmOrderMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous confirmer la commande'**
  String get confirmOrderMessage;

  /// No description provided for @orderConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Commande confirmée avec succès'**
  String get orderConfirmed;

  /// No description provided for @cancelOrder.
  ///
  /// In fr, this message translates to:
  /// **'Annuler la commande'**
  String get cancelOrder;

  /// No description provided for @orderCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Commande annulée'**
  String get orderCancelled;

  /// No description provided for @cancellationReason.
  ///
  /// In fr, this message translates to:
  /// **'Raison d\'annulation'**
  String get cancellationReason;

  /// No description provided for @cancellationReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Produit en rupture de stock'**
  String get cancellationReasonHint;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @updateStatus.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour le statut'**
  String get updateStatus;

  /// No description provided for @updateStatusMessage.
  ///
  /// In fr, this message translates to:
  /// **'Marquer la commande comme'**
  String get updateStatusMessage;

  /// No description provided for @order.
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get order;

  /// No description provided for @filterCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulées'**
  String get filterCancelled;

  /// No description provided for @stockManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion de stock'**
  String get stockManagement;

  /// No description provided for @stockQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité en stock'**
  String get stockQuantity;

  /// No description provided for @minStockAlert.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte minimum'**
  String get minStockAlert;

  /// No description provided for @maxStockAlert.
  ///
  /// In fr, this message translates to:
  /// **'Stock maximum'**
  String get maxStockAlert;

  /// No description provided for @stockSufficient.
  ///
  /// In fr, this message translates to:
  /// **'Stock suffisant'**
  String get stockSufficient;

  /// No description provided for @lowStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock faible'**
  String get lowStock;

  /// No description provided for @outOfStock.
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock'**
  String get outOfStock;

  /// No description provided for @inStock.
  ///
  /// In fr, this message translates to:
  /// **'en stock'**
  String get inStock;

  /// No description provided for @available.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @soonOut.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt épuisé'**
  String get soonOut;

  /// No description provided for @invoices.
  ///
  /// In fr, this message translates to:
  /// **'Mes factures'**
  String get invoices;

  /// No description provided for @invoice.
  ///
  /// In fr, this message translates to:
  /// **'Facture'**
  String get invoice;

  /// No description provided for @invoice_number.
  ///
  /// In fr, this message translates to:
  /// **'N° Facture'**
  String get invoice_number;

  /// No description provided for @invoice_date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get invoice_date;

  /// No description provided for @invoice_total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get invoice_total;

  /// No description provided for @invoice_status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get invoice_status;

  /// No description provided for @invoice_paid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get invoice_paid;

  /// No description provided for @invoice_pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get invoice_pending;

  /// No description provided for @invoice_download.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger'**
  String get invoice_download;

  /// No description provided for @invoice_details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get invoice_details;

  /// No description provided for @invoice_customer.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get invoice_customer;

  /// No description provided for @invoice_company.
  ///
  /// In fr, this message translates to:
  /// **'Société'**
  String get invoice_company;

  /// No description provided for @invoice_email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get invoice_email;

  /// No description provided for @invoice_phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get invoice_phone;

  /// No description provided for @invoice_address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get invoice_address;

  /// No description provided for @invoice_city.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get invoice_city;

  /// No description provided for @invoice_zip.
  ///
  /// In fr, this message translates to:
  /// **'Code postal'**
  String get invoice_zip;

  /// No description provided for @invoice_items.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get invoice_items;

  /// No description provided for @invoice_quantity.
  ///
  /// In fr, this message translates to:
  /// **'Qté'**
  String get invoice_quantity;

  /// No description provided for @invoice_price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get invoice_price;

  /// No description provided for @invoice_subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get invoice_subtotal;

  /// No description provided for @invoice_tax.
  ///
  /// In fr, this message translates to:
  /// **'TVA (20%)'**
  String get invoice_tax;

  /// No description provided for @invoice_shipping.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get invoice_shipping;

  /// No description provided for @invoice_grand_total.
  ///
  /// In fr, this message translates to:
  /// **'Total TTC'**
  String get invoice_grand_total;

  /// No description provided for @invoice_payment_method.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get invoice_payment_method;

  /// No description provided for @invoice_cash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get invoice_cash;

  /// No description provided for @invoice_card.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get invoice_card;

  /// No description provided for @invoice_no_invoices.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture'**
  String get invoice_no_invoices;

  /// No description provided for @invoice_no_invoices_desc.
  ///
  /// In fr, this message translates to:
  /// **'Vos factures apparaîtront ici après vos achats'**
  String get invoice_no_invoices_desc;

  /// No description provided for @due_date.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'échéance'**
  String get due_date;

  /// No description provided for @billed_to.
  ///
  /// In fr, this message translates to:
  /// **'Facturé à'**
  String get billed_to;

  /// No description provided for @customer.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get customer;

  /// No description provided for @zip_code.
  ///
  /// In fr, this message translates to:
  /// **'Code postal'**
  String get zip_code;

  /// No description provided for @items.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get items;

  /// No description provided for @product.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get product;

  /// No description provided for @reference.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get reference;

  /// No description provided for @unit_price.
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire'**
  String get unit_price;

  /// No description provided for @payment_method.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get payment_method;

  /// No description provided for @payment_status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get payment_status;

  /// No description provided for @download_pdf.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger PDF'**
  String get download_pdf;

  /// No description provided for @share_pdf.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share_pdf;

  /// No description provided for @no_invoices.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture'**
  String get no_invoices;

  /// No description provided for @total_invoiced.
  ///
  /// In fr, this message translates to:
  /// **'Total facturé'**
  String get total_invoiced;

  /// No description provided for @filter_all.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filter_all;

  /// No description provided for @filter_this_month.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get filter_this_month;

  /// No description provided for @filter_last_month.
  ///
  /// In fr, this message translates to:
  /// **'Mois dernier'**
  String get filter_last_month;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
