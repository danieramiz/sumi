package com.sumi.sumi_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

class SumiMediumWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sumi_widget_medium)

            val coverPath = prefs.getString("continue_cover_path", "")
            if (!coverPath.isNullOrEmpty()) {
                val file = File(coverPath)
                if (file.exists()) {
                    val bitmap = BitmapFactory.decodeFile(coverPath)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_medium_cover, bitmap)
                    }
                }
            }

            val title = prefs.getString("continue_title", "")
            if (!title.isNullOrEmpty()) {
                views.setTextViewText(R.id.widget_medium_title, title)

                val chapter = prefs.getString("continue_chapter", "Ch. 0") ?: "Ch. 0"
                views.setTextViewText(R.id.widget_medium_chapter, chapter)

                val percentage = prefs.getInt("continue_percentage", 0)
                views.setTextViewText(R.id.widget_medium_percentage, "${percentage}% caught up")
                views.setProgressBar(R.id.widget_medium_progress, 100, percentage, false)
            }

            setTapToOpen(context, views, R.id.widget_medium_root)

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun setTapToOpen(context: Context, views: RemoteViews, viewId: Int) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pi = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(viewId, pi)
    }
}
