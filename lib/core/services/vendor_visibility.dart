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
/// Deliberately a denylist rather than `status == 'publish'`: a row whose
/// status is null, empty or some value not seen yet stays visible. An
/// allowlist would blank the entire catalogue the moment the backend added a
/// fourth status value, which is a far worse failure than one stale listing
/// slipping through. Once the full set of statuses is confirmed against a
/// live API, tighten [_hiddenStatuses] below — no call site needs to change.
library;

const Set<String> _hiddenStatuses = {'hide', 'hidden'};

/// True when [row] is a `/vendor-services` record the app must not display.
///
/// Reads the row's own `status`, not `vendor.status` — the latter is the
/// vendor *account* state ("pending"/"approved") that drives the claim
/// button, and has nothing to do with whether this listing is published.
bool isHiddenVendor(dynamic row) {
  if (row is! Map) return false;
  final status = row['status'];
  if (status == null) return false;
  return _hiddenStatuses.contains(status.toString().trim().toLowerCase());
}

/// [rows] with every hidden listing dropped.
///
/// Anything that is not a list yields an empty list, matching how the call
/// sites already treat an unexpected body.
List<dynamic> visibleVendors(dynamic rows) {
  if (rows is! List) return <dynamic>[];
  return rows.where((row) => !isHiddenVendor(row)).toList();
}
