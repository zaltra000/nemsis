package com.nemesis.nemesis_core

import android.app.ActivityManager
import android.content.Context
import android.net.TrafficStats
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.FileReader
import java.io.RandomAccessFile

class MainActivity : FlutterActivity() {
    private val CHANNEL = "nemesis/stats"

    // CPU calculation state
    private var prevIdle: Long = 0
    private var prevTotal: Long = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStats" -> {
                        val stats = HashMap<String, Any>()

                        // ─── RAM via ActivityManager ───
                        try {
                            val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val memInfo = ActivityManager.MemoryInfo()
                            actManager.getMemoryInfo(memInfo)
                            stats["ramTotal"] = memInfo.totalMem.toDouble()
                            stats["ramAvailable"] = memInfo.availMem.toDouble()
                        } catch (e: Exception) {
                            stats["ramTotal"] = 0.0
                            stats["ramAvailable"] = 0.0
                        }

                        // ─── Network via TrafficStats ───
                        try {
                            stats["netRx"] = TrafficStats.getTotalRxBytes()
                            stats["netTx"] = TrafficStats.getTotalTxBytes()
                        } catch (e: Exception) {
                            stats["netRx"] = 0L
                            stats["netTx"] = 0L
                        }

                        // ─── CPU via /proc/stat (best effort) ───
                        try {
                            val reader = RandomAccessFile("/proc/stat", "r")
                            val line = reader.readLine()
                            reader.close()

                            val parts = line.split("\\s+".toRegex())
                            // cpu user nice system idle iowait irq softirq
                            val user = parts[1].toLong()
                            val nice = parts[2].toLong()
                            val system = parts[3].toLong()
                            val idle = parts[4].toLong()
                            val iowait = parts[5].toLong()
                            val irq = parts[6].toLong()
                            val softirq = parts[7].toLong()

                            val total = user + nice + system + idle + iowait + irq + softirq
                            val idleTime = idle + iowait

                            if (prevTotal > 0) {
                                val deltaTotal = total - prevTotal
                                val deltaIdle = idleTime - prevIdle
                                val cpuPercent = if (deltaTotal > 0) {
                                    ((deltaTotal - deltaIdle).toDouble() / deltaTotal.toDouble()) * 100.0
                                } else 0.0
                                stats["cpu"] = cpuPercent
                            } else {
                                stats["cpu"] = 0.0
                            }

                            prevIdle = idleTime
                            prevTotal = total
                        } catch (e: Exception) {
                            // /proc/stat might be restricted, fallback to 0
                            stats["cpu"] = 0.0
                        }

                        // ─── Device Info ───
                        stats["model"] = Build.MODEL
                        stats["manufacturer"] = Build.MANUFACTURER
                        stats["androidVersion"] = Build.VERSION.RELEASE
                        stats["sdkVersion"] = Build.VERSION.SDK_INT

                        result.success(stats)
                    }
                    "getDeviceInfo" -> {
                        val info = HashMap<String, Any>()
                        info["model"] = Build.MODEL
                        info["manufacturer"] = Build.MANUFACTURER
                        info["android"] = Build.VERSION.RELEASE
                        info["sdk"] = Build.VERSION.SDK_INT
                        info["board"] = Build.BOARD
                        info["hardware"] = Build.HARDWARE
                        result.success(info)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
