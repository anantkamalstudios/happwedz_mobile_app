/// Razorpay checkout for the Honeymoon booking flows.
///
/// The web client opens Razorpay's `checkout.js` in the page. There is no
/// native equivalent already in this project, so rather than add a plugin the
/// same script is hosted inside a [WebView] and its callbacks are bridged back
/// to Dart through a single JavaScript channel. The options object below is
/// the one the web client builds, field for field, so a payment started on
/// either surface reaches the backend identically.
///
/// ```dart
/// final outcome = await RazorpayCheckout.open(
///   context,
///   order: order,
///   title: 'HappyWedz Flights',
///   prefill: (name: name, email: email, contact: phone),
/// );
/// switch (outcome) {
///   case RazorpaySuccess(:final result): // verify on the backend
///   case RazorpayFailure(:final message): // show it
///   case RazorpayDismissed(): // traveller backed out
/// }
/// ```
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/core.dart';
import '../models/booking_models.dart';

/// What came back from the gateway.
sealed class RazorpayOutcome {
  const RazorpayOutcome();
}

/// Payment authorised. The signature still has to be verified server-side —
/// this is not a booking.
class RazorpaySuccess extends RazorpayOutcome {
  const RazorpaySuccess(this.result);

  final PaymentResult result;
}

/// The gateway rejected the payment, or the page could not be loaded.
class RazorpayFailure extends RazorpayOutcome {
  const RazorpayFailure(this.message);

  final String message;
}

/// The traveller closed checkout without paying.
class RazorpayDismissed extends RazorpayOutcome {
  const RazorpayDismissed();
}

/// Name / email / phone to prefill the gateway form with.
typedef RazorpayPrefill = ({String name, String email, String contact});

class RazorpayCheckout {
  const RazorpayCheckout._();

  /// Opens checkout full-screen and resolves once the gateway settles.
  ///
  /// Never returns null: a traveller who backs out gets [RazorpayDismissed],
  /// so the caller always has a state to render.
  static Future<RazorpayOutcome> open(
    BuildContext context, {
    required PaymentOrder order,
    required String title,
    required RazorpayPrefill prefill,
    String description = '',
  }) async {
    final outcome = await Navigator.of(context).push<RazorpayOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RazorpayCheckoutPage(
          order: order,
          title: title,
          description: description,
          prefill: prefill,
        ),
      ),
    );
    return outcome ?? const RazorpayDismissed();
  }
}

// ---------------------------------------------------------------------------

class _RazorpayCheckoutPage extends StatefulWidget {
  const _RazorpayCheckoutPage({
    required this.order,
    required this.title,
    required this.description,
    required this.prefill,
  });

  final PaymentOrder order;
  final String title;
  final String description;
  final RazorpayPrefill prefill;

  @override
  State<_RazorpayCheckoutPage> createState() => _RazorpayCheckoutPageState();
}

class _RazorpayCheckoutPageState extends State<_RazorpayCheckoutPage> {
  late final WebViewController _controller;

