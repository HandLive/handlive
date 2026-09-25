package app.handlive.android.core.transport.testing

import app.handlive.android.core.crypto.primitives.SecureRandomBytes
import app.handlive.android.core.protocol.capability.CallFeature
import app.handlive.android.core.protocol.capability.CameraFeature
import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.capability.CapabilityFeatures
import app.handlive.android.core.protocol.capability.ClipboardFeature
import app.handlive.android.core.protocol.capability.RelayFeature
import app.handlive.android.core.protocol.capability.SmsFeature
import app.handlive.android.core.protocol.id.UuidV7Generator
import app.handlive.android.core.transport.handshake.PairRecord
import app.handlive.android.core.transport.server.ControlServer
import app.handlive.android.core.transport.server.ControlServerConfig
import app.handlive.android.core.transport.server.ControlServerOptions
import app.handlive.android.core.transport.server.ControlSession
import app.handlive.android.core.transport.tls.TlsIdentity
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** Server `/v1/ctl` thật (Netty, TLS 1.3, chứng chỉ tự ký) trên loopback, cổng do hệ điều hành cấp. */
class LoopbackServerFixture(
    handshakeTimeout: Duration = 5.seconds,
    rekeyAfterEnvelopes: Long = 10_000,
) : AutoCloseable {
    val serverDeviceId = "39f713d0-a644-853f-8452-9421b9f51b9b"
    val tls: TlsIdentity = sharedIdentity
    val pairs = ConcurrentHashMap<String, PairRecord>()
    val established = LinkedBlockingQueue<ControlSession>()
    val server: ControlServer
    val port: Int

    init {
        val config =
            ControlServerConfig(
                tls = tls,
                localDeviceId = serverDeviceId,
                pairs = { pairs[it] },
                localCapability = { ANDROID_CAPABILITY },
                onSessionEstablished = { established.add(it) },
                options =
                    ControlServerOptions(
                        host = "127.0.0.1",
                        ports = listOf(0),
                        handshakeTimeout = handshakeTimeout,
                        rekeyAfterEnvelopes = rekeyAfterEnvelopes,
                    ),
            )
        server = ControlServer(config)
        port = kotlinx.coroutines.runBlocking { server.start() }
    }

    val url: String get() = "wss://127.0.0.1:$port/v1/ctl"

    /** Thêm một cặp mới với `PRK` ngẫu nhiên và trả client C tương ứng. */
    fun addPair(revoked: Boolean = false): TestClientPeer {
        val pairId = UUID.randomUUID().toString()
        val clientDeviceId = UuidV7Generator().next()
        val prk = SecureRandomBytes.next(PRK_SIZE)
        pairs[pairId] = PairRecord(pairId, clientDeviceId, prk, revoked)
        return TestClientPeer(pairId, clientDeviceId, prk, serverDeviceId)
    }

    /** Phiên vừa bắt tay xong (sau `capability/hello` của client). */
    fun awaitSession(): ControlSession =
        established.poll(WAIT_SECONDS, TimeUnit.SECONDS) ?: error("no session established")

    override fun close() = server.stop()

    companion object {
        private const val PRK_SIZE = 32
        private const val WAIT_SECONDS = 5L

        /** Sinh một lần cho cả lớp test (EC P-256 nhanh, nhưng không cần sinh lại mỗi test). */
        val sharedIdentity: TlsIdentity by lazy { TlsIdentity.generate() }

        /** Android: camera bật nhưng thiếu `CAMERA`; SMS bật; call bật; relay tắt. */
        val ANDROID_CAPABILITY =
            CapabilityData(
                protocol = 1,
                appVersion = "1.0.0 (100)",
                platform = "android",
                osVersion = "15",
                model = "Pixel 8",
                features =
                    CapabilityFeatures(
                        clipboard = ClipboardFeature(enabled = true, autoSend = true),
                        sms = SmsFeature(enabled = true, canSend = true, sims = emptyList()),
                        call = CallFeature(enabled = true, canAnswer = true, canEnd = true, callerId = false),
                        camera = CameraFeature(enabled = true),
                        relay = RelayFeature(enabled = false),
                    ),
                permissionsMissing = listOf("CAMERA", "READ_CALL_LOG"),
            )

        /** Mac: clipboard và camera bật, SMS tắt, call bật, relay bật. */
        val MAC_CAPABILITY =
            CapabilityData(
                protocol = 1,
                appVersion = "1.0.0 (100)",
                platform = "macos",
                osVersion = "15.1",
                model = "MacBookPro18,3",
                features =
                    CapabilityFeatures(
                        clipboard = ClipboardFeature(enabled = true, autoSend = true),
                        sms = SmsFeature(enabled = false),
                        call = CallFeature(enabled = true),
                        camera = CameraFeature(enabled = true),
                        relay = RelayFeature(enabled = true),
                    ),
            )
    }
}
