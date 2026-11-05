package com.example.growwell

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import java.time.LocalDate
import java.time.LocalTime
import java.time.YearMonth
import java.time.ZoneId
import java.time.ZonedDateTime

class GrowthReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_REMIND) {
            val childId = intent.getIntExtra(EXTRA_CHILD, -1)
            if (childId < 0) return
            if (Build.VERSION.SDK_INT < 33 || context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (Build.VERSION.SDK_INT >= 26) {
                    manager.createNotificationChannel(NotificationChannel(CHANNEL_ID, "Growth reminders", NotificationManager.IMPORTANCE_DEFAULT))
                }
                val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val openApp = launch?.let { PendingIntent.getActivity(context, childId, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE) }
                val builder = if (Build.VERSION.SDK_INT >= 26) android.app.Notification.Builder(context, CHANNEL_ID) else @Suppress("DEPRECATION") android.app.Notification.Builder(context)
                val name = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString("name:$childId", "")
                val message = if (name.isNullOrBlank()) "Time to record your child's growth." else "Time to record $name's growth."
                builder.setSmallIcon(context.applicationInfo.icon)
                    .setContentTitle("Growth check reminder")
                    .setContentText(message)
                    .setVisibility(android.app.Notification.VISIBILITY_PRIVATE)
                    .setAutoCancel(true)
                if (openApp != null) builder.setContentIntent(openApp)
                manager.notify(childId, builder.build())
            }
            scheduleSaved(context, childId)
        } else {
            val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            preferences.all.keys.mapNotNull { it.toIntOrNull() }.forEach { scheduleSaved(context, it) }
        }
    }

    companion object {
        private const val PREFS = "growth_reminder_dates"
        private const val ACTION_REMIND = "com.example.growwell.GROWTH_REMINDER"
        private const val EXTRA_CHILD = "child_id"
        private const val CHANNEL_ID = "growth_reminders_auto"

        fun saveAndSchedule(context: Context, childId: Int, date: String, name: String) {
            LocalDate.parse(date)
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(childId.toString(), date).putString("name:$childId", name).commit()
            scheduleSaved(context, childId)
        }

        private fun scheduleSaved(context: Context, childId: Int) {
            val stored = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(childId.toString(), null) ?: return
            val lastMeasurement = LocalDate.parse(stored)
            val zone = ZoneId.systemDefault()
            val now = ZonedDateTime.now(zone)
            var month = YearMonth.from(lastMeasurement).plusMonths(1)
            var next: ZonedDateTime
            do {
                val day = minOf(lastMeasurement.dayOfMonth, month.lengthOfMonth())
                next = month.atDay(day).atTime(LocalTime.of(9, 0)).atZone(zone)
                month = month.plusMonths(1)
            } while (!next.isAfter(now))
            val intent = Intent(context, GrowthReminderReceiver::class.java).setAction(ACTION_REMIND).putExtra(EXTRA_CHILD, childId)
            val pending = PendingIntent.getBroadcast(context, childId, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.toInstant().toEpochMilli(), pending)
        }
    }
}
