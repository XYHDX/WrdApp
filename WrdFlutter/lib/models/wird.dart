import 'gate.dart';
import '../util/ids.dart';

/// A wird — one committed unit of devotion.
class Wird {
  final String id;
  final String title;
  final String? text; // the dhikr/duʿāʼ text, if any
  final String? source; // e.g. "رواه مسلم" — every duʿāʼ shows its source
  final Gate gate;
  final int targetCount; // 1 = read once / check off; >1 = counter
  final bool isCustom; // written by the user
  final String? note; // optional personal dedication/intention
  final int? reminderMinutes; // optional daily reminder, minutes from midnight

  Wird({
    String? id,
    required this.title,
    this.text,
    this.source,
    required this.gate,
    this.targetCount = 1,
    this.isCustom = false,
    this.note,
    this.reminderMinutes,
  }) : id = id ?? newId();

  Wird copyWith({
    String? id,
    String? title,
    String? text,
    String? source,
    Gate? gate,
    int? targetCount,
    bool? isCustom,
    String? note,
    int? reminderMinutes,
    bool clearReminder = false,
  }) {
    return Wird(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      source: source ?? this.source,
      gate: gate ?? this.gate,
      targetCount: targetCount ?? this.targetCount,
      isCustom: isCustom ?? this.isCustom,
      note: note ?? this.note,
      reminderMinutes:
          clearReminder ? null : (reminderMinutes ?? this.reminderMinutes),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (text != null) 'text': text,
        if (source != null) 'source': source,
        'gate': gate.wire,
        'targetCount': targetCount,
        'isCustom': isCustom,
        if (note != null) 'note': note,
        if (reminderMinutes != null) 'reminderMinutes': reminderMinutes,
      };

  factory Wird.fromJson(Map<String, dynamic> json) => Wird(
        id: (json['id'] as String).toUpperCase(),
        title: json['title'] as String? ?? '',
        text: json['text'] as String?,
        source: json['source'] as String?,
        gate: Gate.fromWire(json['gate'] as String?),
        targetCount: (json['targetCount'] as num?)?.toInt() ?? 1,
        isCustom: json['isCustom'] as bool? ?? false,
        note: json['note'] as String?,
        reminderMinutes: (json['reminderMinutes'] as num?)?.toInt(),
      );

  @override
  bool operator ==(Object other) => other is Wird && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
