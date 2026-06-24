package com.sumi.sumi_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

object SumiNotificationManager {

    private const val CHANNEL_ID = "sumi_new_chapters"
    private const val CHANNEL_NAME = "New Chapters"
    private const val NOTIFICATION_ID = 1001

    fun createChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "New manga chapters available"
        }
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    fun hasPermission(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            context, Manifest.permission.POST_NOTIFICATIONS
        ) == PackageManager.PERMISSION_GRANTED
    }

    data class NewChapterInfo(
        val title: String,
        val chapterLabel: String,
        val mangaId: String
    )

    fun showNotification(context: Context, newChapters: List<NewChapterInfo>) {
        if (newChapters.isEmpty()) return
        if (!hasPermission(context)) return

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val inboxStyle = NotificationCompat.InboxStyle()
        val titleMap = mutableMapOf<String, MutableList<String>>()
        for (ch in newChapters) {
            titleMap.getOrPut(ch.title) { mutableListOf() }.add(ch.chapterLabel)
        }

        val sorted = titleMap.entries.take(4)
        for ((title, chapters) in sorted) {
            inboxStyle.addLine("$title — ${chapters.first()}")
        }
        if (titleMap.size > 4) {
            inboxStyle.setSummaryText("+${titleMap.size - 4} more")
        } else if (newChapters.size == 1) {
            inboxStyle.setSummaryText("${newChapters.size} new chapter")
        } else {
            inboxStyle.setSummaryText("${newChapters.size} new chapters")
        }

        val bodyText = if (titleMap.size == 1) {
            "${titleMap.keys.first()} — ${titleMap.values.first().first()}"
        } else {
            "${titleMap.size} manga have new chapters"
        }

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("New Chapters Available")
            .setContentText(bodyText)
            .setStyle(inboxStyle)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setColor(0xFFFF4F6D.toInt())
            .build()

        NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
    }
}
