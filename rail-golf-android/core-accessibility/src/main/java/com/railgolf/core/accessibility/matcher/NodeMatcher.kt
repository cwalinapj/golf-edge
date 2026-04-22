package com.railgolf.core.accessibility.matcher

interface NodeMatcher {
    fun matches(text: String?): Boolean
}
