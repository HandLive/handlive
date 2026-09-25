plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "app.handlive.android.core.crypto"
    compileSdk = 36

    defaultConfig {
        minSdk = 29
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    testOptions {
        unitTests.all { test ->
            val sharedDir = rootProject.layout.projectDirectory.dir("../shared")
            // Chỉ theo dõi file vector đầu vào; envelope-roundtrip.json là đầu ra của chính test này.
            test.inputs
                .files(fileTree(sharedDir.dir("test-vectors")) { exclude("envelope-roundtrip.json") })
                .withPropertyName("testVectors")
                .withPathSensitivity(PathSensitivity.RELATIVE)
            test.systemProperty("hl.shared.dir", sharedDir.asFile.absolutePath)
            // HL_WRITE_ROUNDTRIP=1 → ghi lại shared/test-vectors/envelope-roundtrip.json.
            val writeRoundtrip = providers.environmentVariable("HL_WRITE_ROUNDTRIP").orElse("")
            test.inputs.property("writeRoundtrip", writeRoundtrip)
            test.environment("HL_WRITE_ROUNDTRIP", writeRoundtrip.get())
        }
    }
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    api(project(":core:protocol"))
    implementation(libs.tink.android)

    testImplementation(libs.junit)
    testImplementation(testFixtures(project(":core:protocol")))
}
