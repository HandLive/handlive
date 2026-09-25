package app.handlive.android.core.protocol

import kotlinx.serialization.json.Json

/**
 * Cấu hình JSON dùng chung cho mọi tin: dạng gọn, giữ thứ tự khai báo trường, không ghi giá trị mặc định
 * (trường tùy chọn vắng mặt thay vì `null`), bỏ qua trường lạ để tương thích phiên bản sau.
 */
val ProtocolJson: Json =
    Json {
        encodeDefaults = false
        ignoreUnknownKeys = true
        prettyPrint = false
    }
