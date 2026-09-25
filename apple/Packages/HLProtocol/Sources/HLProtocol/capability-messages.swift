/// `data` của `capability` op `hello`/`update` (0.7.2). `update` luôn là ảnh chụp đầy đủ cùng cấu trúc.
/// Tính năng nền tảng không có thì vắng mặt trong `features`; trường "chỉ Android/Mac/iOS" là tùy chọn.
public enum CapabilityOp: String, Sendable {
    case hello, update
}

public struct CapabilityData: Codable, Equatable, Sendable {
    public enum Platform: String, Codable, Sendable, LenientStringEnum {
        case android, macos, ios, ipados
        case unrecognized = ""
    }

    public let protocolVersion: Int32
    public let appVersion: String
    public let platform: Platform
    public let osVersion: String
    public let model: String
    public let features: Features
    public let permissionsMissing: [String]?

    public init(protocolVersion: Int32 = currentProtocolVersion, appVersion: String, platform: Platform,
                osVersion: String, model: String, features: Features, permissionsMissing: [String]? = nil) {
        self.protocolVersion = protocolVersion
        self.appVersion = appVersion
        self.platform = platform
        self.osVersion = osVersion
        self.model = model
        self.features = features
        self.permissionsMissing = permissionsMissing
    }

    enum CodingKeys: String, CodingKey {
        case protocolVersion = "protocol"
        case appVersion = "app_version"
        case platform
        case osVersion = "os_version"
        case model, features
        case permissionsMissing = "permissions_missing"
    }
}

public struct Features: Codable, Equatable, Sendable {
    public var clipboard: ClipboardFeature?
    public var sms: SmsFeature?
    public var call: CallFeature?
    public var callAudio: CallAudioFeature?
    public var camera: CameraFeature?
    public var relay: RelayFeature?

    public init(clipboard: ClipboardFeature? = nil, sms: SmsFeature? = nil, call: CallFeature? = nil,
                callAudio: CallAudioFeature? = nil, camera: CameraFeature? = nil, relay: RelayFeature? = nil) {
        self.clipboard = clipboard
        self.sms = sms
        self.call = call
        self.callAudio = callAudio
        self.camera = camera
        self.relay = relay
    }

    enum CodingKeys: String, CodingKey {
        case clipboard, sms, call
        case callAudio = "call_audio"
        case camera, relay
    }
}
