# Keep Flutter & plugin entry points.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# SQLCipher native bindings.
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# flutter_local_notifications uses Gson reflectively.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# androidx work / alarm.
-keep class androidx.work.** { *; }
