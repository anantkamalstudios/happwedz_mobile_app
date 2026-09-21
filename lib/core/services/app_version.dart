/// Numeric comparison of app version strings.
///
/// Store version strings are compared *segment by segment as integers*, never
/// as text: `"2.0.10"` is greater than `"2.0.9"` even though it sorts before
/// it alphabetically, which is exactly the bug a string compare would ship.
///
/// Nothing here imports Flutter, so the comparison rules are unit-testable on
/// their own — see `test/app_version_test.dart`.
library;

/// A parsed version such as `2.0.10` or `2.0.10+47`.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.segments, {this.build});

  /// The dot-separated numeric segments, most significant first.
  final List<int> segments;

  /// The build number (`+47`, Android `versionCode`, iOS `CFBundleVersion`),
  /// when one is known. Store listings do not publish it, so this is usually
  /// null for a store version and non-null for the installed one.
  final int? build;

  /// Parses [raw], or returns null when it holds no usable version.
  ///
  /// Tolerates what stores and build systems actually emit: leading `v`,
  /// surrounding whitespace, a `+build` suffix, and trailing pre-release text
  /// (`2.1.0-beta.2` parses as `2.1.0`). Play Store listings that report
  /// "Varies with device" have no numbers at all and yield null, which callers
  /// treat as "unknown" rather than as an update.
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.isEmpty) return null;
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }

    int? build;
    final plus = text.indexOf('+');
    if (plus != -1) {
      build = int.tryParse(_leadingDigits(text.substring(plus + 1)));
      text = text.substring(0, plus);
    }

    // Drop any pre-release/qualifier tail: "2.1.0-beta.2" → "2.1.0".
    final dash = text.indexOf('-');
    if (dash != -1) text = text.substring(0, dash);

    final segments = <int>[];
    for (final part in text.split('.')) {
      final digits = _leadingDigits(part.trim());
      if (digits.isEmpty) break;
      final value = int.tryParse(digits);
      if (value == null) break;
      segments.add(value);
    }

    if (segments.isEmpty) return null;
    return AppVersion(segments, build: build);
  }

  static String _leadingDigits(String input) {
    final match = RegExp(r'^\d+').firstMatch(input);
    return match?.group(0) ?? '';
  }

  /// Compares numerically, padding the shorter version with zeros so `2.1`
  /// and `2.1.0` are equal and `2.1.1` is greater than both.
  ///
  /// Build numbers break a tie only when *both* sides have one: a store
  /// version with no published build must never be read as older than the
  /// installed build, or every user would be told to update forever.
  @override
  int compareTo(AppVersion other) {
    final length = segments.length > other.segments.length
        ? segments.length
        : other.segments.length;

    for (var i = 0; i < length; i++) {
      final mine = i < segments.length ? segments[i] : 0;
      final theirs = i < other.segments.length ? other.segments[i] : 0;
      if (mine != theirs) return mine.compareTo(theirs);
    }

    final myBuild = build;
    final theirBuild = other.build;
    if (myBuild != null && theirBuild != null) {
      return myBuild.compareTo(theirBuild);
    }
    return 0;
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  bool operator <(AppVersion other) => compareTo(other) < 0;
  bool operator >=(AppVersion other) => compareTo(other) >= 0;
  bool operator <=(AppVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hashAll([...segments, build]);

  @override
  String toString() {
    final name = segments.join('.');
    return build == null ? name : '$name+$build';
  }
}

/// True when [store] is a strictly newer release than [installed].
///
/// Returns false whenever either side cannot be parsed — an unreadable store
/// listing must never lock a user out of the app.
bool isUpdateRequired({required String? installed, required String? store}) {
  final current = AppVersion.tryParse(installed);
  final latest = AppVersion.tryParse(store);
  if (current == null || latest == null) return false;
  return latest > current;
}
