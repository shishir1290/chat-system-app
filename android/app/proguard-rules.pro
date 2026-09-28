# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WebRTC Native Bindings
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn com.cloudwebrtc.webrtc.**

# Audio & Media Plugins
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# General Keep Rules
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
