/// Từng tính năng trong `features` của capability (0.7.2). Chỉ `enabled` bắt buộc.
public struct ClipboardFeature: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var autoSend: Bool?
    public var maxTextBytes: Int64?
    public var maxImageBytes: Int64?
    public var mimes: [String]?

    public init(enabled: Bool, autoSend: Bool? = nil, maxTextBytes: Int64? = nil,
                maxImageBytes: Int64? = nil, mimes: [String]? = nil) {
        self.enabled = enabled
        self.autoSend = autoSend
        self.maxTextBytes = maxTextBytes
        self.maxImageBytes = maxImageBytes
        self.mimes = mimes
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case autoSend = "auto_send"
        case maxTextBytes = "max_text_bytes"
        case maxImageBytes = "max_image_bytes"
        case mimes
    }
}

public struct SimInfo: Codable, Equatable, Sendable {
    public var subId: Int32
    public var slot: Int32
    public var label: String

    enum CodingKeys: String, CodingKey {
        case subId = "sub_id"
        case slot, label
    }
}

public struct SmsFeature: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var canSend: Bool?
    public var sims: [SimInfo]?
    public var defaultSubId: Int32?
    public var notify: Bool?

    public init(enabled: Bool, canSend: Bool? = nil, notify: Bool? = nil) {
        self.enabled = enabled
        self.canSend = canSend
        self.notify = notify
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case canSend = "can_send"
        case sims
        case defaultSubId = "default_sub_id"
        case notify
    }
}

public struct CallFeature: Codable, Equatable, Sendable {
    public var enabled: Bool
    public var canAnswer: Bool?
    public var canEnd: Bool?
    public var callerId: Bool?
    public var notify: Bool?

    public init(enabled: Bool, notify: Bool? = nil) {
        self.enabled = enabled
        self.notify = notify
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case canAnswer = "can_answer"
        case canEnd = "can_end"
        case callerId = "caller_id"
        case notify
    }
}

public struct OpusFallback: Codable, Equatable, Sendable {
    public enum Reason: String, Codable, Sendable {
        case ok, disabled
        case android10 = "android_10"
        case shizukuNotRunning = "shizuku_not_running"
        case captureSilent = "capture_silent"
        case uplinkUnsupported = "uplink_unsupported"
    }

    public var available: Bool
    public var downlink: Bool
    public var uplink: Bool
    public var reason: Reason
}

public struct CallAudioFeature: Codable, Equatable, Sendable {
    public var enabled: Bool
    /// Chỉ Mac, dạng `A1:B2:C3:D4:E5:F6`.
    public var btAddress: String?
    public var hfpConnected: Bool?
    public var consented: Bool?
    public var opusFallback: OpusFallback?

    public init(enabled: Bool, btAddress: String? = nil, consented: Bool? = nil) {
        self.enabled = enabled
        self.btAddress = btAddress
        self.consented = consented
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case btAddress = "bt_address"
        case hfpConnected = "hfp_connected"
        case consented
        case opusFallback = "opus_fallback"
    }
}

public struct CameraFeature: Codable, Equatable, Sendable {
    public enum Facing: String, Codable, Sendable { case front, back }
    public enum Codec: String, Codable, Sendable { case h264 }

    public var enabled: Bool
    public var cameras: [Facing]?
    public var maxWidth: Int32?
    public var maxHeight: Int32?
    public var maxFps: Int32?
    public var codecs: [Codec]?

    public init(enabled: Bool) {
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey {
        case enabled, cameras
        case maxWidth = "max_width"
        case maxHeight = "max_height"
        case maxFps = "max_fps"
        case codecs
    }
}

public struct RelayFeature: Codable, Equatable, Sendable {
    public var enabled: Bool

    public init(enabled: Bool) {
        self.enabled = enabled
    }
}
