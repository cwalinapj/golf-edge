package com.railgolf.core.model

data class ProxyStatus(
    val state: String,
    val piConnected: Boolean,
    val mevoConnected: Boolean,
    val tcp5100Connected: Boolean,
    val tcp1258Connected: Boolean,
)
