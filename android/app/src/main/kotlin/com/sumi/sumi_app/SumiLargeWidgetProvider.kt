package com.sumi.sumi_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class SumiLargeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sumi_widget_large)

            val count = prefs.getInt("new_chapter_count", 0)
            views.setTextViewText(R.id.widget_large_summary, "$count new chapters today")

            for (i in 1..3) {
                val title = prefs.getString("update_${i}_title", "")
                if (!title.isNullOrEmpty()) {
                    val rowId = when (i) {
                        1 -> R.id.widget_update_row_1
                        2 -> R.id.widget_update_row_2
                        else -> R.id.widget_update_row_3
                    }
                    views.setViewVisibility(rowId, View.VISIBLE)

                    val titleId = when (i) {
                        1 -> R.id.widget_update_1_title
                        2 -> R.id.widget_update_2_title
                        else -> R.id.widget_update_3_title
                    }
                    views.setTextViewText(titleId, title)

                val chapter = prefs.getString("update_${i}_chapter", "Ch. 0") ?: "Ch. 0"
                val time = prefs.getString("update_${i}_time", "") ?: ""
                    val chapterId = when (i) {
                        1 -> R.id.widget_update_1_chapter
                        2 -> R.id.widget_update_2_chapter
                        else -> R.id.widget_update_3_chapter
                    }
                    views.setTextViewText(chapterId, "$chapter \u00b7 $time")
                }
            }

            setTapToOpen(context, views, R.id.widget_large_root)

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
