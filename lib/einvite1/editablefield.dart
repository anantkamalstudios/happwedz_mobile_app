class EditableField {
  double x;
  double y;
  final String id;
  String color;
  String label;
  double fontSize;
  String fontFamily;
  String text;
  double rotation;
  double scale;


  EditableField({
    required this.x,
    required this.y,
    required this.id,
    required this.color,
    required this.label,
    required this.fontSize,
    required this.fontFamily,
    required this.text,
    this.rotation = 0.0,
    this.scale = 1.0,
  });


  factory EditableField.fromJson(Map<String, dynamic> json) {
    return EditableField(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      id: json['id'].toString(),
      color: json['color'] ?? '#000000',
      label: json['label'] ?? '',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 20.0,
      fontFamily: json['fontFamily'] ?? 'Arial',
      text: json['defaultText'] ?? '',
    );
  }


  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'id': id,
    'color': color,
    'label': label,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'text': text,
    'rotation': rotation,
    'scale': scale,
  };
}