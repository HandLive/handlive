package app.handlive.android.core.transport.server

import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.envelope.Envelope
import app.handlive.android.core.transport.TransportConstants
import app.handlive.android.core.transport.handshake.PairRegistry
import app.handlive.android.core.transport.tls.TlsIdentity
import io.ktor.server.application.install
import io.ktor.server.engine.EmbeddedServer
import io.ktor.server.engine.embeddedServer
import io.ktor.server.engine.sslConnector
import io.ktor.server.netty.Netty
import io.ktor.server.netty.NettyApplicationEngine
import io.ktor.server.routing.routing
import io.ktor.server.websocket.WebSockets
import io.ktor.server.websocket.webSocket
import java.net.BindException
import kotlin.time.Duration

/** Cấu hình WSS server của A-SVC. */
class ControlServerConfig(
    val tls: TlsIdentity,
    val localDeviceId: String,
    val pairs: PairRegistry,
    /** Capability hiện tại của Android (0.7.2); gọi mỗi lần gửi `capability/hello|update`. */
    val localCapability: () -> CapabilityData,
    val onSessionEstablished: (ControlSession) -> Unit = {},
    val options: ControlServerOptions = ControlServerOptions(),
)

/** Tham số mạng và hằng số (0.4.1, 0.10); [ports] mặc định 47800–47809, test truyền `listOf(0)`. */
class ControlServerOptions(
    val host: String = "0.0.0.0",
    val ports: List<Int> = TransportConstants.CTL_PORTS,
    val handshakeTimeout: Duration = TransportConstants.HANDSHAKE_TIMEOUT,
    val rekeyAfterEnvelopes: Long = TransportConstants.REKEY_AFTER_ENVELOPES,
    val clock: () -> Long = System::currentTimeMillis,
)

/**
 * WSS server `/v1/ctl` (Ktor 3, engine Netty — 0.1): chỉ TLS 1.3 với chứng chỉ tự ký của [ControlServerConfig.tls],
 * HTTP/1.1 (tắt HTTP/2 nên không cần ALPN), đường dẫn khác trả 404. mDNS và vòng đời service thuộc Phase 1.
 */
class ControlServer(
    private val config: ControlServerConfig,
) {
    val sessions = ActiveSessionRegistry()
    private val handler = ControlConnectionHandler(config, sessions)
    private var server: EmbeddedServer<NettyApplicationEngine, NettyApplicationEngine.Configuration>? = null

    /** Lắng nghe trên cổng đầu tiên còn trống trong [ControlServerOptions.ports]; trả cổng thực (để quảng bá SRV). */
    suspend fun start(): Int {
        check(server == null) { "server already started" }
        var lastError: BindException? = null
        for (port in config.options.ports) {
            val candidate = create(port)
            try {
                candidate.start(wait = false)
            } catch (e: BindException) {
                candidate.stop(0, 0)
                lastError = e
                continue
            }
            server = candidate
            return candidate.engine
                .resolvedConnectors()
                .first()
                .port
        }
        throw lastError ?: BindException("no port configured")
    }

    fun stop() {
        server?.stop(STOP_GRACE_MILLIS, STOP_TIMEOUT_MILLIS)
        server = null
    }

    private fun create(port: Int) =
        embeddedServer(
            Netty,
            configure = {
                sslConnector(
                    keyStore = config.tls.keyStore,
                    keyAlias = TlsIdentity.ALIAS,
                    keyStorePassword = config.tls::password,
                    privateKeyPassword = config.tls::password,
                ) {
                    this.host = config.options.host
                    this.port = port
                    enabledProtocols = listOf(TLS_1_3)
                }
                enableHttp2 = false
                enableH2c = false
            },
        ) {
            install(WebSockets) {
                // Envelope ≤ 256 KiB (0.5.1); frame lớn hơn bị Ktor đóng 1009.
                maxFrameSize = Envelope.MAX_BYTES.toLong()
            }
            routing {
                webSocket(TransportConstants.CTL_PATH) { handler.handle(this) }
            }
        }

    private companion object {
        const val TLS_1_3 = "TLSv1.3"
        const val STOP_GRACE_MILLIS = 500L
        const val STOP_TIMEOUT_MILLIS = 2_000L
    }
}
