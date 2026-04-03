# Stripe
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep Stripe models
-keepclassmembers class com.stripe.android.model.** { *; }

# Keep Stripe payment methods
-keep class com.stripe.android.view.** { *; }

# Keep React Native Stripe
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**

# Keep Flutter Stripe
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.paymentsheet.** { *; }

# Keep all classes from stripe library
-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}