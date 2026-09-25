// Design system Android: HandLiveTheme sinh từ shared/design-tokens/tokens.json + thành phần Compose kiểu Apple.
import app.handlive.buildlogic.designtokens.GenerateHandLiveThemeTask

plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
}

val generatedThemeDir = layout.buildDirectory.dir("generated/source/handLiveTheme")

android {
    namespace = "app.handlive.android.core.design"
    compileSdk = 36

    defaultConfig {
        minSdk = 29
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests {
            // Robolectric cần tài nguyên Android (font, chuỗi) khi dựng Compose trên JVM.
            isIncludeAndroidResources = true
            all { test ->
                val sharedDir = rootProject.layout.projectDirectory.dir("../shared")
                val docsDir = rootProject.layout.projectDirectory.dir("../docs/design-system")
                test.inputs.file(sharedDir.file("design-tokens/tokens.json")).withPathSensitivity(PathSensitivity.NONE)
                test.inputs.dir(docsDir.dir("1-foundations")).withPathSensitivity(PathSensitivity.RELATIVE)
                test.systemProperty("hl.shared.dir", sharedDir.asFile.absolutePath)
                test.systemProperty("hl.docs.dir", docsDir.asFile.absolutePath)
                test.systemProperty("hl.main.source.dir", file("src/main").absolutePath)
                test.systemProperty("hl.generated.source.dir", generatedThemeDir.get().asFile.absolutePath)
            }
        }
    }
}

kotlin {
    jvmToolchain(21)
}

// Mã HandLiveTheme sinh vào build/ (không commit) ở mỗi lần biên dịch, nên luôn khớp tokens.json.
val generateHandLiveTheme =
    tasks.register<GenerateHandLiveThemeTask>("generateHandLiveTheme") {
        tokensFile.set(rootProject.layout.projectDirectory.file("../shared/design-tokens/tokens.json"))
        packageName.set("app.handlive.android.core.design.theme")
        outputDirectory.set(generatedThemeDir)
    }

androidComponents {
    onVariants { variant ->
        variant.sources.kotlin?.addGeneratedSourceDirectory(
            generateHandLiveTheme,
            GenerateHandLiveThemeTask::outputDirectory,
        )
    }
}

dependencies {
    api(platform(libs.compose.bom))
    api(libs.compose.ui)
    api(libs.compose.foundation)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.serialization.json)
    testImplementation(libs.robolectric)
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi.compose)
    debugImplementation(libs.compose.ui.test.manifest)
}
