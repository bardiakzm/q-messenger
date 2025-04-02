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
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.provider.ContactsContract



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
                            val simSlot = call.argument<Int>("simSlot") ?: 0 //default to SIM 1

                            if (address == null || body == null) {
                                result.error("INVALID_ARGUMENT", "Address and body are required", null)
                                return@setMethodCallHandler
                            }

                            sendSms(address, body, simSlot)
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

    private fun getContactName(phoneNumber: String): String? {
        val uri = ContactsContract.PhoneLookup.CONTENT_FILTER_URI.buildUpon()
            .appendPath(phoneNumber)
            .build()

        val cursor = contentResolver.query(
            uri,
            arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME),
            null,
            null,
            null
        )

        cursor?.use {
            if (it.moveToFirst()) {
                return it.getString(it.getColumnIndexOrThrow(ContactsContract.PhoneLookup.DISPLAY_NAME))
            }
        }
        return null
    }


    private fun sendSms(address: String, body: String, simSlot: Int = 0) {
        try {
            val subscriptionManager = getSystemService(SubscriptionManager::class.java)
            val subscriptionInfoList = subscriptionManager.activeSubscriptionInfoList

            if (subscriptionInfoList != null && subscriptionInfoList.size > simSlot) {
                val subscriptionId = subscriptionInfoList[simSlot].subscriptionId
                val smsManager = SmsManager.getSmsManagerForSubscriptionId(subscriptionId)

                // For long messages, split into parts
                val parts = smsManager.divideMessage(body)
                smsManager.sendMultipartTextMessage(address, null, parts, null, null)
            } else {
                throw Exception("Invalid SIM slot or no active SIM cards.")
            }
        } catch (e: Exception) {
            e.printStackTrace()
            throw e
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
                val senderName = getContactName(address) ?: "Unknown"

                smsList.add(mapOf(
                    "id" to id,
                    "address" to address,
                    "body" to body,
                    "date" to date,
                    "type" to type,
                    "senderName" to senderName,
                ))
            }
        }

        return smsList
    }
}