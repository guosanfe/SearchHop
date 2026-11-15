package com.searchhop.searchhop

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

abstract class BaseSearchHopWidgetProvider(private val layoutId: Int) : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val intent = Intent(context, WidgetSearchActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, layoutId)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

class SearchHopWidgetProvider : BaseSearchHopWidgetProvider(R.layout.widget_search)

class SearchHopWidgetSmallProvider : BaseSearchHopWidgetProvider(R.layout.widget_search_small)

class SearchHopWidgetLargeProvider : BaseSearchHopWidgetProvider(R.layout.widget_search_large)