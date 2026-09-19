/// Models for the Wedding Websites module.
///
/// Every "from API" model tolerates the same messiness the React source has
/// to tolerate — `WeddingWebsiteForm.jsx`'s own `mapExistingToFormState` and
/// `WeddingPublicView.jsx`'s `normalizeWebsiteData` both read several
/// alternative keys for the same value (`bride.name` vs `brideData.name` vs
/// `brideData.title` vs a flat `brideName`), because the backend response
/// shape has drifted over time. Nothing here throws on a missing or
/// differently-shaped field — a malformed record yields a mostly-empty model.
library;

import 'dart:io';

// ---------------------------------------------------------------------------
// Safe readers (same conventions as lib/honeymoon/models/honeymoon_models.dart)
// ---------------------------------------------------------------------------

Object? _get(dynamic source, String key) => source is Map ? source[key] : null;

String asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value.trim();
  return value.toString().trim();
}

bool asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Always returns a list, never null, dropping null entries.
List<dynamic> asList(dynamic value) {
  if (value is List) return value.where((e) => e != null).toList();
  return const [];
}

/// First non-empty string among [candidates] — mirrors the `a || b || c`
/// chains the source uses everywhere it reads a value that moved keys.
String firstNonEmpty(List<dynamic> candidates, {String fallback = ''}) {
  for (final c in candidates) {
    final s = asString(c);
    if (s.isNotEmpty) return s;
  }
  return fallback;
}

/// An image can arrive as a bare URL string or as `{ url }` — both the
/// slider and gallery arrays use either shape depending on when the record
/// was written.
String _imageUrlOf(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is Map) {
    return firstNonEmpty([value['url'], value['imageUrl'], value['image_url']]);
  }
  return '';
}

/// Same `imageUrl || image_url || image` chain used for bride/groom/love
/// story/wedding party/when-where entries throughout the source.
String _entryImageUrl(dynamic value) {
  if (value is! Map) return '';
  return firstNonEmpty([value['imageUrl'], value['image_url'], value['image']]);
}

List<String> _imageUrlList(dynamic value) =>
    asList(value).map(_imageUrlOf).where((s) => s.isNotEmpty).toList();

// ---------------------------------------------------------------------------
// Templates (src/templates/index.js — TEMPLATE_LIST)
// ---------------------------------------------------------------------------

/// The three themes `TEMPLATE_LIST` in `src/templates/index.js` exposes.
/// Visual style only differs between them — the section set they render is
/// shared (see `src/templates/royal|floral|modern/index.jsx`).
enum WeddingWebsiteTemplate { royal, floral, modern }

extension WeddingWebsiteTemplateX on WeddingWebsiteTemplate {
  String get id => switch (this) {
    WeddingWebsiteTemplate.royal => 'royal',
    WeddingWebsiteTemplate.floral => 'floral',
    WeddingWebsiteTemplate.modern => 'modern',
  };

  String get label => switch (this) {
    WeddingWebsiteTemplate.royal => 'Royal Theme',
    WeddingWebsiteTemplate.floral => 'Floral Theme',
    WeddingWebsiteTemplate.modern => 'Modern Theme',
  };

  String get description => switch (this) {
    WeddingWebsiteTemplate.royal => 'Elegant gold and white wedding theme.',
    WeddingWebsiteTemplate.floral => 'Soft romantic floral design.',
    WeddingWebsiteTemplate.modern => 'Modern and sleek design.',
  };

  static WeddingWebsiteTemplate fromId(String? id) {
    switch (asString(id).toLowerCase()) {
      case 'floral':
        return WeddingWebsiteTemplate.floral;
      case 'modern':
        return WeddingWebsiteTemplate.modern;
      case 'royal':
      default:
        return WeddingWebsiteTemplate.royal;
    }
  }
}

// ---------------------------------------------------------------------------
// Display models — what a GET response is turned into
// ---------------------------------------------------------------------------

/// One row from `GET wedding-websites` (the list) — deliberately small; the
/// list card in `MyWeddingWebsites.jsx` only ever reads these fields.
class WeddingWebsiteSummary {
  const WeddingWebsiteSummary({
    required this.id,
    required this.templateId,
    this.weddingDate = '',
    this.isPublished = false,
    this.websiteUrl = '',
    this.brideName = '',
    this.groomName = '',
  });

