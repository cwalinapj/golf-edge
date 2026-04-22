package com.railgolf.core.piapi.dto

data class ProxyStatusDto(
    val state: String,
    val mevoConnected: Boolean,
    val clientConnected: Boolean,
    val openPorts: List<Int>,
)
