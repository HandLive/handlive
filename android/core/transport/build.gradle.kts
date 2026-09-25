// Khung rỗng: agent A0.2 điền Ktor WSS server, bắt tay phiên, capability, máy trạng thái.
plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "app.handlive.android.core.transport"
    compileSdk = 36

    defaultConfig {
        minSdk = 29
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }
}

kotlin {
    jvmToolchain(21)
}

dependencies {
    api(project(":core:protocol"))
    api(project(":core:crypto"))
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.ktor.server.core)
    implementation(libs.ktor.server.netty) {
        // HTTP/3 (QUIC) không dùng; bỏ thư viện native desktop đi kèm để APK không mang file .so thừa.
        exclude(group = "io.netty", module = "netty-codec-native-quic")
    }
    implementation(libs.ktor.server.websockets)
    implementation(libs.ktor.network.tls.certificates)

    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.ktor.server.test.host)
    testImplementation(libs.ktor.client.websockets)
}
