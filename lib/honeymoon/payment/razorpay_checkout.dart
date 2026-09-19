/// Razorpay checkout for the Honeymoon booking flows.
///
/// On Android and iOS this uses Razorpay's native SDK (`razorpay_flutter`).
///
/// BUG FIX: checkout used to run Razorpay's `checkout.js` inside a
/// [WebView]. Netbanking bank pages and card OTP pages open in a *pop-up*
/// window that reports back to its opener; `webview_flutter` has no second
/// window, so it loads the pop-up URL into the same view, the checkout page
/// is replaced, and the payment ends as "could not be completed" — while the
/// same order pays fine on the web, where the browser opens a real pop-up.
/// The native SDK handles those pages itself. The WebView checkout below is
/// kept as the fallback for any other platform.
///
/// Either way the options are the ones the web client builds, field for
/// field, so a payment reaches the backend identically.
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

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
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
    bool restrictMethodsInTestMode = false,
    bool allowRetry = false,
  }) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return _openNative(
        order: order,
        title: title,
        prefill: prefill,
        description: description,
        restrictMethodsInTestMode: restrictMethodsInTestMode,
      );
    }

    // Fallback: the WebView checkout.
    final outcome = await Navigator.of(context).push<RazorpayOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RazorpayCheckoutPage(
          order: order,
          title: title,
          description: description,
          prefill: prefill,
          restrictMethodsInTestMode: restrictMethodsInTestMode,
          allowRetry: allowRetry,
        ),
      ),
    );
    return outcome ?? const RazorpayDismissed();
  }

  /// The native SDK checkout. Same options as the web's
  /// `new window.Razorpay({...})`; the SDK keeps its own retry, so a
  /// declined attempt lets the traveller pick another method and only the
  /// final outcome comes back.
  static Future<RazorpayOutcome> _openNative({
    required PaymentOrder order,
    required String title,
    required RazorpayPrefill prefill,
    required String description,
    required bool restrictMethodsInTestMode,
  }) async {
    final options = <String, dynamic>{
      'key': order.keyId,
      'order_id': order.orderId,
      if (order.amountInPaise > 0) 'amount': order.amountInPaise,
      'currency': order.currency,
      'name': title,
      'description': description.isEmpty ? title : description,
      'prefill': {
        'name': prefill.name,
        'email': prefill.email,
        'contact': prefill.contact,
      },
      'theme': {'color': '#ed1173'},
      // The web's hotel checkout hides these in test mode, where a test
      // account caps them far below a hotel stay.
      if (restrictMethodsInTestMode && order.keyId.startsWith('rzp_test_'))
        'method': {'upi': false, 'wallet': false, 'paylater': false},
    };
    debugPrint('[RazorpayCheckout] native options: ${jsonEncode(options)}');

    final razorpay = Razorpay();
    final completer = Completer<RazorpayOutcome>();
    void settle(RazorpayOutcome outcome) {
      if (!completer.isCompleted) completer.complete(outcome);
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      debugPrint('[RazorpayCheckout] native success: ${r.paymentId}');
      settle(
        RazorpaySuccess(
          PaymentResult(
            orderId: r.orderId ?? order.orderId,
            paymentId: r.paymentId ?? '',
            signature: r.signature ?? '',
          ),
        ),
      );
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      debugPrint(
        '[RazorpayCheckout] native error: code=${r.code} message=${r.message} '
        'error=${r.error}',
      );
      if (r.code == Razorpay.PAYMENT_CANCELLED) {
        settle(const RazorpayDismissed());
        return;
      }
      settle(RazorpayFailure(_nativeErrorText(r)));
    });
    // A wallet that takes over outside checkout — nothing is paid here.
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {
      debugPrint('[RazorpayCheckout] native external wallet: ${r.walletName}');
      settle(const RazorpayDismissed());
    });

    try {
      razorpay.open(options);
      return await completer.future;
    } catch (e) {
      debugPrint('[RazorpayCheckout] native open failed: $e');
      return const RazorpayFailure(
        'The payment could not be started. Please try again.',
      );
    } finally {
      razorpay.clear();
    }
  }

  /// The SDK reports errors as a plain message or as the gateway's JSON body
  /// (`{"error":{"description": …}}`); the description is what is shown.
  static String _nativeErrorText(PaymentFailureResponse r) {
    // Razorpay's "Payment could not be completed" on an account without
    // international payments is really `international_transaction_not_allowed`
    // (the web's hotel flow recognises the same pair). Said plainly, the
    // traveller knows to switch card rather than retry the same one.
    final everything = '${r.message} ${r.error}'.toLowerCase();
    if (everything.contains('international_transaction_not_allowed') ||
        everything.contains('international cards are not supported') ||
        everything.contains('payment could not be completed')) {
      return 'This card was treated as an international card, which is not '
          'enabled for this account. Please pay with an Indian card or '
          'netbanking.';
    }
    final fromBody = r.error?['error'] is Map
        ? (r.error?['error'] as Map)['description']
        : null;
    if (fromBody is String && fromBody.trim().isNotEmpty) return fromBody;
    final message = r.message ?? '';
    try {
      final decoded = jsonDecode(message);
      final description = decoded is Map && decoded['error'] is Map
          ? (decoded['error'] as Map)['description']
          : null;
      if (description is String && description.trim().isNotEmpty) {
        return description;
      }
    } catch (_) {
      // Plain text.
    }
    return message.trim().isEmpty
        ? 'The payment could not be completed.'
        : message.trim();
  }
}

