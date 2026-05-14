package com.remembersomething.rs

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Bundle as AndroidBundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter Android 主 Activity。
 *
 * 负责设置沉浸式状态栏，并注册分享处理状态的 MethodChannel。
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            enableLegacyEdgeToEdge()
        }
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT
    }

    @Suppress("DEPRECATION")
    private fun enableLegacyEdgeToEdge() {
        window.decorView.systemUiVisibility = (
            android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val notifier = ShareStatusNotifier(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "rs_android/share_status"
        ).setMethodCallHandler { call, result ->
            val id = call.argument<Int>("id") ?: ShareStatusNotifier.DEFAULT_NOTIFICATION_ID
            when (call.method) {
                "supportsLiveUpdate" -> result.success(notifier.supportsLiveUpdate())
                "showAnalyzing" -> result.success(notifier.showAnalyzing(id))
                "showComplete" -> {
                    val memoryType = call.argument<String>("memoryType") ?: ""
                    result.success(notifier.showComplete(id, memoryType))
                }
                "showFailed" -> {
                    val message = call.argument<String>("message") ?: "请打开应用查看详情"
                    result.success(notifier.showFailed(id, message))
                }
                "cancel" -> {
                    notifier.cancel(id)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

/**
 * 分享分析状态通知封装。
 *
 * Android 16+ 支持 promoted ongoing notification 时展示系统级实时状态；
 * 旧版本或不支持的平台能力时保持普通通知/空操作。
 */
private class ShareStatusNotifier(private val context: Context) {
    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun supportsLiveUpdate(): Boolean {
        if (Build.VERSION.SDK_INT < 36) return false
        return canPostPromotedNotifications()
    }

    /** 展示“AI 正在分析”的持续通知。 */
    fun showAnalyzing(id: Int): Boolean {
        if (!supportsLiveUpdate()) return false

        ensureChannel()
        val notification = createBaseBuilder("AI 正在分析中", "RS 正在分析分享内容", "分析中")
            .setOngoing(true)
            .setAutoCancel(false)
            .setProgress(0, 0, true)
            .setAnalyzingProgressStyle()
            .requestPromotedOngoing()
            .build()

        if (!notification.hasPromotableCharacteristics()) return false

        notificationManager.notify(id, notification)
        return true
    }

    /** 展示“AI 分析完成”的通知。 */
    fun showComplete(id: Int, memoryType: String): Boolean {
        ensureChannel()
        val body = if (memoryType.isBlank()) {
            "分享内容已分析完成"
        } else {
            "已识别为$memoryType，请打开应用确认"
        }
        val notification = createBaseBuilder("AI 分析已完成", body, "已完成")
            .setOngoing(false)
            .setAutoCancel(true)
            .setProgress(100, 100, false)
            .setCompleteProgressStyle()
            .build()

        notificationManager.notify(id, notification)
        return true
    }

    /** 展示“AI 分析失败”的通知。 */
    fun showFailed(id: Int, message: String): Boolean {
        ensureChannel()
        val notification = createBaseBuilder("AI 分析失败", message, "失败")
            .setOngoing(false)
            .setAutoCancel(true)
            .setProgress(0, 0, false)
            .build()

        notificationManager.notify(id, notification)
        return true
    }

    /** 取消指定分享状态通知。 */
    fun cancel(id: Int) {
        notificationManager.cancel(id)
    }

    /** 确保通知渠道存在；Android 8 以下无需渠道。 */
    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "分享内容分析",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "显示系统分享到 RS 后的 AI 分析状态"
            setShowBadge(false)
        }
        notificationManager.createNotificationChannel(channel)
    }

    /** 创建所有分享状态通知共用的基础 Builder。 */
    private fun createBaseBuilder(
        title: String,
        text: String,
        shortCriticalText: String,
    ): Notification.Builder {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(text)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setContentIntent(contentIntent())
            .setShortCriticalTextCompat(shortCriticalText)
    }

    /** 点击通知后回到主界面。 */
    private fun contentIntent(): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_SHARE_STATUS
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** 通过反射兼容 Android 16 的 promoted notification 检查 API。 */
    private fun canPostPromotedNotifications(): Boolean {
        return try {
            val method = NotificationManager::class.java.getMethod("canPostPromotedNotifications")
            method.invoke(notificationManager) as? Boolean ?: false
        } catch (_: ReflectiveOperationException) {
            false
        }
    }

    /** 请求 Android 16 promoted ongoing notification 能力。 */
    private fun Notification.Builder.requestPromotedOngoing(): Notification.Builder {
        addExtras(AndroidBundle().apply {
            putBoolean("android.requestPromotedOngoing", true)
        })
        return this
    }

    private fun Notification.Builder.setShortCriticalTextCompat(
        text: String,
    ): Notification.Builder {
        if (Build.VERSION.SDK_INT < 36) return this

        try {
            val method = Notification.Builder::class.java.getMethod(
                "setShortCriticalText",
                String::class.java
            )
            method.invoke(this, text)
        } catch (_: ReflectiveOperationException) {
            // Android 16.0 没有该 Android 16.1 便捷 API，缺失时继续使用基础通知。
        }
        return this
    }

    /** 设置“分析中”的进度样式。 */
    private fun Notification.Builder.setAnalyzingProgressStyle(): Notification.Builder {
        if (Build.VERSION.SDK_INT >= 36) {
            setStyle(Notification.ProgressStyle().setProgressIndeterminate(true))
        }
        return this
    }

    /** 设置“已完成”的进度样式。 */
    private fun Notification.Builder.setCompleteProgressStyle(): Notification.Builder {
        if (Build.VERSION.SDK_INT >= 36) {
            setStyle(Notification.ProgressStyle().setProgress(100))
        }
        return this
    }

    /** 检查通知是否满足 promoted ongoing notification 的系统要求。 */
    private fun Notification.hasPromotableCharacteristics(): Boolean {
        if (Build.VERSION.SDK_INT < 36) return true

        return try {
            val method = Notification::class.java.getMethod("hasPromotableCharacteristics")
            method.invoke(this) as? Boolean ?: true
        } catch (_: ReflectiveOperationException) {
            true
        }
    }

    companion object {
        const val DEFAULT_NOTIFICATION_ID = 220001

        private const val CHANNEL_ID = "rs_share_status"
        private const val ACTION_OPEN_SHARE_STATUS = "com.remembersomething.rs.OPEN_SHARE_STATUS"
    }
}
