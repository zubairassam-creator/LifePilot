LifePilot Password Vault Fix Patch

Replace/copy these files into C:\development\LifePilot using the same folder structure.

Fixes:
1. Blocks screenshots and recent-app previews while Password Vault is open.
2. Fixes biometric password reveal by ignoring the temporary inactive lifecycle state caused by Android's biometric prompt.
3. Automatically hides revealed passwords after 30 seconds.
4. Fixes password-generator button overflow using Wrap.

After copying, run:
flutter clean
flutter pub get
flutter analyze
flutter run
