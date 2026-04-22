package com.example.mevobinder

data class WifiTarget(
    val ssid: String,
    val bssid: String,
    val rssi: Int,
    val frequencyMhz: Int
) {
    override fun toString(): String = "$ssid | $bssid | ${frequencyMhz}MHz | RSSI $rssi"
}
