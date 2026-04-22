package com.railgolf.core.piapi.repository

import com.railgolf.core.model.MevoDiscoveryInfo
import com.railgolf.core.model.ProxyStatus
import com.railgolf.core.piapi.api.PiApiService

class PiRepository(private val apiService: PiApiService) {
    fun isOnline(): Boolean = apiService.status().online

    fun proxyStatus(): ProxyStatus {
        val dto = apiService.proxyStatus()
        return ProxyStatus(
            state = dto.state,
            piConnected = isOnline(),
            mevoConnected = dto.mevoConnected,
            tcp5100Connected = 5100 in dto.openPorts,
            tcp1258Connected = 1258 in dto.openPorts,
        )
    }

    fun discoveryInfo(): MevoDiscoveryInfo {
        val dto = apiService.discoveryInfo()
        return MevoDiscoveryInfo(
            ssid = dto.ssid,
            bssid = dto.bssid,
            ipAddress = dto.ipAddress,
        )
    }
}
