plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "app.handlive.android.core.protocol"
    compileSdk = 36

    defaultConfig {
        minSdk = 29
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    // Tiện ích đọc shared/test-vectors dùng chung cho test của core:protocol và core:crypto.
    testFixtures {
        enable = true
    }

    testOptions {
        unitTests.all { test ->
            // Test đọc thẳng shared/test-vectors và shared/schemas (nguồn chung Kotlin ↔ Swift ↔ Rust).
            val sharedDir = rootProject.layout.projectDirectory.dir("../shared")
            test.inputs
                .dir(sharedDir)
                .withPropertyName("sharedDir")
                .withPathSensitivity(PathSensitivity.RELATIVE)
            test.systemProperty("hl.shared.dir", sharedDir.asFile.absolutePath)
        }
    }
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    api(libs.kotlinx.serialization.json)

    testFixturesImplementation(libs.kotlinx.serialization.json)
    testFixturesImplementation(libs.junit)

    testImplementation(libs.junit)
    testImplementation(libs.json.schema.validator)
}
