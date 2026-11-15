# ProGuard & R8 Optimization Rules for Simple AAC Sri Lanka
# Optimized for Android Gradle Plugin 9.0.1 and R8 full mode shrinking

# Keep essential attributes for serialization, annotations, and reflection
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions

# Flutter framework & engine JNI bridge
# (Plugin registration is managed by GeneratedPluginRegistrant and flutter_proguard_rules.pro)
-dontwarn io.flutter.embedding.**
-keepclasseswithmembernames class * {
    native <methods>;
}

# Application native classes
-keep class com.example.simple_aac_app.MainActivity {
    public *;
}
-keep class com.example.simple_aac_app.VideoGifEncoder {
    public static <methods>;
}

# Google ML Kit (Offline Image Labeling & Object Detection)
# Preserves ComponentRegistrars, reflection constructors, and ML Kit vision client factories
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    <init>();
}
-keep class com.google.mlkit.** {
    <init>(...);
    public *;
}
-keep interface com.google.mlkit.** {
    *;
}
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# Native Method Channel & Platform Plugins
# Text-to-Speech (TTS Engine integration & trilingual synthesis)
-keep class com.tundralabs.fluttertts.FlutterTtsPlugin {
    public *;
}

# Audio recording & playback
-keep class xyz.luan.audioplayers.AudioplayersPlugin {
    public *;
}
-keep class com.llfbandit.record.RecordPlugin {
    public *;
}

# Media, File & Storage platform plugins
-keep class io.flutter.plugins.imagepicker.ImagePickerPlugin {
    public *;
}
-keep class com.mr.flutter.plugin.filepicker.FilePickerPlugin {
    public *;
}
-keep class dev.fluttercommunity.plus.share.SharePlusPlugin {
    public *;
}
-keep class io.flutter.plugins.pathprovider.PathProviderPlugin {
    public *;
}
-keep class io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin {
    public *;
}
-keep class com.baseflow.permissionhandler.PermissionHandlerPlugin {
    public *;
}
