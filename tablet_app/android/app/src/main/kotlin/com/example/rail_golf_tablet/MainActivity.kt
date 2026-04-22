package com.example.rail_golf_tablet

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.ScanResult
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.net.wifi.WifiNetworkSuggestion
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "rail_golf/wifi_scan"
    private val controllerWifiChannelName = "rail_golf/controller_wifi"
    private val permissionRequestCode = 4401
    private val handler = Handler(Looper.getMainLooper())

    private var pendingScanResult: MethodChannel.Result? = null
    private var scanReceiver: BroadcastReceiver? = null
    private var pendingControllerResult: MethodChannel.Result? = null
    private var controllerNetworkCallback: ConnectivityManager.NetworkCallback? = null

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, controllerWifiChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveControllerNetwork" -> saveControllerNetwork(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        unregisterScanReceiver()
        clearControllerNetworkCallback()
        pendingScanResult = null
        pendingControllerResult = null
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
        val ownerKey = call.argument<String>("ownerKey").orEmpty()
        val persist = call.argument<Boolean>("persist") ?: true

        if (ssid.isBlank() || bssid.isBlank()) {
            result.error("binding_invalid", "Select a Wi-Fi network first", null)
            return
        }

        if (secured(capabilities) && passphrase.isBlank()) {
            result.error("passphrase_required", "Enter the Wi-Fi passcode", null)
            return
        }

        if (persist) {
            val bindingOwner = ownerKey.ifBlank { "default" }
            getSharedPreferences("rail_golf_wifi_$bindingOwner", Context.MODE_PRIVATE)
                .edit()
                .putString("ssid", ssid)
                .putString("bssid", bssid)
                .putString("capabilities", capabilities)
                .putString("passphrase", passphrase)
                .apply()
        }

        result.success(null)
    }

    private fun secured(capabilities: String): Boolean {
        return capabilities.contains("WEP") ||
            capabilities.contains("WPA") ||
            capabilities.contains("SAE")
    }

    private fun saveControllerNetwork(call: MethodCall, result: MethodChannel.Result) {
        val ssid = call.argument<String>("ssid").orEmpty()
        val password = call.argument<String>("password").orEmpty()
        if (pendingControllerResult != null) {
            result.error("controller_connect_in_progress", "Already connecting to the controller", null)
            return
        }
        if (ssid.isBlank()) {
            result.error("controller_ssid_required", "Enter the controller network name", null)
            return
        }
        if (password.length < 8) {
            result.error("controller_password_invalid", "Password must be at least 8 characters", null)
            return
        }

        val wifiManager =
            applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveControllerSuggestion(wifiManager, ssid, password)

            val connectivityManager =
                getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val specifier = WifiNetworkSpecifier.Builder()
                .setSsid(ssid)
                .setWpa2Passphrase(password)
                .build()
            val request = NetworkRequest.Builder()
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .setNetworkSpecifier(specifier)
                .build()
            val callback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    handler.post {
                        val pending = pendingControllerResult ?: return@post
                        pendingControllerResult = null
                        connectivityManager.bindProcessToNetwork(network)
                        pending.success(null)
                    }
                }

                override fun onUnavailable() {
                    handler.post {
                        val pending = pendingControllerResult ?: return@post
                        clearControllerNetworkCallback()
                        pendingControllerResult = null
                        pending.error(
                            "controller_unavailable",
                            "Rail Golf Controller network was not available. Check wlan1 and the password.",
                            null
                        )
                    }
                }
            }

            pendingControllerResult = result
            controllerNetworkCallback = callback
            connectivityManager.requestNetwork(request, callback)
            handler.postDelayed({
                val pending = pendingControllerResult ?: return@postDelayed
                clearControllerNetworkCallback()
                pendingControllerResult = null
                pending.error(
                    "controller_timeout",
                    "Timed out connecting to the Rail Golf Controller network",
                    null
                )
            }, 30_000)
            return
        }

        @Suppress("DEPRECATION")
        val config = WifiConfiguration().apply {
            SSID = "\"$ssid\""
            preSharedKey = "\"$password\""
            allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK)
        }
        @Suppress("DEPRECATION")
        val networkId = wifiManager.addNetwork(config)
        if (networkId == -1) {
            result.error(
                "controller_network_not_saved",
                "Android could not save the Rail Golf Controller network",
                null
            )
            return
        }
        @Suppress("DEPRECATION")
        wifiManager.enableNetwork(networkId, true)
        @Suppress("DEPRECATION")
        wifiManager.reconnect()
        result.success(null)
    }

    private fun saveControllerSuggestion(
        wifiManager: WifiManager,
        ssid: String,
        password: String
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val suggestion = WifiNetworkSuggestion.Builder()
                .setSsid(ssid)
                .setWpa2Passphrase(password)
                .setIsAppInteractionRequired(false)
                .build()
            wifiManager.removeNetworkSuggestions(listOf(suggestion))
            wifiManager.addNetworkSuggestions(listOf(suggestion))
        }
    }

    private fun clearControllerNetworkCallback() {
        val callback = controllerNetworkCallback ?: return
        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        runCatching { connectivityManager.unregisterNetworkCallback(callback) }
        controllerNetworkCallback = null
    }

    private fun requiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.NEARBY_WIFI_DEVICES,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
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
        return true
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