  final String id;
  final String templateId;
  final String weddingDate;
  final bool isPublished;
  final String websiteUrl;
  final String brideName;
  final String groomName;

  factory WeddingWebsiteSummary.fromJson(dynamic json) {
    final map = json is Map ? json : const {};
    return WeddingWebsiteSummary(
      id: firstNonEmpty([map['id'], map['_id']]),
      templateId: asString(map['templateId'], fallback: 'royal'),
      weddingDate: asString(map['weddingDate']),
      isPublished: asBool(map['isPublished']),
      websiteUrl: asString(map['websiteUrl']),
      brideName: firstNonEmpty([
        map['brideName'],
        _get(map['bride'], 'name'),
        _get(map['bride'], 'title'),
        _get(map['brideData'], 'name'),
        _get(map['brideData'], 'title'),
      ]),
      groomName: firstNonEmpty([
        map['groomName'],
        _get(map['groom'], 'name'),
        _get(map['groom'], 'title'),
        _get(map['groomData'], 'name'),
        _get(map['groomData'], 'title'),
      ]),
    );
  }
}

/// Bride or groom's name/description/photo — `bride`/`groom` in the source's
/// normalised data (`bride.name`, `bride.description`, `bride.imageUrl`).
class WeddingPerson {
  const WeddingPerson({this.name = '', this.description = '', this.imageUrl = ''});

  final String name;
  final String description;
  final String imageUrl;

  static WeddingPerson fromEitherKey(dynamic map, String flatPrefix) {
    if (map is! Map) return const WeddingPerson();
    final person = map[flatPrefix]; // e.g. map['bride']
    final data = map['${flatPrefix}Data']; // e.g. map['brideData']
    return WeddingPerson(
      name: firstNonEmpty([
        map['${flatPrefix}Name'],
        _get(person, 'name'),
        _get(person, 'title'),
        _get(data, 'name'),
        _get(data, 'title'),
      ]),
      description: firstNonEmpty([
        map['${flatPrefix}Description'],
        _get(person, 'description'),
        _get(data, 'description'),
      ]),
      imageUrl: firstNonEmpty([
        map['${flatPrefix}ImageUrl'],
        _entryImageUrl(person),
        _entryImageUrl(data),
      ]),
    );
  }
}

/// One entry in the "Our Love Story" timeline (`loveStory[]`).
class LoveStoryEntry {
  const LoveStoryEntry({
    this.title = '',
    this.date = '',
    this.description = '',
    this.imageUrl = '',
  });

  final String title;
  final String date;
  final String description;
  final String imageUrl;

  factory LoveStoryEntry.fromJson(dynamic json) {
    final map = json is Map ? json : const {};
    return LoveStoryEntry(
      title: asString(map['title']),
      date: asString(map['date']),
      description: asString(map['description']),
      imageUrl: _entryImageUrl(map),
    );
  }
}

/// One member of the wedding party (`weddingParty[]`). The source accepts
/// both `name`/`relation` and the older `title`/`role` keys.
class WeddingPartyMember {
  const WeddingPartyMember({this.name = '', this.relation = '', this.imageUrl = ''});

  final String name;
  final String relation;
  final String imageUrl;

  factory WeddingPartyMember.fromJson(dynamic json) {
    final map = json is Map ? json : const {};
    return WeddingPartyMember(
      name: firstNonEmpty([map['name'], map['title']]),
      relation: firstNonEmpty([map['relation'], map['role']]),
      imageUrl: _entryImageUrl(map),
    );
  }
}

/// One "When & Where" event (ceremony, reception, …) — `whenWhere[]`.
class WhenWhereEvent {
  const WhenWhereEvent({
    this.title = '',
    this.location = '',
    this.description = '',
    this.date = '',
    this.time = '',
    this.imageUrl = '',
  });

  final String title;
  final String location;
  final String description;
  final String date;
  final String time;
  final String imageUrl;