  bool _loading = true;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('RazorpayFlutter', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: _onNavigation,
          onWebResourceError: (error) {
            // Only a failure of the top-level document is fatal; sub-resources
            // (an analytics beacon, a bank logo) fail all the time and must
            // not tear down a checkout that is otherwise working.
            if (error.isForMainFrame == true) {
              _finish(
                const RazorpayFailure(
                  'The payment page could not be loaded. '
                  'Please check your connection and try again.',
                ),
              );
            }
          },
        ),
      )
      ..loadHtmlString(_checkoutHtml(), baseUrl: 'https://happywedz.com/');
  }

  /// UPI and bank apps are opened with `upi:` / `intent:` links, which a
  /// WebView cannot load itself — they have to be handed to the OS.
  FutureOr<NavigationDecision> _onNavigation(NavigationRequest request) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;
    if (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'about') {
      return NavigationDecision.navigate;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No app installed for that scheme — staying put lets the traveller
      // pick another payment method rather than dead-ending.
    }
    return NavigationDecision.prevent;
  }

  void _onMessage(JavaScriptMessage message) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(message.message);
      payload = decoded is Map
          ? decoded.map((k, v) => MapEntry('$k', v))
          : <String, dynamic>{};
    } catch (_) {
      _finish(const RazorpayFailure('The payment could not be completed.'));
      return;
    }

    switch (payload['event']) {
      case 'success':
        _finish(RazorpaySuccess(PaymentResult.fromJson(payload)));
      case 'dismissed':
        _finish(const RazorpayDismissed());
      case 'failed':
        final description = '${payload['description'] ?? ''}'.trim();
        _finish(
          RazorpayFailure(
            description.isEmpty
                ? 'The payment failed. Please try again.'
                : description,
          ),
        );
      default:
        _finish(const RazorpayFailure('The payment could not be completed.'));
    }
  }

  /// Guards against a double pop — the gateway can fire `ondismiss` right
  /// after a failure, and popping twice would take the traveller off the
  /// booking screen as well.
  void _finish(RazorpayOutcome outcome) {
    if (_settled || !mounted) return;
    _settled = true;
    Navigator.of(context).pop(outcome);
  }

  Future<void> _confirmExit() async {
    final leave = await ConfirmPopup.show(
      context,
      title: 'Cancel this payment?',
      message: 'Your booking is not confirmed until the payment goes through.',
      // Kept short: the dialog's two buttons share a row, and "Cancel payment"
      // ellipsised to "Cancel pay…" on a 360 dp screen.
      confirmLabel: 'Cancel',
      cancelLabel: 'Keep paying',
      icon: Icons.credit_card_off_rounded,
      danger: true,
    );
    if (leave) _finish(const RazorpayDismissed());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppTopBar(
          title: 'Secure payment',
          showBack: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel payment',
              onPressed: _confirmExit,
            ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const ColoredBox(
                  color: Colors.white,
                  child: Center(child: AppLoader()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The checkout host page.
  ///
  /// Values are JSON-encoded rather than interpolated raw: a traveller called
  /// O'Brien would otherwise terminate the string and break the script.
  String _checkoutHtml() {
    final options = <String, dynamic>{
      'key': widget.order.keyId,
      'order_id': widget.order.orderId,
      if (widget.order.amountInPaise > 0) 'amount': widget.order.amountInPaise,
      'currency': widget.order.currency,
      'name': widget.title,
      'description': widget.description.isEmpty
          ? widget.title
          : widget.description,
      'prefill': {
        'name': widget.prefill.name,
        'email': widget.prefill.email,
        'contact': widget.prefill.contact,
      },
      // Matches the brand colour the web checkout uses.
      'theme': {'color': '#ed1173'},
      'retry': {'enabled': false},
    };

    return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <style>
    html, body { margin:0; padding:0; height:100%; background:#fff;
      font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; }
    #msg { display:flex; height:100%; align-items:center; justify-content:center;
      color:#616161; font-size:14px; text-align:center; padding:24px; }
  </style>
</head>
<body>
  <div id="msg">Opening secure payment…</div>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <script>
    var sent = false;
    function post(payload) {
      if (sent) return;
      sent = true;
      RazorpayFlutter.postMessage(JSON.stringify(payload));
    }

    function start() {
      if (typeof Razorpay === 'undefined') {
        post({ event: 'failed', description: 'The payment gateway could not be reached.' });
        return;
      }
      var options = ${jsonEncode(options)};
      options.handler = function (response) {
        post({
          event: 'success',
          razorpay_order_id: response.razorpay_order_id,
          razorpay_payment_id: response.razorpay_payment_id,
          razorpay_signature: response.razorpay_signature
        });
      };
      options.modal = {
        escape: false,
        ondismiss: function () { post({ event: 'dismissed' }); }
      };

      var rzp = new Razorpay(options);
      rzp.on('payment.failed', function (resp) {
        post({
          event: 'failed',
          description: (resp && resp.error && (resp.error.description || resp.error.reason)) || ''
        });
      });
      rzp.open();
    }

    // checkout.js may still be in flight when this runs.
    if (document.readyState === 'complete') { start(); }
    else { window.addEventListener('load', start); }
    // A blocked or very slow script must not leave a blank screen forever.
    setTimeout(function () {
      if (typeof Razorpay === 'undefined') {
        post({ event: 'failed', description: 'The payment gateway did not load. Please try again.' });
      }
    }, 15000);
  </script>
</body>
</html>
''';
  }
}
