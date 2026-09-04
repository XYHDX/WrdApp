import 'dart:convert';

import '../models/khatma.dart';
import '../util/arabic.dart';
import '../util/dates.dart';

/// Offline circle sync — sharing by code, WhatsApp-friendly, no server, no
/// accounts. Invite: "WRD1.<base64url>" carries the whole circle.
/// Progress: "WRDU.<base64url>" carries one member's completed ajzāʼ.
/// Paste either into WRD and it merges. Wire format is compatible with the
/// Swift app's codes (ISO dates are accepted alongside Foundation's seconds).
class ProgressUpdate {
  final String circleId;
  final String memberId;
  final String memberName;
  final List<int> completed;

  const ProgressUpdate({
    required this.circleId,
    required this.memberId,
    required this.memberName,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'circleID': circleId,
        'memberID': memberId,
        'memberName': memberName,
        'completed': completed,
      };

  factory ProgressUpdate.fromJson(Map<String, dynamic> json) => ProgressUpdate(
        circleId: (json['circleID'] as String).toUpperCase(),
        memberId: (json['memberID'] as String).toUpperCase(),
        memberName: json['memberName'] as String? ?? '',
        completed: (json['completed'] as List? ?? []).map((e) => (e as num).toInt()).toList(),
      );
}

sealed class Decoded {}

class DecodedCircle extends Decoded {
  final KhatmaCircle circle;
  DecodedCircle(this.circle);
}

class DecodedProgress extends Decoded {
  final ProgressUpdate update;
  DecodedProgress(this.update);
}

sealed class Outcome {}

class OutcomeDecoded extends Outcome {
  final Decoded decoded;
  OutcomeDecoded(this.decoded);
}

class OutcomeExpired extends Outcome {}

class OutcomeNotFound extends Outcome {}

class CircleCodec {
  CircleCodec._();

  /// Invitations expire — best-effort single-use until server invites land.
  static const Duration inviteValidity = Duration(hours: 72);

  // MARK: Encode

  static String inviteCode(KhatmaCircle circle) {
    final clean = circle.copy()
      ..createdHere = null
      ..myMemberId = null;
    final envelope = {
      'circle': clean.toJson(),
      'expires': DateTime.now().add(inviteValidity).toIso8601String(),
    };
    return 'WRD1.${_base64Url(utf8.encode(jsonEncode(envelope)))}';
  }

  static String inviteMessage(KhatmaCircle circle) {
    final lines = circle.members.map((m) => '• ${m.name}: الأجزاء ${_rangesText(m.assigned)}').join('\n');
    final dedication = circle.dedication == null ? '' : '\nالنية: ${circle.dedication}';
    return '🕯 حلقة ختمة «${circle.name}»$dedication\n\n'
        '$lines\n\n'
        'للانضمام: افتح تطبيق وِرْد → الحلقات → «انضمّ برمز» وألصِق هذه الرسالة كاملة.\n'
        '(الدعوة صالحة ثلاثة أيام)\n'
        '${inviteCode(circle)}';
  }

  static String progressCode(KhatmaCircle circle, KhatmaMember member) {
    final update = ProgressUpdate(
      circleId: circle.id,
      memberId: member.id,
      memberName: member.name,
      completed: member.completed.toList()..sort(),
    );
    return 'WRDU.${_base64Url(utf8.encode(jsonEncode(update.toJson())))}';
  }

  static String progressMessage(KhatmaCircle circle, KhatmaMember member) {
    return '✅ ${member.name} — أتممتُ ${arabicNumber(member.completed.length)} من '
        '${arabicNumber(member.assigned.length)} من أجزائي في «${circle.name}»\n\n'
        'ألصِق هذه الرسالة في تطبيق وِرْد (الحلقات → انضمّ برمز) ليتحدّث تقدمي عندك.\n'
        '${progressCode(circle, member)}';
  }

  // MARK: Decode — accepts a whole pasted message and finds the code inside

  static Outcome read(String pasted) {
    final invitePayload = _extract('WRD1.', pasted);
    if (invitePayload != null) {
      final data = _base64UrlDecode(invitePayload);
      if (data != null) {
        try {
          final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
          if (json.containsKey('circle')) {
            final expires = parseFlexibleDate(json['expires']);
            if (expires != null && !expires.isAfter(DateTime.now())) return OutcomeExpired();
            final circle = KhatmaCircle.fromJson(json['circle'] as Map<String, dynamic>)
              ..createdHere = false
              ..myMemberId = null;
            return OutcomeDecoded(DecodedCircle(circle));
          }
          final circle = KhatmaCircle.fromJson(json)
            ..createdHere = false
            ..myMemberId = null;
          return OutcomeDecoded(DecodedCircle(circle));
        } catch (_) {
          // fall through to the progress code
        }
      }
    }
    final progressPayload = _extract('WRDU.', pasted);
    if (progressPayload != null) {
      final data = _base64UrlDecode(progressPayload);
      if (data != null) {
        try {
          final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
          return OutcomeDecoded(DecodedProgress(ProgressUpdate.fromJson(json)));
        } catch (_) {}
      }
    }
    return OutcomeNotFound();
  }

  // MARK: Helpers

  static final RegExp _payloadChars = RegExp(r'^[A-Za-z0-9\-_]+');

  static String? _extract(String prefix, String text) {
    final index = text.indexOf(prefix);
    if (index == -1) return null;
    final tail = text.substring(index + prefix.length);
    final match = _payloadChars.firstMatch(tail);
    return match?.group(0);
  }

  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static List<int>? _base64UrlDecode(String s) {
    var padded = s;
    while (padded.length % 4 != 0) {
      padded += '=';
    }
    try {
      return base64Url.decode(padded);
    } catch (_) {
      return null;
    }
  }

  static String _rangesText(List<int> numbers) {
    final sorted = [...numbers]..sort();
    if (sorted.isEmpty) return '';
    final first = sorted.first, last = sorted.last;
    if (sorted.length == last - first + 1 && sorted.length > 1) {
      return '${arabicNumber(first)}–${arabicNumber(last)}';
    }
    return sorted.map(arabicNumber).join('، ');
  }
}
