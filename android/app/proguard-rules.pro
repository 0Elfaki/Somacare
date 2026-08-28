# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.**

# Supabase specific rules
-keep class com.supabase.** { *; }
-dontwarn com.supabase.**

# Keep Supabase GoTrue
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep postgrest
-keep class io.postgrest.** { *; }
-dontwarn io.postgrest.**

# Keep realtime
-keep class io.realtime.** { *; }
-dontwarn io.realtime.**

# Keep storage
-keep class io.storage.** { *; }
-dontwarn io.storage.**

# Keep gotrue
-keep class io.gotrue.** { *; }
-dontwarn io.gotrue.**

# Keep Dio (HTTP client used by Supabase)
-keep class dio.** { *; }
-dontwarn dio.**

# Keep OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Gson (JSON parsing)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes
-keep class com.example.telemedicine101.** { *; }

# ── Agora RTC engine ────────────────────────────────────────────────────────
# The engine is reached over JNI, so R8 cannot see the references and will
# strip it. Without these rules video calls fail ONLY in release builds.
-keep class io.agora.**  { *; }
-keep class com.agora.**  { *; }
-dontwarn io.agora.**

# ── permission_handler / url_launcher ───────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ── printing / pdf ──────────────────────────────────────────────────────────
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# Model classes are matched against the Kotlin package, which is unchanged
# even though the applicationId is now com.somacare.app.
-keep class com.somacare.app.** { *; }
