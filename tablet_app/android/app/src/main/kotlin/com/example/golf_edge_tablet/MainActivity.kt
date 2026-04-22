package com.example.golf_edge_tablet

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.wifi.ScanResult
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "golf_edge/wifi_scan"
    private val permissionRequestCode = 4401
    private val handler = Handler(Looper.getMainLooper())

    private var pendingScanResult: MethodChannel.Result? = null
    private var scanReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanWifi" -> scanWifi(result)
                    "saveWifiBinding" -> saveWifiBinding(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        unregisterScanReceiver()
        pendingScanResult = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) {
            return
        }

        val pending = pendingScanResult ?: return
        if (hasWifiScanPermissions()) {
            startWifiScan(pending)
        } else {
            pendingScanResult = null
            pending.error(
                "wifi_permission_denied",
                "Wi-Fi scan permission was denied",
                null
            )
        }
    }

    private fun scanWifi(result: MethodChannel.Result) {
        if (pendingScanResult != null) {
            result.error("scan_in_progress", "A Wi-Fi scan is already running", null)
            return
        }

        pendingScanResult = result
        if (!hasWifiScanPermissions()) {
            requestPermissions(requiredPermissions(), permissionRequestCode)
            return
        }

        startWifiScan(result)
    }

    private fun startWifiScan(result: MethodChannel.Result) {
        if (requiresLocationForScan() && !isLocationEnabled()) {
            pendingScanResult = null
            result.error(
                "location_services_off",
                "Location services must be on for Wi-Fi scans on this Android version",
                null
            )
            return
        }

        val wifiManager =
            applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (!wifiManager.isWifiEnabled) {
            pendingScanResult = null
            result.error("wifi_disabled", "Wi-Fi is disabled", null)
            return
        }

        registerScanReceiver(wifiManager)
        val started = wifiManager.startScan()
        if (!started) {
            unregisterScanReceiver()
            pendingScanResult = null
            result.success(scanResults(wifiManager.scanResults))
            return
        }

        handler.postDelayed({
            val pending = pendingScanResult ?: return@postDelayed
            unregisterScanReceiver()
            pendingScanResult = null
            pending.success(scanResults(wifiManager.scanResults))
        }, 10_000)
    }

    private fun registerScanReceiver(wifiManager: WifiManager) {
        unregisterScanReceiver()
        scanReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val pending = pendingScanResult ?: return
                unregisterScanReceiver()
                pendingScanResult = null
                pending.success(scanResults(wifiManager.scanResults))
            }
        }

        val filter = IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(scanReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(scanReceiver, filter)
        }
    }

    private fun unregisterScanReceiver() {
        val receiver = scanReceiver ?: return
        runCatching { unregisterReceiver(receiver) }
        scanReceiver = null
    }

    private fun saveWifiBinding(call: MethodCall, result: MethodChannel.Result) {
        val ssid = call.argument<String>("ssid").orEmpty()
        val bssid = call.argument<String>("bssid").orEmpty()
        val capabilities = call.argument<String>("capabilities").orEmpty()
        val passphrase = call.argument<String>("passphrase").orEmpty()

        if (ssid.isBlank() || bssid.isBlank()) {
            result.error("binding_invalid", "Select a Wi-Fi network first", null)
            return
        }

        getSharedPreferences("golf_edge_wifi", Context.MODE_PRIVATE)
            .edit()
            .putString("ssid", ssid)
            .putString("bssid", bssid)
            .putString("capabilities", capabilities)
            .putString("passphrase", passphrase)
            .apply()

        result.success(null)
    }

    private fun requiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(Manifest.permission.NEARBY_WIFI_DEVICES)
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
    }

    private fun hasWifiScanPermissions(): Boolean {
        return requiredPermissions().all {
            checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun isLocationEnabled(): Boolean {
        val locationManager =
            getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            locationManager.isLocationEnabled
        } else {
            locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    private fun requiresLocationForScan(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU
    }

    private fun scanResults(results: List<ScanResult>): List<Map<String, Any>> {
        return results
            .filter { it.SSID.isNotBlank() }
            .distinctBy { "${it.SSID}|${it.BSSID}" }
            .sortedByDescending { it.level }
            .map {
                mapOf(
                    "ssid" to it.SSID,
                    "bssid" to it.BSSID,
                    "level" to it.level,
                    "frequency" to it.frequency,
                    "capabilities" to it.capabilities
                )
            }
    }
}
