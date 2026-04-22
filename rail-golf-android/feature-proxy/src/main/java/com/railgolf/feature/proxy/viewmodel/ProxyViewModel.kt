package com.railgolf.feature.proxy.viewmodel

import com.railgolf.core.model.ProxyStatus
import com.railgolf.core.piapi.repository.PiRepository

class ProxyViewModel(private val piRepository: PiRepository) {
    fun status(): ProxyStatus = piRepository.proxyStatus()

    fun startProxy() = Unit

    fun stopProxy() = Unit

    fun refreshStatus() = Unit

    fun viewDiscoveryResponse() = piRepository.discoveryInfo()
}
