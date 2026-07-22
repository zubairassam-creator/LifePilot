package com.example.lifepilot

import android.Manifest
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.ContentProviderOperation
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var pendingContactsPermissionResult: MethodChannel.Result? = null
    private val contactsPermissionRequestCode = 4107

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lifepilot/vault_security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecureScreen" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "disableSecureScreen" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lifepilot/contacts")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "hasPermission" -> result.success(hasContactsPermission())
                        "requestPermission" -> requestContactsPermission(result)
                        "getContacts" -> result.success(readContacts())
                        "addContact" -> {
                            ensureContactsPermission()
                            addContact(
                                call.argument<String>("name").orEmpty(),
                                call.argument<String>("phone").orEmpty(),
                                call.argument<String>("email").orEmpty(),
                            )
                            result.success(null)
                        }
                        "updateContact" -> {
                            ensureContactsPermission()
                            updateContact(
                                call.argument<String>("id").orEmpty(),
                                call.argument<String>("name").orEmpty(),
                                call.argument<String>("phone").orEmpty(),
                                call.argument<String>("email").orEmpty(),
                            )
                            result.success(null)
                        }
                        "deleteContact" -> {
                            ensureContactsPermission()
                            deleteContact(call.argument<String>("id").orEmpty())
                            result.success(null)
                        }
                        "call" -> {
                            openDialer(call.argument<String>("phone").orEmpty())
                            result.success(null)
                        }
                        "whatsApp" -> {
                            openWhatsApp(call.argument<String>("phone").orEmpty())
                            result.success(null)
                        }
                        "email" -> {
                            openEmail(call.argument<String>("email").orEmpty())
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: SecurityException) {
                    result.error("permission_denied", "Contacts permission is required.", null)
                } catch (error: Exception) {
                    result.error("contacts_error", error.message ?: "Contact operation failed.", null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lifepilot/spoken_reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val id = call.argument<Int>("id") ?: 0
                        val atMillis = call.argument<Long>("atMillis") ?: 0L
                        val text = call.argument<String>("text") ?: "LifePilot reminder"
                        scheduleSpokenReminder(id, atMillis, text)
                        result.success(null)
                    }
                    "cancel" -> {
                        val id = call.argument<Int>("id") ?: 0
                        cancelSpokenReminder(id)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) ==
            PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CONTACTS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestContactsPermission(result: MethodChannel.Result) {
        if (hasContactsPermission()) {
            result.success(true)
            return
        }
        if (pendingContactsPermissionResult != null) {
            result.error("permission_pending", "A contacts permission request is already open.", null)
            return
        }
        pendingContactsPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.READ_CONTACTS, Manifest.permission.WRITE_CONTACTS),
            contactsPermissionRequestCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == contactsPermissionRequestCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingContactsPermissionResult?.success(granted)
            pendingContactsPermissionResult = null
        }
    }

    private fun ensureContactsPermission() {
        if (!hasContactsPermission()) {
            throw SecurityException("Contacts permission denied")
        }
    }

    private fun readContacts(): List<Map<String, Any>> {
        ensureContactsPermission()
        val contactMap = linkedMapOf<String, MutableMap<String, Any>>()

        contentResolver.query(
            ContactsContract.Contacts.CONTENT_URI,
            arrayOf(
                ContactsContract.Contacts._ID,
                ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
            ),
            null,
            null,
            "${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} COLLATE NOCASE ASC",
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(ContactsContract.Contacts._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex).toString()
                val name = cursor.getString(nameIndex)?.trim().orEmpty().ifEmpty { "Unnamed contact" }
                contactMap[id] = mutableMapOf(
                    "id" to id,
                    "displayName" to name,
                    "phones" to mutableListOf<String>(),
                    "emails" to mutableListOf<String>(),
                )
            }
        }

        contentResolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                ContactsContract.CommonDataKinds.Phone.NUMBER,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
            val valueIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex).toString()
                val phone = cursor.getString(valueIndex)?.trim().orEmpty()
                val phones = contactMap[id]?.get("phones") as? MutableList<String>
                if (phone.isNotEmpty() && phones?.contains(phone) == false) phones.add(phone)
            }
        }

        contentResolver.query(
            ContactsContract.CommonDataKinds.Email.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Email.CONTACT_ID,
                ContactsContract.CommonDataKinds.Email.ADDRESS,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Email.CONTACT_ID)
            val valueIndex = cursor.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Email.ADDRESS)
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex).toString()
                val email = cursor.getString(valueIndex)?.trim().orEmpty()
                val emails = contactMap[id]?.get("emails") as? MutableList<String>
                if (email.isNotEmpty() && emails?.contains(email) == false) emails.add(email)
            }
        }

        return contactMap.values.toList()
    }

    private fun addContact(name: String, phone: String, email: String) {
        require(name.isNotBlank()) { "Contact name is required." }
        val operations = arrayListOf<ContentProviderOperation>()
        operations += ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
            .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
            .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
            .build()
        operations += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
            .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
            .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
            .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name.trim())
            .build()
        if (phone.isNotBlank()) {
            operations += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone.trim())
                .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                .build()
        }
        if (email.isNotBlank()) {
            operations += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.CommonDataKinds.Email.ADDRESS, email.trim())
                .withValue(ContactsContract.CommonDataKinds.Email.TYPE, ContactsContract.CommonDataKinds.Email.TYPE_HOME)
                .build()
        }
        contentResolver.applyBatch(ContactsContract.AUTHORITY, operations)
    }

    private fun firstRawContactId(contactId: String): Long {
        val numericId = contactId.toLongOrNull() ?: error("Invalid contact ID.")
        contentResolver.query(
            ContactsContract.RawContacts.CONTENT_URI,
            arrayOf(ContactsContract.RawContacts._ID),
            "${ContactsContract.RawContacts.CONTACT_ID}=? AND ${ContactsContract.RawContacts.DELETED}=0",
            arrayOf(numericId.toString()),
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getLong(cursor.getColumnIndexOrThrow(ContactsContract.RawContacts._ID))
            }
        }
        error("Contact could not be edited.")
    }

    private fun updateContact(contactId: String, name: String, phone: String, email: String) {
        require(name.isNotBlank()) { "Contact name is required." }
        val rawId = firstRawContactId(contactId)
        val operations = arrayListOf<ContentProviderOperation>()

        operations += ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
            .withSelection(
                "${ContactsContract.Data.RAW_CONTACT_ID}=? AND ${ContactsContract.Data.MIMETYPE} IN (?,?,?)",
                arrayOf(
                    rawId.toString(),
                    ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE,
                    ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE,
                    ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE,
                ),
            )
            .build()
        operations += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
            .withValue(ContactsContract.Data.RAW_CONTACT_ID, rawId)
            .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
            .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name.trim())
            .build()
        if (phone.isNotBlank()) {
            operations += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, rawId)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone.trim())
                .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                .build()
        }
        if (email.isNotBlank()) {
            operations += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, rawId)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.CommonDataKinds.Email.ADDRESS, email.trim())
                .withValue(ContactsContract.CommonDataKinds.Email.TYPE, ContactsContract.CommonDataKinds.Email.TYPE_HOME)
                .build()
        }
        contentResolver.applyBatch(ContactsContract.AUTHORITY, operations)
    }

    private fun deleteContact(contactId: String) {
        val numericId = contactId.toLongOrNull() ?: error("Invalid contact ID.")
        contentResolver.delete(
            ContactsContract.RawContacts.CONTENT_URI,
            "${ContactsContract.RawContacts.CONTACT_ID}=?",
            arrayOf(numericId.toString()),
        )
    }

    private fun openDialer(phone: String) {
        require(phone.isNotBlank()) { "No phone number available." }
        startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:${Uri.encode(phone)}")))
    }

    private fun openWhatsApp(phone: String) {
        val digits = phone.filter { it.isDigit() }
        require(digits.isNotBlank()) { "No phone number available." }
        val uri = Uri.parse("https://wa.me/$digits")
        val whatsappIntent = Intent(Intent.ACTION_VIEW, uri).setPackage("com.whatsapp")
        try {
            startActivity(whatsappIntent)
        } catch (_: Exception) {
            startActivity(Intent(Intent.ACTION_VIEW, uri))
        }
    }

    private fun openEmail(email: String) {
        require(email.isNotBlank()) { "No email address available." }
        startActivity(Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:${Uri.encode(email)}")))
    }

    private fun scheduleSpokenReminder(id: Int, atMillis: Long, text: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = spokenIntent(id, text)
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pendingIntent)
    }

    private fun cancelSpokenReminder(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(spokenIntent(id, ""))
    }

    private fun spokenIntent(id: Int, text: String): PendingIntent {
        val intent = Intent(this, SpokenReminderReceiver::class.java).putExtra("text", text)
        return PendingIntent.getBroadcast(
            this,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
