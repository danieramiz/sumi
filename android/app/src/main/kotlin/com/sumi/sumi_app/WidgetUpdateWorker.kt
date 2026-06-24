package com.sumi.sumi_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.TimeUnit

class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val token = readAuthToken()
            if (token == null) {
                android.util.Log.w("SumiWidget", "No auth token available")
                return@withContext Result.success()
            }

            val json = fetchFollowedManga(token)
            if (json == null) {
                android.util.Log.w("SumiWidget", "API returned null (maybe 401)")
                return@withContext Result.success()
            }

            val items = parseItems(json)
            if (items.isEmpty()) {
                android.util.Log.d("SumiWidget", "No manga items in response")
                return@withContext Result.success()
            }

            saveWidgetData(items)
            updateAllWidgets()
            checkForNewChapters(items)
            android.util.Log.d("SumiWidget", "Widget update completed: ${items.size} manga")
            Result.success()
        } catch (e: Exception) {
            android.util.Log.e("SumiWidget", "Worker failed", e)
            if (runAttemptCount < 3) Result.retry() else Result.failure()
        }
    }

    private fun readAuthToken(): String? {
        return try {
            val dir = applicationContext.filesDir.parentFile
            val file = File(dir, "app_flutter/sumi_auth_token.json")
            if (!file.exists()) return null
            val content = file.readText()
            val obj = JSONObject(content)
            val token = obj.optString("session", null) ?: return null
            val expiresAtStr = obj.optString("expiresAt", null) ?: return null
            val expiresAt = java.time.Instant.parse(expiresAtStr)
            if (java.time.Instant.now().isAfter(expiresAt)) return null
            token
        } catch (_: Exception) {
            null
        }
    }

    private fun fetchFollowedManga(token: String): String? {
        return try {
            val url = URL("https://api.mangadex.org/user/follows/manga?limit=20&includes[]=cover_art")
            val conn = url.openConnection() as HttpURLConnection
            conn.requestMethod = "GET"
            conn.setRequestProperty("Authorization", "Bearer $token")
            conn.setRequestProperty("User-Agent", "SumiApp/1.0")
            conn.connectTimeout = 15000
            conn.readTimeout = 15000

            if (conn.responseCode == 401) return null

            val reader = BufferedReader(InputStreamReader(
                if (conn.responseCode in 200..299) conn.inputStream else conn.errorStream
            ))
            val response = reader.readText()
            conn.disconnect()

            if (conn.responseCode !in 200..299) return null
            response
        } catch (_: Exception) {
            null
        }
    }

    private data class MangaItem(
        val id: String, val title: String, val coverFileName: String?,
        val lastChapter: String?, val updatedAt: String?
    )

    private fun parseItems(json: String): List<MangaItem> {
        val root = JSONObject(json)
        val data = root.optJSONArray("data") ?: return emptyList()
        val items = mutableListOf<MangaItem>()

        for (i in 0 until data.length()) {
            val obj = data.getJSONObject(i)
            val attrs = obj.optJSONObject("attributes") ?: continue
            val rels = obj.optJSONArray("relationships") ?: JSONArray()

            var coverFileName: String? = null
            for (j in 0 until rels.length()) {
                val r = rels.getJSONObject(j)
                if (r.optString("type") == "cover_art") {
                    val rAttrs = r.optJSONObject("attributes")
                    coverFileName = rAttrs?.optString("fileName", null)
                }
            }

            val titleMap = attrs.optJSONObject("title") ?: JSONObject()
            val title = titleMap.optString("en", null)
                ?: titleMap.keys().asSequence().firstOrNull()?.let { titleMap.optString(it, "Unknown") }
                ?: "Unknown"

            items.add(MangaItem(
                id = obj.optString("id", ""),
                title = title,
                coverFileName = coverFileName,
                lastChapter = attrs.optString("lastChapter", null),
                updatedAt = attrs.optString("updatedAt", null)
            ))
        }
        return items
    }

    private fun saveWidgetData(items: List<MangaItem>) {
        val prefs = applicationContext.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putInt("new_chapter_count", items.size)

            if (items.isNotEmpty()) {
                val first = items.first()
                putString("continue_title", first.title)
                putString("continue_chapter", "Ch. ${first.lastChapter ?: "?"}")
                putInt("continue_percentage", 50)
            } else {
                putString("continue_title", "")
                putString("continue_chapter", "")
                putInt("continue_percentage", 0)
            }

            for (i in 0 until 3) {
                val idx = i + 1
                if (i < items.size) {
                    val item = items[i]
                    putString("update_${idx}_title", item.title)
                    putString("update_${idx}_chapter", "Ch. ${item.lastChapter ?: "?"}")
                    putString("update_${idx}_time", item.updatedAt?.let { timeAgo(it) } ?: "")
                } else {
                    putString("update_${idx}_title", "")
                    putString("update_${idx}_chapter", "")
                    putString("update_${idx}_time", "")
                }
            }
            apply()
        }
    }

    private fun updateAllWidgets() {
        val ctx = applicationContext
        val manager = AppWidgetManager.getInstance(ctx)
        val providers = listOf(
            SumiSmallWidgetProvider::class.java to R.layout.sumi_widget_small,
            SumiMediumWidgetProvider::class.java to R.layout.sumi_widget_medium,
            SumiLargeWidgetProvider::class.java to R.layout.sumi_widget_large
        )

        val prefs = ctx.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        for ((providerClass, layoutId) in providers) {
            val component = ComponentName(ctx, providerClass)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isEmpty()) continue

            val views = RemoteViews(ctx.packageName, layoutId)

            when (providerClass) {
                SumiSmallWidgetProvider::class.java -> {
                    val count = prefs.getInt("new_chapter_count", 0)
                    views.setTextViewText(R.id.widget_small_count, "$count new chapters")
                    setTapToOpen(ctx, views, R.id.widget_small_root)
                }
                SumiMediumWidgetProvider::class.java -> {
                    val title = prefs.getString("continue_title", "")
                    if (!title.isNullOrEmpty()) {
                        views.setTextViewText(R.id.widget_medium_title, title)
                        views.setTextViewText(R.id.widget_medium_chapter,
                            prefs.getString("continue_chapter", "Ch. 0") ?: "Ch. 0")
                        val pct = prefs.getInt("continue_percentage", 0)
                        views.setTextViewText(R.id.widget_medium_percentage, "${pct}% caught up")
                        views.setProgressBar(R.id.widget_medium_progress, 100, pct, false)
                    }
                    setTapToOpen(ctx, views, R.id.widget_medium_root)
                }
                SumiLargeWidgetProvider::class.java -> {
                    val count = prefs.getInt("new_chapter_count", 0)
                    views.setTextViewText(R.id.widget_large_summary, "$count new chapters today")
                    for (i in 1..3) {
                        val t = prefs.getString("update_${i}_title", "")
                        if (!t.isNullOrEmpty()) {
                            val rowId = when (i) { 1 -> R.id.widget_update_row_1; 2 -> R.id.widget_update_row_2; else -> R.id.widget_update_row_3 }
                            views.setViewVisibility(rowId, android.view.View.VISIBLE)
                            val titleId = when (i) { 1 -> R.id.widget_update_1_title; 2 -> R.id.widget_update_2_title; else -> R.id.widget_update_3_title }
                            views.setTextViewText(titleId, t)
                            val ch = prefs.getString("update_${i}_chapter", "") ?: ""
                            val tm = prefs.getString("update_${i}_time", "") ?: ""
                            val chId = when (i) { 1 -> R.id.widget_update_1_chapter; 2 -> R.id.widget_update_2_chapter; else -> R.id.widget_update_3_chapter }
                            views.setTextViewText(chId, "$ch \u00b7 $tm")
                        }
                    }
                    setTapToOpen(ctx, views, R.id.widget_large_root)
                }
            }

            for (id in ids) {
                manager.updateAppWidget(id, views)
            }
        }
    }

    private fun setTapToOpen(ctx: Context, views: RemoteViews, viewId: Int) {
        val intent = android.content.Intent(ctx, MainActivity::class.java).apply {
            flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pi = android.app.PendingIntent.getActivity(
            ctx, 0, intent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(viewId, pi)
    }

    private fun checkForNewChapters(items: List<MangaItem>) {
        val ctx = applicationContext
        val prefs = ctx.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val notificationsEnabled = prefs.getBoolean("notifications_enabled", true)
        if (!notificationsEnabled) return

        val newChapters = mutableListOf<SumiNotificationManager.NewChapterInfo>()
        val now = System.currentTimeMillis()
        val oneDayMs = 86400000L

        for (item in items) {
            val lastChapter = prefs.getString("last_chapter_${item.id}", null)
            val lastNotified = prefs.getLong("last_notified_${item.id}", 0)

            if (item.lastChapter != null && item.lastChapter != lastChapter) {
                if (now - lastNotified > oneDayMs) {
                    newChapters.add(SumiNotificationManager.NewChapterInfo(
                        title = item.title,
                        chapterLabel = "Ch. ${item.lastChapter}",
                        mangaId = item.id
                    ))
                    prefs.edit()
                        .putString("last_chapter_${item.id}", item.lastChapter)
                        .putLong("last_notified_${item.id}", now)
                        .apply()
                }
            } else if (item.lastChapter != null && lastChapter == null) {
                prefs.edit().putString("last_chapter_${item.id}", item.lastChapter).apply()
            }
        }

        if (newChapters.isNotEmpty()) {
            SumiNotificationManager.showNotification(ctx, newChapters)
        }
    }

    companion object {
        private const val WORK_NAME = "sumi-widget-background-update"

        fun schedule(context: Context) {
            val constraints = androidx.work.Constraints.Builder()
                .setRequiredNetworkType(androidx.work.NetworkType.CONNECTED)
                .build()

            val request = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                15, TimeUnit.MINUTES
            ).setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}

object WidgetUpdateWorkerTestUtil {
    fun timeAgo(isoDate: String): String {
        return try {
            val instant = java.time.Instant.parse(isoDate)
            val diff = java.time.Duration.between(instant, java.time.Instant.now())
            when {
                diff.toMinutes() < 60 -> "${diff.toMinutes()}m ago"
                diff.toHours() < 24 -> "${diff.toHours()}h ago"
                diff.toDays() < 7 -> "${diff.toDays()}d ago"
                else -> "${(diff.toDays() / 7)}w ago"
            }
        } catch (_: Exception) {
            ""
        }
    }

    fun parseItems(json: String): List<MangaItemPublic> {
        val root = JSONObject(json)
        val data = root.optJSONArray("data") ?: return emptyList()
        val items = mutableListOf<MangaItemPublic>()

        for (i in 0 until data.length()) {
            val obj = data.getJSONObject(i)
            val attrs = obj.optJSONObject("attributes") ?: continue
            val rels = obj.optJSONArray("relationships") ?: JSONArray()

            var coverFileName: String? = null
            for (j in 0 until rels.length()) {
                val r = rels.getJSONObject(j)
                if (r.optString("type") == "cover_art") {
                    val rAttrs = r.optJSONObject("attributes")
                    coverFileName = rAttrs?.optString("fileName", null)
                }
            }

            val titleMap = attrs.optJSONObject("title") ?: JSONObject()
            val title = titleMap.optString("en", null)
                ?: titleMap.keys().asSequence().firstOrNull()?.let { titleMap.optString(it, "Unknown") }
                ?: "Unknown"

            items.add(MangaItemPublic(
                id = obj.optString("id", ""),
                title = title,
                coverFileName = coverFileName,
                lastChapter = attrs.optString("lastChapter", null),
                updatedAt = attrs.optString("updatedAt", null)
            ))
        }
        return items
    }
}

data class MangaItemPublic(
    val id: String, val title: String, val coverFileName: String?,
    val lastChapter: String?, val updatedAt: String?
)

private fun timeAgo(isoDate: String): String {
    return try {
        val instant = java.time.Instant.parse(isoDate)
        val diff = java.time.Duration.between(instant, java.time.Instant.now())
        when {
            diff.toMinutes() < 60 -> "${diff.toMinutes()}m ago"
            diff.toHours() < 24 -> "${diff.toHours()}h ago"
            diff.toDays() < 7 -> "${diff.toDays()}d ago"
            else -> "${(diff.toDays() / 7)}w ago"
        }
    } catch (_: Exception) {
        ""
    }
}
