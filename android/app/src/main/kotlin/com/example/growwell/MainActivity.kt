package com.example.growwell

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "growwell/growth_reminders")
            .setMethodCallHandler { call, result ->
                if (call.method != "schedule") {
                    result.notImplemented()
                } else {
                    try {
                        val childId = requireNotNull(call.argument<Int>("childId"))
                        val date = requireNotNull(call.argument<String>("date"))
                        val name = requireNotNull(call.argument<String>("name"))
                        GrowthReminderReceiver.saveAndSchedule(this, childId, date, name)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("reminder_error", e.message, null)
                    }
                }
            }
    }
}
