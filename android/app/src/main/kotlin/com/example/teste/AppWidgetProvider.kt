package com.example.teste

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AppWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Obter a string com a lista de tarefas, salva no Flutter via HomeWidget
                val tasksString = widgetData.getString("widget_tasks_string", "Carregando tarefas...")
                setTextViewText(R.id.widget_tasks, tasksString)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
