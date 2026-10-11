# Security reports

Avoid posting personal photos, folder bookmarks, access tokens, or location metadata in public issues. A small synthetic image and reproduction steps are usually enough.

Once the public repository is created, the maintainer should enable GitHub private vulnerability reporting. Use its **Security → Report a vulnerability** flow for issues that could expose photos or overwrite data. A private reporting URL and supported release versions will be added when the repository and first release exist.

The app has no network code, analytics, advertising, account system, or third-party SDKs. The App Store configuration grants user-selected file access and app-scoped bookmarks only. It does not request network, Photos-library, Full Disk Access, or automation entitlements.
