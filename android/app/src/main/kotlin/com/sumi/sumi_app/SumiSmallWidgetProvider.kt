package com.sumi.sumi_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class SumiSmallWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.sumi_widget_small)

            val count = prefs.getInt("new_chapter_count", 0)
            views.setTextViewText(R.id.widget_small_count, "$count new chapters")

            setTapToOpen(context, views, R.id.widget_small_root)

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
