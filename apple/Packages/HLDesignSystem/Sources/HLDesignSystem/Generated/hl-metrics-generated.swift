// Tệp sinh tự động bởi Scripts/generate-design-tokens.py từ shared/design-tokens/tokens.json.
// Không sửa tay: sửa tokens.json rồi chạy lại script (kiểm bằng --check).
import CoreGraphics

/// Khoảng cách (pt), lưới 4 pt.
public enum HLSpacing {
    /// Khe giữa biểu tượng và chữ nhỏ.
    public static let space4: CGFloat = 4
    /// Khe giữa các phần tử trong một dòng.
    public static let space8: CGFloat = 8
    /// Đệm quanh control có viền (HIG: ~12 pt).
    public static let space12: CGFloat = 12
    /// Đệm trong thẻ, khe giữa các dòng nội dung.
    public static let space16: CGFloat = 16
    /// Lề nội dung cửa sổ Mac; khe giữa các nhóm cài đặt.
    public static let space20: CGFloat = 20
    /// Đệm quanh control không viền (HIG: ~24 pt); khe giữa hai nút tròn cuộc gọi.
    public static let space24: CGFloat = 24
    /// Khe giữa các khối lớn trên màn chào.
    public static let space32: CGFloat = 32
    /// Lề trên của tiêu đề màn chào.
    public static let space40: CGFloat = 40
    /// Lề màn hình iPhone và Android (mặc định layoutMargins compact).
    public static let marginCompact: CGFloat = 16
    /// Lề màn hình iPad và cửa sổ rộng.
    public static let marginRegular: CGFloat = 20
}

/// Bo góc (pt) cho control tự dựng, macOS 13–15 / iOS 16–18.
public enum HLRadius {
    /// Nút push, ô nhập trên macOS 13–15.
    public static let controlMac: CGFloat = 6
    /// Nhóm danh sách inset (iOS 16–18), vùng chọn trong sidebar.
    public static let row: CGFloat = 10
    /// Thẻ trong lớp nội dung, alert iOS 16–18.
    public static let card: CGFloat = 14
    /// Menu, popover, thông báo, panel cuộc gọi (kính).
    public static let panel: CGFloat = 18
    /// Sheet, nhóm danh sách thời Liquid Glass, cửa sổ Mac 26.
    public static let sheet: CGFloat = 26
    /// Nút capsule, công tắc, huy hiệu, thanh tab nổi.
    public static let capsule: CGFloat = 999
}

/// Kích thước tối thiểu và kích thước cố định (pt).
public enum HLSize {
    /// Vùng chạm mặc định iOS/iPadOS (tối thiểu size-hit-ios-min).
    public static let hitIos: CGFloat = 44
    /// Vùng chạm tối thiểu iOS/iPadOS.
    public static let hitIosMin: CGFloat = 28
    /// Control mặc định macOS (tối thiểu size-hit-mac-min).
    public static let hitMac: CGFloat = 28
    /// Control tối thiểu macOS.
    public static let hitMacMin: CGFloat = 20
    /// Vùng chạm tối thiểu Android (48 dp).
    public static let hitAndroid: CGFloat = 48
    /// Chiều cao menu bar macOS.
    public static let menuBar: CGFloat = 24
    /// Avatar chữ cái trong danh sách hội thoại (Mac 32, iOS 40).
    public static let avatar: CGFloat = 40
    /// Nút tròn Trả lời, Từ chối, Kết thúc.
    public static let callButton: CGFloat = 48
    /// Cạnh mã QR ghép nối trên Mac.
    public static let qr: CGFloat = 220
}

/// Thời lượng (giây); Apple ưu tiên spring của hệ thống.
public enum HLDuration {
    /// Nhấn, hover, đổi màu.
    public static let quick: Double = 0.15
    /// Công tắc, segmented, đổi trạng thái.
    public static let standard: Double = 0.25
    /// Sheet, panel, chuyển màn.
    public static let emphasized: Double = 0.4
    /// Nhịp chấm Đang kết nối và Đang phát camera.
    public static let pulse: Double = 1.5
}
