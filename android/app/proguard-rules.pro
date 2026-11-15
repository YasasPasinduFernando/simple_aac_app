# ProGuard & R8 Optimization Rules for Simple AAC Sri Lanka

# Keep essential attributes for serialization, annotations, and reflection
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions

# Flutter framework & engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Application native classes (MainActivity, VideoGifEncoder, VideoTooLongException)
-keep class com.example.simple_aac_app.** { *; }
-keepclassmembers class com.example.simple_aac_app.** { *; }

# Google ML Kit (Offline Image Labeling & Object Detection)
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Native Method Channel & Platform Plugins
# Text-to-Speech (TTS Engine integration)
-keep class com.tundralabs.fluttertts.** { *; }

# Audio recording & playback
-keep class xyz.luan.audioplayers.** { *; }
-keep class com.llfbandit.record.** { *; }

# Media & Storage providers (Image picker, file picker, share_plus, path_provider, shared_preferences, permission_handler)
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
