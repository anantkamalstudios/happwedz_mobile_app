/// One rule for "may this vendor listing be shown?", shared by every screen
/// that renders `/vendor-services` rows.
///
/// The catalogue endpoint returns unpublished listings alongside live ones:
/// each row carries a top-level `status`, and `"hide"` marks a listing the
/// vendor or an admin has taken down. The API does not filter these out, so
/// until it does, the app has to — everywhere a row can surface (home rails,
/// category lists, venue lists, search, autocomplete suggestions, wishlist
/// entries, and slug/id deep links into the detail screen).
///
/// An allowlist: only a row whose `status` is exactly `"publish"` is shown.
/// Anything else — `"hide"`, null, empty, or a value not seen yet — is
/// dropped. (Earlier this was a denylist of `{'hide', 'hidden'}`; switched
/// on product request so nothing unpublished can ever surface.)
library;

// const Set<String> _hiddenStatuses = {'hide', 'hidden'};

const String _publishedStatus = 'publish';

/// True when [row] is a `/vendor-services` record the app must not display.
///
/// Reads the row's own `status`, not `vendor.status` — the latter is the
/// vendor *account* state ("pending"/"approved") that drives the claim
/// button, and has nothing to do with whether this listing is published.
bool isHiddenVendor(dynamic row) {
  if (row is! Map) return false;
  final status = row['status'];
  // if (status == null) return false;
  // return _hiddenStatuses.contains(status.toString().trim().toLowerCase());
  return status?.toString().trim().toLowerCase() != _publishedStatus;
}

/// [rows] with every hidden listing dropped.
///
/// Anything that is not a list yields an empty list, matching how the call
/// sites already treat an unexpected body.
List<dynamic> visibleVendors(dynamic rows) {
  if (rows is! List) return <dynamic>[];
  return rows.where((row) => !isHiddenVendor(row)).toList();
}
