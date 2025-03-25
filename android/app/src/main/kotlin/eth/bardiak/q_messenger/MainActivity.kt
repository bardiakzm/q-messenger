package eth.bardiak.q_messenger

//import io.flutter.embedding.android.FlutterActivity
//
//class MainActivity : FlutterActivity()



import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.provider.Telephony
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity: FlutterActivity() {
    private val CHANNEL = "eth.bardiak.q_messenger/sms_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAllSms" -> {
                    if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_SMS)
                        == PackageManager.PERMISSION_GRANTED) {
                        result.success(getAllSms())
                    } else {
                        ActivityCompat.requestPermissions(
                            activity,
                            arrayOf(Manifest.permission.READ_SMS),
                            100
                        )
                        result.error("PERMISSION_DENIED", "READ_SMS permission required", null)
                    }
                }
                "sendSms" -> {
                    if (ContextCompat.checkSelfPermission(context, Manifest.permission.SEND_SMS)
                        == PackageManager.PERMISSION_GRANTED) {
                        try {
                            val address = call.argument<String>("address")
                            val body = call.argument<String>("body")

                            if (address == null || body == null) {
                                result.error("INVALID_ARGUMENT", "Address and body are required", null)
                                return@setMethodCallHandler
                            }

                            sendSms(address, body)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SEND_FAILURE", e.message, null)
                        }
                    } else {
                        ActivityCompat.requestPermissions(
                            activity,
                            arrayOf(Manifest.permission.SEND_SMS),
                            101
                        )
                        result.error("PERMISSION_DENIED", "SEND_SMS permission required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }

            }
        }
    }

    private fun sendSms(address: String, body: String) {
        val smsManager = SmsManager.getDefault()

        // For longer messages that might need to be split
        if (body.length > 160) {
            val parts = smsManager.divideMessage(body)
            smsManager.sendMultipartTextMessage(address, null, parts, null, null)
        } else {
            smsManager.sendTextMessage(address, null, body, null, null)
        }
    }

    private fun getAllSms(): List<Map<String, Any>> {
        val smsList = mutableListOf<Map<String, Any>>()
        val cursor: Cursor? = contentResolver.query(
            Telephony.Sms.CONTENT_URI,
            arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE
            ),
            null,
            null,
            Telephony.Sms.DEFAULT_SORT_ORDER
        )

        cursor?.use {
            while (it.moveToNext()) {
                val id = it.getString(it.getColumnIndexOrThrow(Telephony.Sms._ID))
                val address = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS))
                val body = it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY))
                val date = it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE))
                val type = it.getInt(it.getColumnIndexOrThrow(Telephony.Sms.TYPE))

                smsList.add(mapOf(
                    "id" to id,
                    "address" to address,
                    "body" to body,
                    "date" to date,
                    "type" to type
                ))
            }
        }

        return smsList
    }
}