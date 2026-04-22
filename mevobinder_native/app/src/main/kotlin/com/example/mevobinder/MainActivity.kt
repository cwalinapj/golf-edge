package com.example.mevobinder

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ListView
import android.widget.TextView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class MainActivity : AppCompatActivity() {

    private lateinit var wifiManager: WifiManager
    private lateinit var btnScan: Button
    private lateinit var btnBind: Button
    private lateinit var txtStatus: TextView
    private lateinit var txtSelected: TextView
    private lateinit var listNetworks: ListView

    private val results = mutableListOf<WifiTarget>()
    private lateinit var adapter: ArrayAdapter<WifiTarget>

    private var selected: WifiTarget? = null

    private val wifiScanReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val success = intent?.getBooleanExtra(WifiManager.EXTRA_RESULTS_UPDATED, false) ?: false
            if (success) {
                loadScanResults("Scan complete")
            } else {
                // Android docs note these may be older cached results if the new scan failed.
                loadScanResults("Scan finished, using latest available results")
            }
        }
    }

    private val permissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { grants ->
            val allGranted = grants.values.all { it }
            if (allGranted) {
                startWifiScan()
            } else {
                txtStatus.text = "Status: permission denied"
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        applySystemBarInsets()

        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

        btnScan = findViewById(R.id.btnScan)
        btnBind = findViewById(R.id.btnBind)
        txtStatus = findViewById(R.id.txtStatus)
        txtSelected = findViewById(R.id.txtSelected)
        listNetworks = findViewById(R.id.listNetworks)

        adapter = ArrayAdapter(this, android.R.layout.simple_list_item_single_choice, results)
        listNetworks.adapter = adapter

        listNetworks.setOnItemClickListener { _, _, position, _ ->
            selected = results[position]
            txtSelected.text = "Selected: ${selected!!.ssid} | ${selected!!.bssid}"
        }

        btnScan.setOnClickListener {
            ensurePermissionsThenScan()
        }

        btnBind.setOnClickListener {
            saveSelected()
        }

        loadSavedBinding()
    }

    override fun onStart() {
        super.onStart()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(
                wifiScanReceiver,
                IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION),
                RECEIVER_NOT_EXPORTED
            )
        } else {
            registerReceiver(
                wifiScanReceiver,
                IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
            )
        }
    }

    override fun onStop() {
        super.onStop()
        unregisterReceiver(wifiScanReceiver)
    }

    private fun ensurePermissionsThenScan() {
        if (!isLocationEnabled()) {
            txtStatus.text = "Status: enable Location in system settings, then scan again"
            startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
            return
        }

        val needed = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.NEARBY_WIFI_DEVICES
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                needed.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            }
        }

        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            needed.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }

        if (needed.isNotEmpty()) {
            permissionLauncher.launch(needed.toTypedArray())
        } else {
            startWifiScan()
        }
    }

    private fun startWifiScan() {
        txtStatus.text = "Status: scanning..."
        try {
            val ok = wifiManager.startScan()
            if (!ok) {
                // Android docs: startScan can fail because of throttling, idle mode, or Wi-Fi/hardware failure.
                txtStatus.text = "Status: startScan failed (possibly throttled); loading latest available results"
                loadScanResults("Using latest available results")
            }
        } catch (e: SecurityException) {
            txtStatus.text = "Status: security exception: ${e.message}"
        } catch (e: Exception) {
            txtStatus.text = "Status: scan failed: ${e.message}"
        }
    }

    private fun loadScanResults(statusMessage: String) {
        try {
            val scanResults = wifiManager.scanResults

            results.clear()

            scanResults
                .filter { it.SSID.isNotBlank() }
                .sortedByDescending { it.level }
                .forEach {
                    results.add(
                        WifiTarget(
                            ssid = it.SSID,
                            bssid = it.BSSID,
                            rssi = it.level
                        )
                    )
                }

            adapter.notifyDataSetChanged()
            txtStatus.text = "Status: $statusMessage (${results.size} networks)"
        } catch (e: SecurityException) {
            txtStatus.text = "Status: could not read scan results: ${e.message}"
        }
    }

    private fun saveSelected() {
        val s = selected
        if (s == null) {
            txtStatus.text = "Status: select a network first"
            return
        }

        val prefs = getSharedPreferences("mevo_bind", MODE_PRIVATE)
        prefs.edit()
            .putString("ssid", s.ssid)
            .putString("bssid", s.bssid)
            .putInt("rssi", s.rssi)
            .putLong("saved_at", System.currentTimeMillis())
            .apply()

        txtSelected.text = "Selected: ${s.ssid} | ${s.bssid}"
        txtStatus.text = "Status: binding saved"
    }

    private fun loadSavedBinding() {
        val prefs = getSharedPreferences("mevo_bind", MODE_PRIVATE)
        val ssid = prefs.getString("ssid", null)
        val bssid = prefs.getString("bssid", null)

        if (!ssid.isNullOrBlank() && !bssid.isNullOrBlank()) {
            txtSelected.text = "Selected: $ssid | $bssid"
            txtStatus.text = "Status: loaded saved binding"
        }
    }

    private fun isLocationEnabled(): Boolean {
        return try {
            val mode = Settings.Secure.getInt(
                contentResolver,
                Settings.Secure.LOCATION_MODE
            )
            mode != Settings.Secure.LOCATION_MODE_OFF
        } catch (_: Exception) {
            false
        }
    }

    private fun applySystemBarInsets() {
        val root = findViewById<android.view.View>(R.id.root)
        ViewCompat.setOnApplyWindowInsetsListener(root) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            view.setPadding(0, bars.top, 0, bars.bottom)
            insets
        }
    }
}
