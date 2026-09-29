// GENERATED from the live production bundle (happywedz.com):
//   PrivacyPolicy-B1twQiTj.js, TermsCondition-B2l5kzcQ.js
// Each `content` string is the page's template literal copied byte-for-byte
// (CRLF normalised to LF). Do not hand-edit the wording — it is legal text and
// must match the website. Rendering rules live in legal_content_view.dart.

import 'package:flutter/material.dart';

/// One selectable section of a tabbed legal page (web: one entry of the
/// `legalSections` / `policySections` object).
class LegalSection {
  const LegalSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.content,
  });

  /// The object key on the web (`overview`, `terms`, …).
  final String id;
  final String title;
  final IconData icon;

  /// Raw pre-formatted text, rendered line by line exactly like the web's
  /// formatter (see LegalContentView).
  final String content;
}

/// Privacy Policy sections, in web order (live /privacy).
const List<LegalSection> privacyPolicySections = [
  LegalSection(
    id: 'overview',
    title: 'Overview',
    icon: Icons.info_outline_rounded,
    content:
        '\n'
        'Last Updated: 23 September 2026\n'
        '\n'
        'HappyWedz ("HappyWedz", "we", "us") runs happywedz.com and the HappyWedz apps — a wedding planning platform where couples find and book vendors, plan their wedding, and book honeymoon travel, and where vendors list and manage their business.\n'
        '\n'
        'This policy explains what personal data we collect, why we collect it, who we share it with, how long we keep it, and the choices you have. It applies to everyone who uses HappyWedz:\n'
        '• Couples and other visitors planning a wedding\n'
        '• Vendors and venues using the vendor dashboard\n'
        '• Guests whose details a couple adds to a guest list or invitation\n'
        '\n'
        '1. Who is responsible for your data\n'
        'HappyWedz is the data fiduciary for the personal data described here. Vendors you contact or book are separate businesses and are responsible for the data you share directly with them.\n'
        '\n'
        '2. Your agreement\n'
        'By using HappyWedz you agree to this policy. If you do not agree, please stop using the platform. Where the law requires your consent — for example to send you marketing messages or to use your photo in an AI feature — we ask for it separately and you can withdraw it at any time.\n'
        '\n'
        '3. Terms that also apply\n'
        'This policy sits alongside our Terms & Condition and Cancellation Policy.\n'
        '',
  ),
  LegalSection(
    id: 'collect',
    title: 'Information We Collect',
    icon: Icons.folder_open_rounded,
    content:
        '\n'
        'We collect only what the platform needs to work. What that is depends on how you use it.\n'
        '\n'
        '1. If you are planning a wedding\n'
        '\n'
        'a) Your account\n'
        '• Name, email address and mobile number\n'
        '• Password, or a Google / Apple sign-in identifier if you use social sign-in\n'
        '• One-time passwords (OTP) used to verify your phone or email\n'
        '• Profile and cover photos, if you upload them\n'
        '• Wedding details you enter: wedding date, city, and venue\n'
        '\n'
        'b) Your planning tools\n'
        '• Budget entries, estimated and final costs, and payments you record\n'
        '• Checklists and task notes\n'
        '• Shortlisted and favourite vendors\n'
        '• Guest lists and seating plans\n'
        '• Enquiries, quotation requests and chat messages you exchange with vendors\n'
        '• Reviews and ratings you write, which are shown publicly with your name\n'
        '\n'
        'c) Your wedding website, e-invites and photo sharing\n'
        '• Bride and groom details, your story, events, dates and venues\n'
        '• Photos and videos you upload for invitations, galleries and event sharing\n'
        '• Share links and RSVP responses\n'
        '\n'
        'd) Information about your guests\n'
        'When you add guests to a guest list or send an invitation, you give us their names and, where you provide them, their phone numbers, email addresses, meal preferences, RSVP replies and your own notes about them. Please add only what you need, and only where the guest would reasonably expect you to share it. We use guest details solely to run your guest list, invitations and RSVPs.\n'
        '\n'
        'e) AI and try-on features\n'
        '• The instructions and details you give our AI planning assistants\n'
        '• If you use the virtual makeup or style try-on, the photo you upload and the image it produces\n'
        '\n'
        '2. If you book honeymoon travel\n'
        'Airlines, hotels, cab operators and insurers require traveller details, which we pass to them through our travel supplier. Depending on what you book, this can include:\n'
        '• Traveller name, title, gender, date of birth and age\n'
        '• Passport number, issue and expiry date, and nationality for international travel\n'
        '• PAN, where a hotel or insurer requires it\n'
        '• Contact email and mobile number, and an emergency contact where the airline requires one\n'
        '• Pincode and address details where required for insurance\n'
        '• GST details, if you ask for a GST invoice\n'
        '• Booking references, PNRs, tickets, vouchers and policy numbers\n'
        '\n'
        '3. If you are a vendor\n'
        '\n'
        'a) Business profile\n'
        '• Business name, contact person, email address and mobile number\n'
        '• City and service locations, categories and subcategories\n'
        '• Business description, services, packages and pricing you publish\n'
        '• Photos, videos and other portfolio media you upload\n'
        '\n'
        'b) Verification (KYC)\n'
        '• The documents you upload to get verified: Aadhaar, PAN, and any business documents you add with your own label (for example a GST certificate or shop licence)\n'
        '• The file name, type and size of each document, and which round of submission it belongs to\n'
        '• The result of our review, including the reason if a submission is rejected\n'
        '\n'
        'Verification documents are stored in private storage. They are not public, and our reviewers open them through links that expire within minutes. When you resubmit, the earlier documents are marked superseded and kept as a record of the review.\n'
        '\n'
        'c) Subscriptions and payments\n'
        '• Your plan, its start and end dates, trial status and renewal state\n'
        '• Payment records: amount, status, method, invoice number, and the order and payment identifiers returned by our payment gateway\n'
        '\n'
        'd) Running your business on HappyWedz\n'
        '• Enquiries and leads, which include the customer\'s name, contact details and wedding requirements\n'
        '• Chat messages between you and customers\n'
        '• Quotations you send and pricing requests you receive\n'
        '• Reviews customers leave about your business\n'
        '• Counts of how many times your profile was viewed\n'
        '• If you choose to connect Instagram: your Instagram username, account name, account type, profile picture and an access token, used to show your posts on your profile. The connection asks Instagram for permission to read your business account\'s posts, comments and messages. You can disconnect at any time from the dashboard, which switches the connection off; write to privacy@happywedz.com if you also want the stored token deleted.\n'
        '\n'
        'e) Your own clients, if you use the vendor CRM\n'
        'The CRM lets you keep records about your clients on HappyWedz, including people who never used HappyWedz themselves. That can include their name, phone number, email address, location and your notes; event dates and venues; quotations, invoices, payments and balances; your GSTIN, PAN, bank details and UPI id as they appear on those documents; and files you upload against a client.\n'
        '\n'
        'You decide what goes in, and you remain responsible for it — please add only what you are entitled to hold, and tell your clients how you use it. We store it for you, and on your instruction we email your clients reminders and documents on your behalf. Quotations, invoices and receipts you share are reachable through a secret link: anyone who has the link can open that document, so share links carefully.\n'
        '\n'
        'f) Exports\n'
        'When you export leads or CRM clients to a spreadsheet, that copy leaves HappyWedz and our protections no longer apply to it. Keep those files safe and delete them when you no longer need them.\n'
        '\n'
        '4. Information we collect automatically\n'
        '• Device and browser type, operating system and device identifiers\n'
        '• IP address and approximate location derived from it\n'
        '• Pages viewed, searches, taps and other activity on the platform\n'
        '• Cookies and similar local storage, described in the Cookies section\n'
        '• When a vendor profile is viewed, we record the view together with the viewer\'s IP address, so vendors can see view counts and so we can detect fake traffic\n'
        '\n'
        '5. Location\n'
        'If you allow it, we use your device location to show nearby vendors and venues. You can turn this off in your browser or device settings at any time.\n'
        '\n'
        '6. What we do not collect\n'
        '• We never receive or store your full card number, CVV, UPI PIN or netbanking password — these go directly to our payment gateway\n'
        '• We do not ask for caste, religion, health or other sensitive categories of data, beyond details you volunteer in free-text fields such as your wedding requirements\n'
        '',
  ),
  LegalSection(
    id: 'use',
    title: 'How We Use Your Information',
    icon: Icons.tune_rounded,
    content:
        '\n'
        'We use personal data for the following purposes and no others.\n'
        '\n'
        '1. To run the platform\n'
        '• Create and secure your account, and sign you in\n'
        '• Show you vendors, venues and packages, and let you shortlist and enquire\n'
        '• Pass your enquiry to the vendors you choose\n'
        '• Run your planning tools: budget, checklist, guest list, invitations and wedding website\n'
        '• Complete and manage your travel bookings, and issue tickets, vouchers and invoices\n'
        '• Give vendors the dashboard they subscribe to, including leads, chats and verification\n'
        '\n'
        '2. To communicate with you\n'
        '• Booking confirmations, payment receipts, reminders and service updates\n'
        '• Replies from our support team\n'
        '• Offers and newsletters, only where you have opted in. Every marketing message has an unsubscribe option; service messages about a booking will still reach you.\n'
        '\n'
        '3. To take payments\n'
        'Process subscription and booking payments, refunds and chargebacks, and keep the records tax law requires.\n'
        '\n'
        '4. To keep HappyWedz safe and honest\n'
        'Detect and prevent fraud, fake listings, fake reviews and abuse; verify vendors; enforce our Terms; and protect our users and our rights.\n'
        '\n'
        '5. To improve the product\n'
        'Understand which features are used and where people get stuck, fix problems, and build new features. Wherever it is enough for the purpose, we do this with aggregated or de-identified data.\n'
        '\n'
        '6. To meet legal obligations\n'
        'Comply with Indian law, including tax and accounting rules, and respond to lawful requests from authorities.\n'
        '',
  ),
  LegalSection(
    id: 'sharing',
    title: 'When We Share Information',
    icon: Icons.share_rounded,
    content:
        '\n'
        'We do not sell your personal data. We share it only in the situations below.\n'
        '\n'
        '1. With vendors you choose\n'
        'When you send an enquiry, request a quote or make a booking, the vendor receives your name, contact details and the requirements you shared. What the vendor then does with it is governed by that vendor\'s own privacy practices.\n'
        '\n'
        '2. With travel suppliers\n'
        'For honeymoon bookings we send traveller and contact details to our travel technology partner and, through them, to the airline, hotel, cab operator or insurer you booked. They need it to issue your ticket, booking or policy.\n'
        '\n'
        '3. With our payment gateway\n'
        'Payments are handled by our payment gateway (Razorpay). Your card, UPI or banking credentials are entered on their systems, not ours. We receive only the order and payment identifiers, the amount and the status.\n'
        '\n'
        '4. With service providers who work for us\n'
        'These providers process data on our instructions and only to provide their service to us:\n'
        '• Cloud hosting and file storage — photos, videos, invitations and verification documents are stored on Amazon Web Services in India\n'
        '• Email delivery, for booking confirmations, verification updates and the CRM reminders vendors send to their clients\n'
        '• Google Sign-In, if you choose to sign in with your Google account\n'
        '• Map and geocoding services — when a vendor sets a business location, the address is sent to OpenStreetMap to find its coordinates\n'
        '• AI providers, for the planning assistant and try-on features you choose to use\n'
        '\n'
        '5. Across HappyWedz services\n'
        'HappyWedz and the HappyWedz store share a signed-in session across happywedz.com and its subdomains, so you are not asked to sign in twice. Your session details are stored in a cookie readable across those subdomains.\n'
        '\n'
        '6. With Meta / Instagram\n'
        'Only if a vendor connects their Instagram account, and only to fetch the posts they chose to display.\n'
        '\n'
        '7. For legal reasons\n'
        'Where the law requires it, or to establish, exercise or defend legal claims, or to protect the rights and safety of our users, the public or HappyWedz.\n'
        '\n'
        '8. In a business transfer\n'
        'If HappyWedz is involved in a merger, acquisition or sale of assets, personal data may transfer to the acquirer. We will tell you before your data becomes subject to a different privacy policy.\n'
        '\n'
        '9. What is public by design\n'
        'Some things you create are meant to be seen by others, and you control whether to publish them:\n'
        '• Reviews and ratings, shown with your name\n'
        '• A wedding website once you publish it\n'
        '• An e-invite once you share its link — anyone with the link can open it and RSVP\n'
        '• A vendor\'s business profile, portfolio and packages\n'
        '',
  ),
  LegalSection(
    id: 'cookies',
    title: 'Cookies & Tracking',
    icon: Icons.cookie_outlined,
    content:
        '\n'
        'We use cookies and similar browser storage, such as localStorage, to run the platform.\n'
        '\n'
        '1. Types we use\n'
        '• Essential — signing you in, keeping your session across HappyWedz and the HappyWedz store, security and fraud prevention. The platform cannot work without these.\n'
        '• Preference — remembering your choices, such as your city, saved filters, favourites and whether you dismissed a banner.\n'
        '• Analytics — understanding how the platform is used so we can improve it. We do not run advertising or remarketing pixels, and we do not sell what we learn.\n'
        '\n'
        '2. Your choices\n'
        'When you first visit we show a cookie notice and remember your choice on that device. You can also clear or block cookies in your browser settings. If you block essential cookies, sign-in and booking will not work.\n'
        '\n'
        '3. Third-party cookies\n'
        'Services embedded in our pages — such as Google, Firebase and our payment gateway — may set their own cookies when you use those features. Their own policies govern those cookies.\n'
        '\n'
        '4. Do Not Track\n'
        'Browsers send "Do Not Track" signals in different, inconsistent ways, so we do not currently respond to them.\n'
        '',
  ),
  LegalSection(
    id: 'payments',
    title: 'Payments & Financial Data',
    icon: Icons.credit_card_rounded,
    content:
        '\n'
        '1. How payments are handled\n'
        'All payments — vendor subscriptions, wedding service bookings, and honeymoon flight, hotel, cab and insurance bookings — are processed by our payment gateway. You enter your card, UPI or netbanking details on the gateway\'s secure screen.\n'
        '\n'
        '2. What we keep\n'
        '• The payment gateway\'s order and payment identifiers\n'
        '• Amount, currency, status, method and the time of payment\n'
        '• Invoice numbers and the invoices, receipts, vouchers and tickets issued to you\n'
        '• For a failed payment, the reason returned by the gateway\n'
        '\n'
        '3. What we never keep\n'
        'Full card numbers, CVV, UPI PIN, netbanking passwords or any other payment credential.\n'
        '\n'
        '4. Refunds\n'
        'Where a booking fails after a payment is authorised, the refund is made through the same payment method. Refund timelines follow our Cancellation Policy and the gateway\'s processing times.\n'
        '',
  ),
  LegalSection(
    id: 'retention',
    title: 'Retention & Deleting Your Account',
    icon: Icons.delete_outline_rounded,
    content:
        '\n'
        '1. How long we keep data\n'
        '• While your account is active, we keep the data needed to provide the service.\n'
        '• Booking, payment and invoice records are kept for as long as tax and accounting law requires, even after you leave.\n'
        '• Logs and analytics are kept for a limited period and then deleted or aggregated.\n'
        '\n'
        '2. Deleting your account\n'
        'You can delete your account yourself from your profile, or by writing to privacy@happywedz.com. We confirm your identity before an account is deleted, because deletion cannot be undone.\n'
        '\n'
        'When you delete your account:\n'
        '• Your personal details — name, email, phone, photos and profile — are removed\n'
        '• Uploaded try-on photos and their results, sign-in tokens, notifications and saved personal lists are deleted\n'
        '• Booking, payment and review records are kept for legal and accounting purposes, and are no longer linked to anything that identifies you\n'
        '• Reviews you posted may stay visible without your personal details, so vendor ratings remain accurate\n'
        '\n'
        '3. Vendors\n'
        'The vendor dashboard does not yet have a self-service delete button. Write to privacy@happywedz.com from your registered email and we will close the account and remove the public listing. Verification documents, subscription records and invoices are kept for the period tax and company law requires.\n'
        '\n'
        'If you used the CRM, tell us what should happen to your client records: we can delete them with your account, or export them to you first.\n'
        '',
  ),
  LegalSection(
    id: 'rights',
    title: 'Your Rights & Security',
    icon: Icons.verified_user_outlined,
    content:
        '\n'
        '1. Your rights under the Digital Personal Data Protection Act, 2023\n'
        '• Access — ask what personal data we hold about you and how we use it\n'
        '• Correction — have inaccurate or incomplete data corrected, or out-of-date data updated\n'
        '• Erasure — ask us to delete your data, except what we must keep by law\n'
        '• Withdraw consent — at any time, for anything you consented to. This does not undo what we did before you withdrew it.\n'
        '• Nominate — name someone to exercise your rights if you die or become incapacitated\n'
        '• Grievance redressal — complain to us first, and then to the Data Protection Board of India if you are not satisfied\n'
        '\n'
        'Most of this is available directly in your account: edit your profile, manage your listings, or delete your account. For anything else, write to privacy@happywedz.com. We respond within the timelines the law sets, and we may ask you to confirm your identity first.\n'
        '\n'
        '2. Your duties\n'
        'Please give accurate information, keep your password to yourself, and do not impersonate anyone or file false complaints.\n'
        '\n'
        '3. How we protect your data\n'
        '• Encrypted connections (HTTPS) between your device and our servers\n'
        '• Passwords stored only as salted hashes, never in readable form\n'
        '• Access to personal data restricted to staff who need it for their work\n'
        '• Payment credentials handled only by our PCI-compliant payment gateway\n'
        '• Monitoring and logging to detect abuse\n'
        '\n'
        'No system can be guaranteed completely secure. If a personal data breach affects you, we will notify you and the Data Protection Board as the law requires.\n'
        '\n'
        '4. Children\n'
        'HappyWedz is for adults of 18 and over. We do not knowingly collect data from children. If you believe a child has given us personal data, write to privacy@happywedz.com and we will delete it.\n'
        '\n'
        '5. Where your data is stored\n'
        'Your data is stored and processed in India. Some of our service providers may process data outside India; where they do, we require safeguards consistent with Indian law.\n'
        '\n'
        '6. Links to other sites\n'
        'Our pages link to vendor websites, social media and payment pages that we do not control. Their privacy policies, not ours, govern what they do with your data.\n'
        '',
  ),
  LegalSection(
    id: 'contact',
    title: 'Contact & Grievances',
    icon: Icons.mail_outline_rounded,
    content:
        '\n'
        '1. Privacy questions and requests\n'
        'Email: privacy@happywedz.com\n'
        'General support: support@happywedz.com\n'
        'Registered address: HappyWedz, Pune, India\n'
        '\n'
        'Please tell us what you would like us to do and the email or phone number registered with your account, so we can find your records.\n'
        '\n'
        '2. Grievance Officer\n'
        'In line with the Information Technology Act, 2000 and the rules under it, and the Digital Personal Data Protection Act, 2023, you can reach our Grievance Officer at:\n'
        '\n'
        'Grievance Officer, HappyWedz\n'
        'Email: privacy@happywedz.com\n'
        'Address: HappyWedz, Pune, India\n'
        '\n'
        'We acknowledge complaints within 24 hours and aim to resolve them within 15 days. If you are not satisfied with the outcome, you may complain to the Data Protection Board of India.\n'
        '\n'
        '3. Changes to this policy\n'
        'We update this policy when the platform or the law changes. The "Last Updated" date at the top of the Overview always shows the current version, and we will tell you about significant changes by email or a notice on the platform. Continuing to use HappyWedz after a change means you accept the updated policy.\n'
        '',
  ),
];