  factory WhenWhereEvent.fromJson(dynamic json) {
    final map = json is Map ? json : const {};
    return WhenWhereEvent(
      title: asString(map['title']),
      location: asString(map['location']),
      description: asString(map['description']),
      date: asString(map['date']),
      time: asString(map['time']),
      imageUrl: _entryImageUrl(map),
    );
  }
}

/// The full record behind `GET wedding-websites/:id` and the public
/// `GET wedding/:websiteUrl` — everything a template needs to render, plus
/// the owner-only management fields (`isPublished`, `websiteUrl`).
class WeddingWebsiteDetail {
  const WeddingWebsiteDetail({
    required this.id,
    required this.template,
    this.weddingDate = '',
    this.isPublished = false,
    this.websiteUrl = '',
    this.bride = const WeddingPerson(),
    this.groom = const WeddingPerson(),
    this.sliderImages = const [],
    this.galleryImages = const [],
    this.loveStory = const [],
    this.weddingParty = const [],
    this.whenWhere = const [],
  });

  final String id;
  final WeddingWebsiteTemplate template;
  final String weddingDate;
  final bool isPublished;
  final String websiteUrl;
  final WeddingPerson bride;
  final WeddingPerson groom;
  final List<String> sliderImages;
  final List<String> galleryImages;
  final List<LoveStoryEntry> loveStory;
  final List<WeddingPartyMember> weddingParty;
  final List<WhenWhereEvent> whenWhere;

