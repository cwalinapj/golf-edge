package com.railgolf.core.common

sealed interface RailGolfResult<out T> {
    data class Success<T>(val value: T) : RailGolfResult<T>
    data class Failure(val message: String) : RailGolfResult<Nothing>
}
