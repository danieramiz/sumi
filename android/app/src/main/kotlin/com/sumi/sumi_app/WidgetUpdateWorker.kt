package com.sumi.sumi_app

import android.content.Context
import android.content.SharedPreferences
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Native WorkManager worker for background widget updates.
 *
 * This is a stub for the WorkManager implementation.
 * See PR #TODO for full implementation details.
 *
 * Reads auth token from sumi_auth_token.json, fetches followed manga
 * from MangaDex API, saves widget data to HomeWidgetPreferences,
 * and triggers AppWidgetManager to update all Sumi widgets.
 */
class WidgetUpdateWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            val token = readAuthToken() ?: return Result.retry()
            // TODO: Fetch manga data from MangaDex API
            // TODO: Parse response and save to SharedPreferences
            // TODO: Update all widgets via AppWidgetManager
            Result.success()
        } catch (e: Exception) {
            if (runAttemptCount < 3) Result.retry() else Result.failure()
        }
    }

    private fun readAuthToken(): String? {
        return try {
            val dir = applicationContext.filesDir.parentFile
            val file = File(dir, "app_flutter/sumi_auth_token.json")
            if (!file.exists()) return null
            val content = file.readText()
            val json = org.json.JSONObject(content)
            json.optString("session", null)
        } catch (_: Exception) {
            null
        }
    }

    companion object {
        private const val WORK_NAME = "sumi-widget-background-update"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                15, TimeUnit.MINUTES
            ).build()

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
