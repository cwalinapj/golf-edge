package com.railgolf.core.piapi.api

import com.railgolf.core.piapi.dto.DiscoveryInfoDto
import com.railgolf.core.piapi.dto.ProxyStatusDto
import com.railgolf.core.piapi.dto.ServiceStateDto

class PiApiService(private val baseUrl: String) {
    fun status(): ServiceStateDto {
        return ServiceStateDto(online = true, detail = baseUrl)
    }

    fun proxyStatus(): ProxyStatusDto {
        return ProxyStatusDto(
            state = "unknown",
            mevoConnected = false,
            clientConnected = false,
            openPorts = emptyList(),
        )
    }

    fun discoveryInfo(): DiscoveryInfoDto {
        return DiscoveryInfoDto(ssid = null, bssid = null, ipAddress = null)
    }
}
