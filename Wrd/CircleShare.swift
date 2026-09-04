import Foundation

/// Offline circle sync — sharing by code, WhatsApp-friendly, no server, no accounts.
/// Invite: "WRD1.<base64>" carries the whole circle. Progress: "WRDU.<base64>"
/// carries one member's completed ajzā'. Paste either into WRD and it merges.
enum CircleCodec {

    struct ProgressUpdate: Codable {
        var circleID: UUID
        var memberID: UUID
        var memberName: String
        var completed: [Int]
    }

    private struct InviteEnvelope: Codable {
        var circle: KhatmaCircle
        var expires: Date
    }

    /// Invitations expire — best-effort single-use until server-side invites land.
    static let inviteValidity: TimeInterval = 72 * 3600

    // MARK: Encode

    static func inviteCode(for circle: KhatmaCircle) -> String? {
        var clean = circle
        clean.createdHere = nil
        clean.myMemberID = nil
        let envelope = InviteEnvelope(circle: clean, expires: Date().addingTimeInterval(inviteValidity))
        guard let data = try? JSONEncoder().encode(envelope) else { return nil }
        return "WRD1." + base64URL(data)
    }

    static func inviteMessage(for circle: KhatmaCircle) -> String {
        let lines = circle.members.map { member in
            "• \(member.name): الأجزاء \(rangesText(member.assigned))"
        }
        let dedication = circle.dedication.map { "\nالنية: \($0)" } ?? ""
        let code = inviteCode(for: circle) ?? ""
        return """
        🕯 حلقة ختمة «\(circle.name)»\(dedication)

        \(lines.joined(separator: "\n"))

        للانضمام: افتح تطبيق وِرْد → الحلقات → «انضمّ برمز» وألصِق هذه الرسالة كاملة.
        (الدعوة صالحة ثلاثة أيام)
        \(code)
        """
    }

    static func progressCode(circle: KhatmaCircle, member: KhatmaMember) -> String? {
        let update = ProgressUpdate(circleID: circle.id,
                                    memberID: member.id,
                                    memberName: member.name,
                                    completed: Array(member.completed).sorted())
        guard let data = try? JSONEncoder().encode(update) else { return nil }
        return "WRDU." + base64URL(data)
    }

    static func progressMessage(circle: KhatmaCircle, member: KhatmaMember) -> String {
        let code = progressCode(circle: circle, member: member) ?? ""
        return """
        ✅ \(member.name) — أتممتُ \(arabicNumber(member.completed.count)) من \(arabicNumber(member.assigned.count)) من أجزائي في «\(circle.name)»

        ألصِق هذه الرسالة في تطبيق وِرْد (الحلقات → انضمّ برمز) ليتحدّث تقدمي عندك.
        \(code)
        """
    }

    // MARK: Decode — accepts a whole pasted message and finds the code inside

    enum Decoded {
        case circle(KhatmaCircle)
        case progress(ProgressUpdate)
    }

    enum Outcome {
        case decoded(Decoded)
        case expired
        case notFound
    }

    static func read(_ pasted: String) -> Outcome {
        if let payload = extract(prefix: "WRD1.", from: pasted),
           let data = base64URLDecode(payload) {
            if let envelope = try? JSONDecoder().decode(InviteEnvelope.self, from: data) {
                guard envelope.expires > Date() else { return .expired }
                var circle = envelope.circle
                circle.createdHere = false
                circle.myMemberID = nil
                return .decoded(.circle(circle))
            }
            if var circle = try? JSONDecoder().decode(KhatmaCircle.self, from: data) {
                circle.createdHere = false
                circle.myMemberID = nil
                return .decoded(.circle(circle))
            }
        }
        if let payload = extract(prefix: "WRDU.", from: pasted),
           let data = base64URLDecode(payload),
           let update = try? JSONDecoder().decode(ProgressUpdate.self, from: data) {
            return .decoded(.progress(update))
        }
        return .notFound
    }

    // MARK: Helpers

    private static func extract(prefix: String, from text: String) -> String? {
        guard let range = text.range(of: prefix) else { return nil }
        let tail = text[range.upperBound...]
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
        let payload = tail.prefix { char in
            char.unicodeScalars.allSatisfy { allowed.contains($0) }
        }
        return payload.isEmpty ? nil : String(payload)
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        return Data(base64Encoded: base64)
    }

    private static func rangesText(_ numbers: [Int]) -> String {
        let sorted = numbers.sorted()
        guard let first = sorted.first, let last = sorted.last else { return "" }
        if sorted.count == (last - first + 1) && sorted.count > 1 {
            return "\(arabicNumber(first))–\(arabicNumber(last))"
        }
        return sorted.map { arabicNumber($0) }.joined(separator: "، ")
    }
}
