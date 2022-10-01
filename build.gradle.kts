/*
 * build.gradle.kts
 * dotfiles
 */

/* -------------------------------------------------------------------------- */
// 📋 Properties
/* -------------------------------------------------------------------------- */

val gradleWrapperVersion: String by project

/* -------------------------------------------------------------------------- */
// 🔌 Plugins
/* -------------------------------------------------------------------------- */

plugins {
    // Gradle plugin portal - https://plugins.gradle.org/
    // id("at.phatbl.clamp") version "1.1.1"
    id("at.phatbl.shellexec") version "1.2.0"
}

/* -------------------------------------------------------------------------- */
// ✔️ Tasks
/* -------------------------------------------------------------------------- */

val removeBatchFile by tasks.registering(Delete::class) { delete("gradlew.bat") }

tasks.getByName<Wrapper>("wrapper") {
    gradleVersion = gradleWrapperVersion
    distributionType = Wrapper.DistributionType.BIN
    finalizedBy(removeBatchFile)
}
