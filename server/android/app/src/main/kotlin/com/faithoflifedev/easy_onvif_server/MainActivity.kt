package com.faithoflifedev.easy_onvif_server

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var recorder: AudioRecord? = null
    private var captureThread: Thread? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "easy_onvif_server/audio_capture"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> { startCapture(); result.success(null) }
                "stop" -> { stopCapture(); result.success(null) }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "easy_onvif_server/audio_capture/events"
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    @SuppressLint("MissingPermission") // RECORD_AUDIO is granted via the OS dialog.
    private fun startCapture() {
        if (recorder != null) return

        val bufferSize = maxOf(
            AudioRecord.getMinBufferSize(
                8000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
            ),
            1280
        )

        val record = AudioRecord(
            MediaRecorder.AudioSource.MIC, 8000,
            AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufferSize
        )

        if (record.state != AudioRecord.STATE_INITIALIZED) return

        recorder = record
        record.startRecording()

        captureThread = Thread {
            val buffer = ByteArray(640) // 40 ms of PCM16 at 8 kHz.
            while (recorder != null) {
                val read = record.read(buffer, 0, buffer.size)
                if (read > 0) {
                    val chunk = buffer.copyOf(read)
                    mainHandler.post { eventSink?.success(chunk) }
                }
            }
        }.also { it.start() }
    }

    private fun stopCapture() {
        val record = recorder ?: return
        recorder = null
        captureThread?.join(500)
        captureThread = null
        record.stop()
        record.release()
    }
}
