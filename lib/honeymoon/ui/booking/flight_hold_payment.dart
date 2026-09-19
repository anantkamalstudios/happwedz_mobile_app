/// Paying for a blocked (held) fare — the web's `payConfirm`, used by
/// `UpcomingBookings.jsx` and the dashboard's `FlightBookingDetail.jsx`.
///
/// ```
/// create_order  {…row, offer_id: order_id, is_hold_confirm: true,
///                booking_payload: {bookingId: order_id}, passengers: []}
///   → Razorpay ("Confirm held flight booking")
///   → verify_and_book {razorpay_order_id, razorpay_payment_id,
///                      razorpay_signature}      — no booking_payload
/// ```
///
/// `is_hold_confirm` tells the backend to ticket the held PNR (confirm-book)
/// instead of booking afresh, which is why the booking payload carries only
/// the booking id.
library;

import 'package:flutter/material.dart';

import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../../payment/razorpay_checkout.dart';

/// How a held-fare payment ended.
typedef HoldPaymentResult = ({bool paid, bool dismissed, String? error});

/// The fields the web sends for a held booking, from a `my-bookings` row or
/// the equivalent the confirmation screen already holds.
typedef HeldFlight = ({
  String orderId,
  double amount,
  String tripType,
  String from,
  String to,
  String departure,
  String arrival,
  String flightNo,
  String airline,
  String cabinClass,
  String email,
  String phone,
  String passengerName,
});

/// A [HeldFlight] from a `GET /tj/my-bookings` row.
HeldFlight heldFlightFromRow(TravelBooking booking) {
  final r = booking.raw;
  return (
    orderId: booking.reference,
    // `amount_paid || price` — a held row has amount_paid 0.
    amount: asDouble(readKey(r, 'amount_paid')) > 0
        ? asDouble(readKey(r, 'amount_paid'))
        : asDouble(readKey(r, 'price')),
    tripType: asString(readKey(r, 'trip_type')),
    from: asString(readKey(r, 'from_iata')),
    to: asString(readKey(r, 'to_iata')),
    departure: asString(readKey(r, 'departure')),
    arrival: asString(readKey(r, 'arrival')),
    flightNo: asString(readKey(r, 'flight_no')),
    airline: asString(readKey(r, 'airline')),
    cabinClass: asString(readKey(r, 'cabin_class')),
    email: asString(readKey(r, 'contact_email')),
    phone: asString(readKey(r, 'contact_phone')),
    passengerName: asString(readKey(r, 'passenger_name')),
  );
}

Future<HoldPaymentResult> payHeldFlight(
  BuildContext context, {
  required HoneymoonApi api,
  required HeldFlight held,
}) async {
  final PaymentOrder order;
  try {
    order = await api.createFlightPaymentOrder({
      'provider': 'tripjack',
      'offer_id': held.orderId,
      'price': held.amount,
      'trip_type': held.tripType,
      'from': held.from,
      'to': held.to,
      'departure': held.departure,
      'arrival': held.arrival,
      'flight_no': held.flightNo,
      'airline': held.airline,
      'cabin_class': held.cabinClass,
      'passengers': const <dynamic>[],
      'contact': {'email': held.email, 'phone': held.phone},
      'booking_payload': {'bookingId': held.orderId},
    }, isHoldConfirm: true);
  } catch (e) {
    return (
      paid: false,
      dismissed: false,
      error: e is HoneymoonApiException
          ? e.message
          : 'Could not start payment.',
    );
  }
  if (!context.mounted) return (paid: false, dismissed: true, error: null);

  final outcome = await RazorpayCheckout.open(
    context,
    order: order,
    title: 'HappyWedz',
    description: 'Confirm held flight booking',
    // Test keys only: a Razorpay test account caps UPI and wallets far
    // below a flight fare ("Amount exceeds maximum amount allowed"), so
    // they are hidden there. Live keys see every method.
    restrictMethodsInTestMode: true,
    prefill: (name: held.passengerName, email: held.email, contact: held.phone),
  );

  switch (outcome) {
    case RazorpayDismissed():
      return (paid: false, dismissed: true, error: null);
    case RazorpayFailure(:final message):
      return (paid: false, dismissed: false, error: message);
    case RazorpaySuccess(:final result):
      try {
        await api.verifyAndBookFlight(result.toVerifyJson());
        return (paid: true, dismissed: false, error: null);
      } catch (e) {
        // The money has moved; the payment id is what support needs.
        final message = e is HoneymoonApiException
            ? firstNonEmpty([
                readKey(e.data, 'message'),
              ], fallback: 'Could not confirm the booking.')
            : 'Could not confirm the booking.';
        return (
          paid: false,
          dismissed: false,
          error: '$message (Payment ID: ${result.paymentId})',
        );
      }
  }
}