  factory WeddingWebsiteDetail.fromJson(dynamic json) {
    final map = json is Map ? json : const {};

    // `slider`/`gallery` are the live keys; `sliderImages`/`galleryImages`
    // are the older ones `normalizeWebsiteData` still falls back to.
    final sliderRaw = asList(map['slider']).isNotEmpty
        ? map['slider']
        : map['sliderImages'];
    final galleryRaw = asList(map['gallery']).isNotEmpty
        ? map['gallery']
        : map['galleryImages'];

    return WeddingWebsiteDetail(
      id: firstNonEmpty([map['id'], map['_id']]),
      template: WeddingWebsiteTemplateX.fromId(asString(map['templateId'])),
      weddingDate: asString(map['weddingDate']),
      isPublished: asBool(map['isPublished']),
      websiteUrl: asString(map['websiteUrl']),
      bride: WeddingPerson.fromEitherKey(map, 'bride'),
      groom: WeddingPerson.fromEitherKey(map, 'groom'),
      sliderImages: _imageUrlList(sliderRaw),
      galleryImages: _imageUrlList(galleryRaw),
      loveStory: asList(map['loveStory']).map(LoveStoryEntry.fromJson).toList(),
      weddingParty:
          asList(map['weddingParty']).map(WeddingPartyMember.fromJson).toList(),
      whenWhere: asList(map['whenWhere']).map(WhenWhereEvent.fromJson).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft models — what the create/edit form builds up before it is sent
// ---------------------------------------------------------------------------

/// One picked-or-kept image: either a freshly picked local [file] to upload,
/// or an [existingUrl] already on the server that should be preserved as-is.
/// Mirrors the form's own `{ file, preview }` item shape.
class DraftImage {
  const DraftImage({this.file, this.existingUrl});

  final File? file;
  final String? existingUrl;

  bool get isEmpty => file == null && (existingUrl == null || existingUrl!.isEmpty);

  factory DraftImage.existing(String url) => DraftImage(existingUrl: url);
  factory DraftImage.picked(File file) => DraftImage(file: file);
}

/// Draft for one "Our Love Story" entry — `title`/`date`/`description` plus
/// an image, matching the fields `WeddingWebsiteForm.jsx`'s `addLoveStory`
/// initialises and `reorderWithFilesFirst` later serialises.
class LoveStoryDraft {
  LoveStoryDraft({
    this.title = '',
    this.date = '',
    this.description = '',
    this.image = const DraftImage(),
  });

  String title;
  String date;
  String description;
  DraftImage image;

  factory LoveStoryDraft.fromDetail(LoveStoryEntry e) => LoveStoryDraft(
    title: e.title,
    date: e.date,
    description: e.description,
    image: e.imageUrl.isEmpty ? const DraftImage() : DraftImage.existing(e.imageUrl),
  );
}

/// Draft for one wedding-party member — `name`/`relation` plus an image.
class WeddingPartyDraft {
  WeddingPartyDraft({
    this.name = '',
    this.relation = '',
    this.image = const DraftImage(),
  });

  String name;
  String relation;
  DraftImage image;

  factory WeddingPartyDraft.fromDetail(WeddingPartyMember m) => WeddingPartyDraft(
    name: m.name,
    relation: m.relation,
    image: m.imageUrl.isEmpty ? const DraftImage() : DraftImage.existing(m.imageUrl),
  );
}

/// Draft for one "When & Where" event — `title`/`location`/`description`/
/// `date`/`time` plus an image.
class WhenWhereDraft {
  WhenWhereDraft({
    this.title = '',
    this.location = '',
    this.description = '',
    this.date = '',
    this.time = '',
    this.image = const DraftImage(),
  });

  String title;
  String location;
  String description;
  String date;
  String time;
  DraftImage image;

  factory WhenWhereDraft.fromDetail(WhenWhereEvent w) => WhenWhereDraft(
    title: w.title,
    location: w.location,
    description: w.description,
    date: w.date,
    time: w.time,
    image: w.imageUrl.isEmpty ? const DraftImage() : DraftImage.existing(w.imageUrl),
  );
}

/// Everything the create/update form collects before it is handed to
/// `WeddingWebsiteApi.createWebsite`/`updateWebsite`, which turns it into the
/// exact multipart shape `buildFormData` in `WeddingWebsiteForm.jsx` sends.
class WeddingWebsiteDraft {
  WeddingWebsiteDraft({
    required this.template,
    this.weddingDate = '',
    this.brideName = '',
    this.brideDescription = '',
    this.brideImage = const DraftImage(),
    this.groomName = '',
    this.groomDescription = '',
    this.groomImage = const DraftImage(),
    List<DraftImage>? sliderImages,
    List<DraftImage>? galleryImages,
    List<LoveStoryDraft>? loveStory,
    List<WeddingPartyDraft>? weddingParty,
    List<WhenWhereDraft>? whenWhere,
  }) : sliderImages = sliderImages ?? [],
       galleryImages = galleryImages ?? [],
       loveStory = loveStory ?? [],
       weddingParty = weddingParty ?? [],
       whenWhere = whenWhere ?? [];

  WeddingWebsiteTemplate template;
  String weddingDate;

  String brideName;
  String brideDescription;
  DraftImage brideImage;

  String groomName;
  String groomDescription;
  DraftImage groomImage;

  final List<DraftImage> sliderImages;
  final List<DraftImage> galleryImages;
  final List<LoveStoryDraft> loveStory;
  final List<WeddingPartyDraft> weddingParty;
  final List<WhenWhereDraft> whenWhere;

  /// Seeds a draft from an existing record, for the edit flow — mirrors
  /// `mapExistingToFormState` in `WeddingWebsiteForm.jsx`.
  factory WeddingWebsiteDraft.fromDetail(WeddingWebsiteDetail d) => WeddingWebsiteDraft(
    template: d.template,
    weddingDate: d.weddingDate.length >= 10 ? d.weddingDate.substring(0, 10) : d.weddingDate,
    brideName: d.bride.name,
    brideDescription: d.bride.description,
    brideImage: d.bride.imageUrl.isEmpty
        ? const DraftImage()
        : DraftImage.existing(d.bride.imageUrl),
    groomName: d.groom.name,
    groomDescription: d.groom.description,
    groomImage: d.groom.imageUrl.isEmpty
        ? const DraftImage()
        : DraftImage.existing(d.groom.imageUrl),
    sliderImages: d.sliderImages.map(DraftImage.existing).toList(),
    galleryImages: d.galleryImages.map(DraftImage.existing).toList(),
    loveStory: d.loveStory.map(LoveStoryDraft.fromDetail).toList(),
    weddingParty: d.weddingParty.map(WeddingPartyDraft.fromDetail).toList(),
    whenWhere: d.whenWhere.map(WhenWhereDraft.fromDetail).toList(),
  );
}
