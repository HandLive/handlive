/// Enum chuỗi đọc được từ phía có phiên bản mới hơn (0.5.1 quy tắc 6): giá trị không biết giải mã thành
/// `.unrecognized` thay vì làm hỏng cả tin. Bên gửi không bao giờ phát `.unrecognized`.
public protocol LenientStringEnum: RawRepresentable, Decodable where RawValue == String {
    static var unrecognized: Self { get }
}

extension LenientStringEnum {
    public init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = Self(rawValue: raw) ?? .unrecognized
    }
}
