/*
 * settings.gradle.kts
 * dotfiles
 */

rootProject.name = "dotfiles"

val clamp = file("dev/gradle/Clamp")
if (clamp.exists()) {
    includeBuild(clamp) {
        dependencySubstitution {
            substitute(module("at.phatbl:clamp")).with(project(":"))
        }
    }
}

pluginManagement {
    repositories {
        gradlePluginPortal()
    }
    resolutionStrategy {
        eachPlugin {
            when (requested.id.id) {
                "at.phatbl.clamp" ->
                    useModule("at.phatbl:clamp:${requested.version}")
                else -> Unit
            }
        }
    }
}