// ---------------------------------------------------------------------------

class _RazorpayCheckoutPage extends StatefulWidget {
  const _RazorpayCheckoutPage({
    required this.order,
    required this.title,
    required this.description,
    required this.prefill,
    this.restrictMethodsInTestMode = false,
    this.allowRetry = false,
  });

  final PaymentOrder order;
  final String title;
  final String description;
  final RazorpayPrefill prefill;

  /// With a `rzp_test_` key, hide UPI, wallets and pay-later. A test account
  /// caps those methods far below a hotel stay ("Amount exceeds maximum
  /// amount allowed"), so the web's hotel checkout offers card and netbanking
  /// only in test mode. Live keys are unaffected.
  final bool restrictMethodsInTestMode;

  /// Keep Razorpay's own retry: a declined attempt ("Please use another
  /// method") leaves checkout open so the traveller can pick another card or
  /// method, as the web's hotel checkout does (it never disables retry). The
  /// failure is reported only if they then close checkout without paying.
  final bool allowRetry;

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
    debugPrint(
      '[RazorpayCheckout] opening order=${widget.order.orderId} '
      'key=${widget.order.keyId} amountInPaise=${widget.order.amountInPaise} '
      'currency=${widget.order.currency}',
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('RazorpayFlutter', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint('[RazorpayCheckout] page finished: $url');
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: _onNavigation,
          onWebResourceError: (error) {
            debugPrint(
              '[RazorpayCheckout] web resource error: '
              'mainFrame=${error.isForMainFrame} '
              'code=${error.errorCode} '
              'description=${error.description} '
              'url=${error.url}',
            );
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
    debugPrint('[RazorpayCheckout] navigation request: ${request.url}');
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;
    if (uri.scheme == 'http' ||
        uri.scheme == 'https' ||
        uri.scheme == 'about') {
      return NavigationDecision.navigate;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // No app installed for that scheme — staying put lets the traveller
      // pick another payment method rather than dead-ending.
      debugPrint('[RazorpayCheckout] could not launch $uri: $e');
    }
    return NavigationDecision.prevent;
  }

  void _onMessage(JavaScriptMessage message) {
    debugPrint('[RazorpayCheckout] ← message: ${message.message}');

    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(message.message);
      payload = decoded is Map
          ? decoded.map((k, v) => MapEntry('$k', v))
          : <String, dynamic>{};
    } catch (e) {
      debugPrint('[RazorpayCheckout] message decode error: $e');
      _finish(const RazorpayFailure('The payment could not be completed.'));
      return;
    }

    switch (payload['event']) {
      case 'success':
        debugPrint(
          '[RazorpayCheckout] success: '
          'payment_id=${payload['razorpay_payment_id']} '
          'order_id=${payload['razorpay_order_id']}',
        );
        _finish(RazorpaySuccess(PaymentResult.fromJson(payload)));
      case 'dismissed':
        debugPrint('[RazorpayCheckout] dismissed by traveller');
        _finish(const RazorpayDismissed());
      case 'failed':
        final description = '${payload['description'] ?? ''}'.trim();
        debugPrint('[RazorpayCheckout] failed: $description');
        _finish(
          RazorpayFailure(
            description.isEmpty
                ? 'The payment failed. Please try again.'
                : description,
          ),
        );
      default:
        debugPrint(
          '[RazorpayCheckout] unrecognised event: ${payload['event']}',
        );
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
      if (!widget.allowRetry) 'retry': {'enabled': false},
      if (widget.restrictMethodsInTestMode &&
          widget.order.keyId.startsWith('rzp_test_'))
        'method': {'upi': false, 'wallet': false, 'paylater': false},
    };
    // DEBUG: the exact options checkout receives (the key id is public), so a
    // gateway refusal can be traced to the amount or the enabled methods.
    debugPrint('[RazorpayCheckout] options: ${jsonEncode(options)}');

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
      var allowRetry = ${widget.allowRetry};
      var lastError = '';
      options.modal = {
        escape: false,
        ondismiss: function () {
          // Closed after a declined attempt: report why, not a plain cancel.
          if (lastError) { post({ event: 'failed', description: lastError }); }
          else { post({ event: 'dismissed' }); }
        }
      };

      var rzp = new Razorpay(options);
      rzp.on('payment.failed', function (resp) {
        var description =
          (resp && resp.error && (resp.error.description || resp.error.reason)) || '';
        if (allowRetry) {
          // Checkout stays open for another method; remember why this failed.
          lastError = description || 'The payment could not be completed.';
          return;
        }
        post({ event: 'failed', description: description });
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
