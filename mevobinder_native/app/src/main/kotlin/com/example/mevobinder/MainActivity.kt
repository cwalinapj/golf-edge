package com.example.mevobinder

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.MacAddress
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiNetworkSpecifier
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.text.InputType
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class MainActivity : AppCompatActivity() {

    private lateinit var wifiManager: WifiManager
    private lateinit var btnScan: Button
    private lateinit var btnBind: Button
    private lateinit var btnWalletLogin: Button
    private lateinit var btnGuestLogin: Button
    private lateinit var loginContainer: LinearLayout
    private lateinit var binderContainer: LinearLayout
    private lateinit var txtStatus: TextView
    private lateinit var txtSelected: TextView
    private lateinit var txtWallet: TextView
    private lateinit var txtWalletStatus: TextView
    private lateinit var listNetworks: ListView

    private val results = mutableListOf<WifiTarget>()
    private lateinit var adapter: ArrayAdapter<WifiTarget>
    private val mainHandler = Handler(Looper.getMainLooper())

    private var selected: WifiTarget? = null
    private var activeNetworkCallback: ConnectivityManager.NetworkCallback? = null

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
        btnWalletLogin = findViewById(R.id.btnWalletLogin)
        btnGuestLogin = findViewById(R.id.btnGuestLogin)
        loginContainer = findViewById(R.id.loginContainer)
        binderContainer = findViewById(R.id.binderContainer)
        txtStatus = findViewById(R.id.txtStatus)
        txtSelected = findViewById(R.id.txtSelected)
        txtWallet = findViewById(R.id.txtWallet)
        txtWalletStatus = findViewById(R.id.txtWalletStatus)
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
            promptForPasswordAndConnect()
        }

        btnWalletLogin.setOnClickListener {
            loginWithWalletConnect()
        }

        btnGuestLogin.setOnClickListener {
            showBinder("Guest")
            txtWalletStatus.text = "Guest: session only"
        }

        loadWalletSession()
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

    override fun onDestroy() {
        clearActiveNetworkRequest()
        super.onDestroy()
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

    private fun loginWithWalletConnect() {
        txtWalletStatus.text = "WalletConnect: use the Rail Golf app login flow"
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
                .filter { it.frequency in 2400..2500 }
                .sortedByDescending { it.level }
                .forEach {
                    results.add(
                        WifiTarget(
                            ssid = it.SSID,
                            bssid = it.BSSID,
                            rssi = it.level,
                            frequencyMhz = it.frequency
                        )
                    )
                }

            adapter.notifyDataSetChanged()
            txtStatus.text = "Status: $statusMessage (${results.size} 2.4 GHz networks)"
        } catch (e: SecurityException) {
            txtStatus.text = "Status: could not read scan results: ${e.message}"
        }
    }

    private fun promptForPasswordAndConnect() {
        val s = selected
        if (s == null) {
            txtStatus.text = "Status: select a network first"
            return
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            txtStatus.text = "Status: bind-connect requires Android 10 or newer"
            return
        }

        val passwordInput = EditText(this)
        passwordInput.hint = "Wi-Fi password"
        passwordInput.inputType =
            InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD

        AlertDialog.Builder(this)
            .setTitle("Bind ${s.ssid}")
            .setMessage("Connect to ${s.bssid}. Binding saves only after connection succeeds.")
            .setView(passwordInput)
            .setNegativeButton("Cancel", null)
            .setPositiveButton("Connect") { _, _ ->
                connectThenSave(s, passwordInput.text?.toString().orEmpty())
            }
            .show()
    }

    private fun connectThenSave(target: WifiTarget, passphrase: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            txtStatus.text = "Status: bind-connect requires Android 10 or newer"
            return
        }

        clearActiveNetworkRequest()
        btnBind.isEnabled = false
        val previousWifi = currentWifiLabel()
        txtStatus.text = "Status: connecting to ${target.ssid}..."

        val specifierBuilder = WifiNetworkSpecifier.Builder()
            .setSsid(target.ssid)
            .setBssid(MacAddress.fromString(target.bssid))

        if (passphrase.isNotBlank()) {
            specifierBuilder.setWpa2Passphrase(passphrase)
        }

        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .setNetworkSpecifier(specifierBuilder.build())
            .build()

        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                runOnUiThread {
                    saveBinding(target, passphrase, previousWifi)
                    txtSelected.text = "Selected: ${target.ssid} | ${target.bssid}"
                    txtStatus.text = "Status: connected, saved, returning to previous Wi-Fi"
                    btnBind.isEnabled = true
                    reportReturnToPreviousWifi(previousWifi)
                }
            }

            override fun onUnavailable() {
                runOnUiThread {
                    txtStatus.text = "Status: connection failed; binding not saved"
                    btnBind.isEnabled = true
                    clearActiveNetworkRequest()
                }
            }

            override fun onLost(network: Network) {
                runOnUiThread {
                    txtStatus.text = "Status: connection lost"
                    btnBind.isEnabled = true
                }
            }
        }

        activeNetworkCallback = callback
        try {
            connectivityManager.requestNetwork(request, callback, 30_000)
        } catch (e: SecurityException) {
            txtStatus.text = "Status: connection permission error: ${e.message}"
            btnBind.isEnabled = true
            clearActiveNetworkRequest()
        } catch (e: Exception) {
            txtStatus.text = "Status: connection failed: ${e.message}"
            btnBind.isEnabled = true
            clearActiveNetworkRequest()
        }
    }

    private fun saveBinding(s: WifiTarget, passphrase: String, previousWifi: String) {
        // Releasing the app-scoped WifiNetworkSpecifier request lets Android
        // fall back to the default/previous Wi-Fi after the 4-way handshake.
        clearActiveNetworkRequest()

        val prefs = getSharedPreferences("mevo_bind", MODE_PRIVATE)
        prefs.edit()
            .putString("ssid", s.ssid)
            .putString("bssid", s.bssid)
            .putInt("rssi", s.rssi)
            .putInt("frequency_mhz", s.frequencyMhz)
            .putString("passphrase", passphrase)
            .putString("previous_wifi", previousWifi)
            .putBoolean("connection_validated", true)
            .putLong("saved_at", System.currentTimeMillis())
            .apply()
    }

    private fun loadSavedBinding() {
        val prefs = getSharedPreferences("mevo_bind", MODE_PRIVATE)
        val validated = prefs.getBoolean("connection_validated", false)
        val ssid = prefs.getString("ssid", null)
        val bssid = prefs.getString("bssid", null)

        if (validated && !ssid.isNullOrBlank() && !bssid.isNullOrBlank()) {
            txtSelected.text = "Selected: $ssid | $bssid"
            txtStatus.text = "Status: loaded saved binding"
        }
    }

    private fun saveWalletSession(walletAddress: String) {
        getSharedPreferences("mevo_wallet", MODE_PRIVATE)
            .edit()
            .putString("wallet_address", walletAddress)
            .putLong("wallet_connected_at", System.currentTimeMillis())
            .apply()
    }

    private fun loadWalletSession() {
        val walletAddress = getSharedPreferences("mevo_wallet", MODE_PRIVATE)
            .getString("wallet_address", null)
        if (!walletAddress.isNullOrBlank()) {
            showBinder(walletAddress)
        } else {
            loginContainer.visibility = android.view.View.VISIBLE
            binderContainer.visibility = android.view.View.GONE
        }
    }

    private fun showBinder(walletAddress: String) {
        txtWallet.text = "Wallet: ${shortWallet(walletAddress)}"
        loginContainer.visibility = android.view.View.GONE
        binderContainer.visibility = android.view.View.VISIBLE
    }

    private fun shortWallet(walletAddress: String): String {
        return if (walletAddress.length > 12) {
            "${walletAddress.take(6)}...${walletAddress.takeLast(6)}"
        } else {
            walletAddress
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

    private fun clearActiveNetworkRequest() {
        val callback = activeNetworkCallback ?: return
        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        runCatching { connectivityManager.unregisterNetworkCallback(callback) }
        connectivityManager.bindProcessToNetwork(null)
        activeNetworkCallback = null
    }

    private fun currentWifiLabel(): String {
        return try {
            val info = wifiManager.connectionInfo
            val ssid = info.ssid?.trim('"').orEmpty()
            val bssid = info.bssid.orEmpty()
            when {
                ssid.isNotBlank() && bssid.isNotBlank() -> "$ssid | $bssid"
                ssid.isNotBlank() -> ssid
                else -> "previous/default Wi-Fi"
            }
        } catch (_: Exception) {
            "previous/default Wi-Fi"
        }
    }

    private fun reportReturnToPreviousWifi(previousWifi: String) {
        mainHandler.postDelayed({
            val current = currentWifiLabel()
            txtStatus.text = if (current == previousWifi) {
                "Status: binding saved; rejoined $current"
            } else {
                "Status: binding saved; current Wi-Fi $current"
            }
        }, 5_000)
    }
}
