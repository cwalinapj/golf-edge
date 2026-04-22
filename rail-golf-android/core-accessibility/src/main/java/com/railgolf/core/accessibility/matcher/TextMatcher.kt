package com.railgolf.core.accessibility.matcher

class TextMatcher(private val expected: String) : NodeMatcher {
    override fun matches(text: String?): Boolean = text?.contains(expected, ignoreCase = true) == true
}
