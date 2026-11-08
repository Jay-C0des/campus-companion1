from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
if not manifest.exists():
    raise SystemExit(f"Android manifest not found: {manifest}")

text = manifest.read_text(encoding="utf-8")
permission = '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
if "android.permission.RECEIVE_BOOT_COMPLETED" not in text:
    text = text.replace("<application", permission + "\n    <application", 1)

receivers = """
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""
if "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" not in text:
    text = text.replace("</application>", receivers + "\n    </application>", 1)

manifest.write_text(text, encoding="utf-8")
print("Patched Android notification permissions and scheduled-notification receivers.")
