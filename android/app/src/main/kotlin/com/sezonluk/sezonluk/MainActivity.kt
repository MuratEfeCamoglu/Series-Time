package com.sezonluk.sezonluk

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// F22: Ayarlar › Uygulama simgesi. Her renk AndroidManifest.xml'de bir activity-alias'tır;
// seçilen açılır, diğerleri kapatılır. Varsayılan (manifestte açık olan) sarıdır.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "current" -> result.success(currentIcon())
                    "set" -> {
                        val name = call.argument<String>("name")
                        if (name == null || name !in ICONS) {
                            result.error("invalid_icon", "Bilinmeyen simge: $name", null)
                        } else {
                            setIcon(name)
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun alias(name: String) = ComponentName(
        this,
        "${MainActivity::class.java.`package`!!.name}.Launcher${name.replaceFirstChar { it.uppercase() }}",
    )

    private fun currentIcon(): String = ICONS.firstOrNull { name ->
        when (packageManager.getComponentEnabledSetting(alias(name))) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> name == DEFAULT_ICON
            else -> false
        }
    } ?: DEFAULT_ICON

    private fun setIcon(name: String) {
        // Önce yenisi açılır: başlatıcıda bir an bile simgesiz kalınmaz.
        packageManager.setComponentEnabledSetting(
            alias(name),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for (other in ICONS) {
            if (other == name) continue
            packageManager.setComponentEnabledSetting(
                alias(other),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private companion object {
        const val CHANNEL = "sezonluk/app_icon"
        const val DEFAULT_ICON = "yellow"
        val ICONS = listOf("yellow", "purple", "blue", "green", "red", "orange")
    }
}
