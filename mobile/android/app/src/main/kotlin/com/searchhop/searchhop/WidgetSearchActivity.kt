package com.searchhop.searchhop

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

class WidgetSearchActivity : FlutterActivity() {
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun getDartEntrypointFunctionName(): String = "widgetSearchMain"
}