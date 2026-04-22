package com.railgolf.core.accessibility.matcher

class ResourceIdMatcher(private val expected: String) : NodeMatcher {
    override fun matches(text: String?): Boolean = text == expected
}