/// Terms & Condition sections, in web order (live /terms).
const List<LegalSection> termsSections = [
  LegalSection(
    id: 'terms',
    title: 'Terms of Service',
    icon: Icons.description_outlined,
    content:
        '\n'
        'Last Updated: 04 Oct 2025\n'
        '\n'
        'By accessing or using Happywedz.com (the "Platform" / "Website"), you agree to these Terms. If you do not agree, please discontinue use immediately.\n'
        '\n'
        '1. Acceptance of Terms\n'
        'These Terms govern your access and use of Happywedz.com. By using the Website, creating an account, or communicating with vendors, you confirm that you have read, understood, and agreed to these Terms.\n'
        'Happywedz reserves the right to modify these Terms at any time. Updates become effective once published.\n'
        '\n'
        '2. Nature of the Platform\n'
        'Happywedz.com is a wedding planning marketplace connecting:\n'
        '• Couples / Users seeking wedding services\n'
        '• Vendors / Service Providers offering wedding-related services\n'
        '\n'
        'Happywedz is a digital intermediary only and does not provide or control vendor services.\n'
        'All bookings, payments, cancellations, and service delivery are contracts solely between Users and Vendors.\n'
        '\n'
        '3. User Eligibility\n'
        'You confirm that you:\n'
        '• Are at least 18 years old\n'
        '• Have legal capacity to enter binding agreements\n'
        '• Will use the platform lawfully\n'
        '\n'
        '4. User Responsibilities\n'
        'You agree not to:\n'
        '• Provide false or misleading information\n'
        '• Create fake or multiple accounts\n'
        '• Post abusive, unlawful, or harmful content\n'
        '• Infringe intellectual property\n'
        '• Hack, disrupt, or misuse the platform\n'
        '• Use bots or scrapers without permission\n'
        '\n'
        'Accounts may be suspended or terminated for violations.\n'
        '\n'
        '5. Vendor Responsibilities\n'
        'Vendors must:\n'
        '• Provide accurate business information\n'
        '• Publish genuine pricing and media\n'
        '• Deliver services professionally\n'
        '• Honor commitments\n'
        '• Respond to users in a timely manner\n'
        '\n'
        'Happywedz is not responsible for vendor behavior or service quality.\n'
        '\n'
        '6. Booking & Payments\n'
        'Happywedz is not involved in pricing, payment collection, refunds, or disputes.\n'
        'All service contracts are between Users and Vendors.\n'
        '\n'
        '7. Account Termination\n'
        'Accounts may be terminated due to fraud, violations, harmful content, or legal reasons.\n'
        'Users may request account deletion via support.\n'
        '\n'
        '8. Third-Party Links\n'
        'Happywedz is not responsible for third-party content or policies.\n'
        '\n'
        '9. Governing Law\n'
        'These Terms are governed by Indian law.\n'
        'Jurisdiction: Courts of [City/State – e.g., Pune, Maharashtra].\n'
        '',
  ),
  LegalSection(
    id: 'privacy',
    title: 'Privacy Policy',
    icon: Icons.shield_outlined,
    content:
        '\n'
        'Your privacy is important to us.\n'
        '\n'
        '1. Information We Collect\n'
        '\n'
        'a) Information You Provide\n'
        '• Name, email, phone number\n'
        '• Wedding details (date, location, budget)\n'
        '• Vendor profile information\n'
        '• Reviews, chats, photos, inquiries\n'
        '\n'
        'b) Information Collected Automatically\n'
        '• IP address\n'
        '• Device & browser details\n'
        '• Pages visited & activity logs\n'
        '• Cookies & analytics data\n'
        '\n'
        'c) Information from Vendors\n'
        'Vendors may share booking details and quotations.\n'
        '\n'
        '2. How We Use Information\n'
        '• Platform functionality\n'
        '• Vendor-user connections\n'
        '• Communication & inquiries\n'
        '• Personalization\n'
        '• Security & fraud prevention\n'
        '• Legal compliance\n'
        '\n'
        '3. Information Sharing\n'
        'We do not sell personal data.\n'
        'Information may be shared with vendors, service providers, legal authorities, or in business transfers.\n'
        '\n'
        '4. Data Protection & Retention\n'
        '• Secure servers & restricted access\n'
        '• Data retained only as required\n'
        '• No system is 100% secure\n'
        '\n'
        '5. Your Rights\n'
        'You may request access, correction, deletion, or withdrawal of consent.\n'
        'Contact: [Support Email]\n'
        '',
  ),
  LegalSection(
    id: 'cookies',
    title: 'Cookie Policy',
    icon: Icons.cookie_outlined,
    content:
        '\n'
        'Happywedz uses cookies to enhance user experience.\n'
        '\n'
        '1. Types of Cookies\n'
        '\n'
        '• Essential Cookies\n'
        'Required for login, navigation, and security.\n'
        '\n'
        '• Analytics Cookies\n'
        'Used to analyze usage and improve performance.\n'
        '\n'
        '• Functional Cookies\n'
        'Store preferences like language and filters.\n'
        '\n'
        '• Advertising Cookies\n'
        '(If enabled) Used for remarketing and ads.\n'
        '\n'
        '2. Third-Party Cookies\n'
        'Services like Google Analytics or ad networks may set cookies.\n'
        'You can disable cookies via browser settings, but some features may not work properly.\n'
        '',
  ),
  LegalSection(
    id: 'intellectual',
    title: 'Intellectual Property Policy',
    icon: Icons.copyright_rounded,
    content:
        '\n'
        '1. Ownership\n'
        'All content on Happywedz.com including text, logos, graphics, videos, databases, and code is owned by or licensed to Happywedz and protected by IP laws.\n'
        '\n'
        '2. User & Vendor Content\n'
        'By uploading content, you grant Happywedz a worldwide, royalty-free license to display, publish, format, distribute, and promote the content.\n'
        '\n'
        'Content remains yours and can be removed unless required for legal, review, or past marketing purposes.\n'
        '\n'
        '3. Copyright Infringement\n'
        'If you believe your copyrighted work is misused:\n'
        'Email: [Your Email]\n'
        'Subject: Copyright Infringement Notice\n'
        '',
  ),
  LegalSection(
    id: 'disclaimer',
    title: 'Disclaimer of Liability',
    icon: Icons.gavel_rounded,
    content:
        '\n'
        '1. Platform Disclaimer\n'
        'Happywedz is a listing and discovery platform only.\n'
        'We do not guarantee vendor quality, pricing, availability, or legality.\n'
        '\n'
        '2. User-Vendor Interaction\n'
        'All dealings are at your own risk.\n'
        'Happywedz is not responsible for:\n'
        '• Financial loss\n'
        '• Service delays or cancellations\n'
        '• Fraud or disputes\n'
        '• Misrepresentation\n'
        '• Vendor or user misconduct\n'
        '\n'
        '3. No Warranty\n'
        'The platform is provided "as is" and "as available".\n'
        'We do not guarantee uninterrupted service, error-free content, or accuracy of listings.\n'
        '',
  ),
];
