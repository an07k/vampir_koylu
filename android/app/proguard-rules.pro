# Flutter Wrapper
-keep class io.flutter.** { *; }
-keep class com.google.android.material.** { *; }
-keep class androidx.** { *; }
-keep class org.jetbrains.kotlin.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Game code - keep all application classes
-keep class com.example.vampir_koylu.** { *; }

# Generic rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
