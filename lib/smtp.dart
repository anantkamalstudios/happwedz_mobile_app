// AUDIT NOTE:
// `sendEmailGmail()` is never imported or called anywhere in `lib/`.
// Kept intentionally and commented out as requested.
// Do not remove without confirming with the project owner.
//
// ⚠️ WHY THIS SHOULD NOT BE REVIVED AS WRITTEN: it embeds a Gmail account and
// an app password directly in the app. Anything shipped in an APK/IPA can be
// extracted, so filling these placeholders in would publish working mailbox
// credentials to every user. Sending mail belongs on the backend — the app
// already does exactly that for guest lists via
// `POST https://happywedz.com/api/guestlist/send-guestlist-email`.
//
// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server.dart';
//
// Future<void> sendEmailGmail(String toEmail, String subject, String body) async {
//   final username = 'your_email@gmail.com';
//   final appPassword = 'your_app_password'; // STORE SECURELY
//
//   final smtpServer = gmail(username, appPassword); // uses smtp.gmail.com
//
//   final message = Message()
//     ..from = Address(username, 'HappyWeds')
//     ..recipients.add(toEmail)
//     ..subject = subject
//     ..text = body;
//
//   try {
//     final sendReport = await send(message, smtpServer);
//     print('Email sent: $sendReport');
//   } on MailerException catch (e) {
//     print('Email not sent. ${e.toString()}');
//   }
// }