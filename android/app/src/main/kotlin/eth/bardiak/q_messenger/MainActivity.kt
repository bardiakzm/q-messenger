package eth.bardiak.q_messenger

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
import android.net.Uri

class MainActivity: FlutterActivity() {
    private val CHANNEL = "eth.bardiak.q_messenger/sms_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAllSms" -> {
                    val requiredPermissions = arrayOf(
                        Manifest.permission.READ_SMS,
                        Manifest.permission.READ_CONTACTS
                    )

                    if (hasPermissions(requiredPermissions)) {
                        result.success(getAllSms())
                    } else {
                        ActivityCompat.requestPermissions(
                            activity,
                            requiredPermissions,
                            100
                        )
                        result.error("PERMISSION_DENIED", "READ_SMS and READ_CONTACTS permissions required", null)
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

    private fun hasPermissions(permissions: Array<String>): Boolean {
        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED) {
                return false
            }
        }
        return true
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

    private fun getContactsMap(): Map<String, String> {
        val contactsMap = mutableMapOf<String, String>()

        //exit early if no contacts permission
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS)
            != PackageManager.PERMISSION_GRANTED) {
            return contactsMap
        }

        val cursor = contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME
            ),
            null,
            null,
            null
        )

        cursor?.use {
            val numberIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            val nameIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)

            while (it.moveToNext()) {
                val phoneNumber = it.getString(numberIndex)
                val name = it.getString(nameIndex)

                // Normalize phone number for better matching
                val normalizedNumber = normalizePhoneNumber(phoneNumber)
                contactsMap[normalizedNumber] = name
            }
        }

        return contactsMap
    }

    private fun normalizePhoneNumber(phoneNumber: String): String {
        // Remove all non-digit characters except the leading +
        return if (phoneNumber.startsWith("+")) {
            "+" + phoneNumber.substring(1).replace(Regex("\\D"), "")
        } else {
            phoneNumber.replace(Regex("\\D"), "")
        }
    }

    private fun getAllSms(): List<Map<String, Any>> {
        val smsList = mutableListOf<Map<String, Any>>()

        //get all contacts
        val contactsMap = getContactsMap()

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

                //normalize the phone number for matching
                val normalizedAddress = normalizePhoneNumber(address)
                //lookup contact name from pre-loaded map
                val contactName = contactsMap[normalizedAddress] ?: "Unknown"

                smsList.add(mapOf(
                    "id" to id,
                    "address" to address,
                    "body" to body,
                    "date" to date,
                    "type" to type,
                    "senderName" to contactName
                ))
            }
        }

        return smsList
    }
}