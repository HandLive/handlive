package app.handlive.android.core.protocol

import app.handlive.android.core.protocol.ack.Ack
import app.handlive.android.core.protocol.capability.CapabilityData
import app.handlive.android.core.protocol.envelope.EnvelopeCodec
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/** 0.5.1 quy tắc 6: trong cùng major `protocol`, bên nhận bỏ qua trường lạ và không hỏng tin vì giá trị lạ. */
class ForwardCompatibilityTest {
    @Test
    fun envelopeWithUnknownFieldStillDecodes() {
        val id = "0192f3c1-7c1e-7a55-9d0b-3f4c2a1b9e10"
        val envelope = EnvelopeCodec.decode("""{"v":1,"type":"sms","id":"$id","ts":1,"payload":"AAAA","x":1}""")
        assertEquals(id, envelope.id)
    }

    @Test
    fun ackWithNewerErrorCodeKeepsRawCode() {
        val ack =
            ProtocolJson.decodeFromString(
                Ack.serializer(),
                """{"re":"0192f3c1-7c1e-7a55-9d0b-3f4c2a1b9e10","ok":false,""" +
                    """"error":{"code":"SMS_QUOTA_NEW","message":"x"}}""",
            )
        assertEquals("SMS_QUOTA_NEW", ack.error?.code)
        assertNull(ErrorCode.fromWire(ack.error!!.code))
    }

    @Test
    fun capabilityFromNewerPeerDecodes() {
        val json =
            """
            {"protocol":1,"app_version":"1.4.0 (140)","platform":"visionos","os_version":"3","model":"X","future":true,
             "features":{"camera":{"enabled":true,"cameras":["front","external"],"codecs":["h264","h265"]},
                         "hologram":{"enabled":true}}}
            """.trimIndent()
        val data = ProtocolJson.decodeFromString(CapabilityData.serializer(), json)
        assertEquals("visionos", data.platform)
        assertEquals(listOf("h264", "h265"), data.features.camera?.codecs)
    }
}
