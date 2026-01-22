# 1. Prevent Agora SDK from being obfuscated/stripped
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# 2. Prevent Flutter native wrapper from being stripped
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Ignore missing Play Core classes referenced by the Flutter engine
-dontwarn com.google.android.play.core.**

# If you still see errors related to 'tasks', add this:
-dontwarn com.google.android.play.core.tasks.**