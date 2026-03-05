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
  /// **'E-mail'**
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
  /// **'Payé'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In fr, this message translates to:
  /// **'Impayé'**
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
  /// **'Validées'**
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
