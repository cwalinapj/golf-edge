package com.example.mevobinder

data class WifiTarget(
    val ssid: String,
    val bssid: String,
    val rssi: Int
) {
    override fun toString(): String = "$ssid | $bssid | RSSI $rssi"
}
