# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# SQLite / sqflite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Google Fonts (fonts loaded at runtime)
-keep class com.google.fonts.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
