package app.handlive.android.core.design.component

/** Kiểu nút theo `components/Button/README.md`. Mỗi màn tối đa một nút [Prominent]. */
enum class HLButtonStyle {
    /** Hành động chính: nền `accent-fill`, chữ `on-accent`, cao 50 dp. */
    Prominent,

    /** Hành động phụ cạnh nút chính: nền `glass-fill`, viền `glass-stroke`. */
    Glass,

    /** Nên thấy nhưng không phải chính ("Mở cài đặt"): nền `accent-tint`, chữ `accent`. */
    Tinted,

    /** Liên kết, lệnh phụ: chỉ chữ `accent`. */
    Plain,

    /** Hủy ghép nối, xóa: chữ `destructive-text` trên nền kính như [Glass]; không bao giờ là nút chính. */
    Destructive,
}
