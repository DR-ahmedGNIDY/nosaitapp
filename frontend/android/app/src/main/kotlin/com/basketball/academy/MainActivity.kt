package com.basketball.academy

import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/** FileProvider مستقل (اسم class خاص) حتى لا يتعارض مع providers الإضافات. */
class ReceiptFileProvider : FileProvider()

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // إرسال صورة الإيصال مباشرة لمحادثة ولي الأمر على واتساب.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nosait/whatsapp_share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareImage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val sent = try {
                    shareImageToWhatsApp(
                        call.argument<ByteArray>("bytes") ?: ByteArray(0),
                        call.argument<String>("phone") ?: "",
                        call.argument<String>("text") ?: "",
                    )
                } catch (e: Exception) {
                    false
                }
                result.success(sent)
            }
    }

    /** واتساب أو واتساب للأعمال — أيهما متثبت. */
    private fun installedWhatsApp(): String? =
        listOf("com.whatsapp", "com.whatsapp.w4b").firstOrNull { pkg ->
            try {
                packageManager.getPackageInfo(pkg, 0)
                true
            } catch (e: PackageManager.NameNotFoundException) {
                false
            }
        }

    private fun shareImageToWhatsApp(bytes: ByteArray, phone: String, text: String): Boolean {
        if (bytes.isEmpty()) return false
        val pkg = installedWhatsApp() ?: return false

        val dir = File(cacheDir, "receipts").apply { mkdirs() }
        // نحتفظ بآخر صورة فقط حتى لا يكبر الـ cache.
        dir.listFiles()?.forEach { it.delete() }
        val file = File(dir, "receipt_${System.currentTimeMillis()}.png")
        file.writeBytes(bytes)
        val uri = FileProvider.getUriForFile(this, "$packageName.receipts", file)

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            setPackage(pkg)
            putExtra(Intent.EXTRA_STREAM, uri)
            if (text.isNotEmpty()) putExtra(Intent.EXTRA_TEXT, text)
            // يفتح محادثة الرقم مباشرة (رقم دولي بدون + أو أصفار).
            if (phone.isNotEmpty()) putExtra("jid", "$phone@s.whatsapp.net")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
