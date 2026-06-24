package com.sumi.sumi_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "sumi_widget_background"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        WidgetUpdateWorker.schedule(this)
                        result.success(true)
                    }
                    "cancel" -> {
                        WidgetUpdateWorker.cancel(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
