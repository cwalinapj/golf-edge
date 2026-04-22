package com.railgolf.core.model

data class Recipe(
    val id: String,
    val name: String,
    val steps: List<RecipeStep>,
)
