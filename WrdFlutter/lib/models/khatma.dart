import '../util/ids.dart';
import '../util/dates.dart';

/// Khatma circles — حلقات الختمة.
class KhatmaMember {
  final String id;
  String name;
  List<int> assigned; // juzʼ numbers 1…30
  Set<int> completed;

  KhatmaMember({
    String? id,
    required this.name,
    List<int>? assigned,
    Set<int>? completed,
  })  : id = id ?? newId(),
        assigned = assigned ?? [],
        completed = completed ?? {};

  KhatmaMember copy() => KhatmaMember(
        id: id,
        name: name,
        assigned: List.of(assigned),
        completed: Set.of(completed),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'assigned': assigned,
        'completed': completed.toList()..sort(),
      };

  factory KhatmaMember.fromJson(Map<String, dynamic> json) => KhatmaMember(
        id: (json['id'] as String).toUpperCase(),
        name: json['name'] as String? ?? '',
        assigned: (json['assigned'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        completed: (json['completed'] as List? ?? [])
            .map((e) => (e as num).toInt())
            .toSet(),
      );
}

class KhatmaCircle {
  final String id;
  String name;
  String? dedication;
  List<KhatmaMember> members;
  DateTime createdAt;

  /// null = created on this device (creator). false = joined via an invite.
  bool? createdHere;

  /// In a joined circle: which member is *me* — only that member's ajzāʼ
  /// are editable.
  String? myMemberId;

  KhatmaCircle({
    String? id,
    required this.name,
    this.dedication,
    List<KhatmaMember>? members,
    DateTime? createdAt,
    this.createdHere,
    this.myMemberId,
  })  : id = id ?? newId(),
        members = members ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get isCreator => createdHere ?? true;
  int get completedCount =>
      members.fold(0, (total, m) => total + m.completed.length);
  double get progress => completedCount / 30.0;
  bool get isComplete => completedCount >= 30;

  bool canEdit(KhatmaMember member) => isCreator || member.id == myMemberId;

  KhatmaCircle copy() => KhatmaCircle(
        id: id,
        name: name,
        dedication: dedication,
        members: members.map((m) => m.copy()).toList(),
        createdAt: createdAt,
        createdHere: createdHere,
        myMemberId: myMemberId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (dedication != null) 'dedication': dedication,
        'members': members.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        if (createdHere != null) 'createdHere': createdHere,
        if (myMemberId != null) 'myMemberID': myMemberId,
      };

  factory KhatmaCircle.fromJson(Map<String, dynamic> json) => KhatmaCircle(
        id: (json['id'] as String).toUpperCase(),
        name: json['name'] as String? ?? '',
        dedication: json['dedication'] as String?,
        members: (json['members'] as List? ?? [])
            .map((m) => KhatmaMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: parseFlexibleDate(json['createdAt']) ?? DateTime.now(),
        createdHere: json['createdHere'] as bool?,
        myMemberId: (json['myMemberID'] as String?)?.toUpperCase(),
      );
}
