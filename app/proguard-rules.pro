# Keep Kotlin metadata for reflection (serialization)
-keepattributes *Annotation*, InnerClasses, Signature, Exceptions, SourceFile, LineNumberTable

# kotlinx.serialization
-keepclassmembers class kotlinx.serialization.json.** {
    *** Companion;
}
-keepclasses class kotlinx.serialization.json.** {
    *** Companion;
}
-keep,includedescriptorclasses class **$$serializer { * }
-keep class kotlinx.serialization.** { * }
-keep class id.realita62.lifeboard.** { *; }

# Compose
-dontwarn androidx.compose.**
