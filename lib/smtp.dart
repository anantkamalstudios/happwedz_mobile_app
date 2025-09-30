import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendEmailGmail(String toEmail, String subject, String body) async {
  final username = 'your_email@gmail.com';
  final appPassword = 'your_app_password'; // STORE SECURELY

  final smtpServer = gmail(username, appPassword); // uses smtp.gmail.com

  final message = Message()
    ..from = Address(username, 'HappyWeds')
    ..recipients.add(toEmail)
    ..subject = subject
    ..text = body;

  try {
    final sendReport = await send(message, smtpServer);
    print('Email sent: $sendReport');
  } on MailerException catch (e) {
    print('Email not sent. ${e.toString()}');
  }
}
