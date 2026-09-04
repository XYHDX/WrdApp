import SwiftUI

/// الحلقات — khatma circles. The creator controls the split; invites travel as
/// WhatsApp-friendly codes; each member marks only their own ajzā' and shares a
/// small progress code back — so everyone sees the khatma move without asking.
struct CirclesView: View {
    @Environment(WrdStore.self) private var store
    @State private var showCreate = false
    @State private var showJoin = false

    var body: some View {
        NavigationStack {
            Group {
                if store.circles.isEmpty {
                    emptyState
                } else {
                    circlesList
                }
            }
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("الحلقات")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreate = true } label: {
                        Image(systemName: "plus").foregroundStyle(WrdColor.gold)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showJoin = true } label: {
                        Image(systemName: "square.and.arrow.down").foregroundStyle(WrdColor.goldDeep)
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                CircleDetailView(circleID: id)
            }
        }
        .sheet(isPresented: $showCreate) { CreateCircleView() }
        .sheet(isPresented: $showJoin) { JoinCircleView() }
    }

    private var circlesList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(store.circles) { circle in
                    NavigationLink(value: circle.id) {
                        circleRow(circle)
                    }
                    .buttonStyle(.plain)
                }
                Text("الدعوة والتحديث برموزٍ تُلصق في واتساب — والمزامنة التلقائية قادمة بإذن الله")
                    .font(.caption2)
                    .foregroundStyle(WrdColor.faint)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    private func circleRow(_ circle: KhatmaCircle) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(WrdColor.goldWash, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: circle.progress)
                    .stroke(WrdColor.gold, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                if circle.isComplete {
                    Image(systemName: "seal.fill")
                        .font(.caption)
                        .foregroundStyle(WrdColor.gold)
                }
            }
            .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(circle.name)
                        .font(.subheadline.weight(.medium))
                    if !circle.isCreator {
                        Text("منضم")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(WrdColor.goldDeep)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(WrdColor.goldWash))
                    }
                }
                if let dedication = circle.dedication, !dedication.isEmpty {
                    Text(dedication)
                        .font(.caption2)
                        .foregroundStyle(WrdColor.gold)
                }
                Text("\(arabicNumber(circle.completedCount)) من ٣٠ جزءًا · \(arabicNumber(circle.members.count)) أعضاء")
                    .font(.caption2)
                    .foregroundStyle(WrdColor.muted)
            }
            Spacer()
            Image(systemName: "chevron.backward")
                .font(.caption)
                .foregroundStyle(WrdColor.faint)
        }
        .padding(14)
        .wrdWash(cornerRadius: 18)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("۞")
                .font(.system(size: 44))
                .foregroundStyle(WrdColor.gold)
            Text("حلقات الختمة")
                .font(.title3.weight(.semibold))
            Text("اقسموا ختمة القرآن بينكم — للأسرة، للأصدقاء،\nأو صدقةً عن روحٍ غالية — وتُذهَّب شمستُكم معًا")
                .font(.subheadline)
                .foregroundStyle(WrdColor.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
            HStack(spacing: 10) {
                Button {
                    showCreate = true
                } label: {
                    Text("أنشئ حلقة")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WrdColor.ground)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(WrdColor.gold))
                }
                .buttonStyle(.plain)
                Button {
                    showJoin = true
                } label: {
                    Text("انضمّ برمز")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WrdColor.gold)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(WrdColor.goldWash))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Join / paste a code

struct JoinCircleView: View {
    @Environment(WrdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var pasted = ""
    @State private var resultMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("ألصِق رسالة الدعوة أو رمز التقدم كما وصلتك — وِرْد يجد الرمز بنفسه.")
                    .font(.subheadline)
                    .foregroundStyle(WrdColor.muted)
                    .multilineTextAlignment(.center)
                ZStack(alignment: .topLeading) {
                    if pasted.isEmpty {
                        Text("ألصِق هنا…")
                            .foregroundStyle(WrdColor.faint)
                            .padding(18)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $pasted)
                        .multilineTextAlignment(.leading)
                        .frame(minHeight: 160)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                }
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(WrdColor.wash))
                Button {
                    switch CircleCodec.read(pasted) {
                    case .decoded(let decoded):
                        resultMessage = store.merge(decoded)
                        Haptics.success()
                    case .expired:
                        resultMessage = "انتهت صلاحية هذه الدعوة — اطلب من صاحب الحلقة دعوةً جديدة"
                    case .notFound:
                        resultMessage = "لم أجد رمزًا صالحًا في النص — تأكد من لصق الرسالة كاملة"
                    }
                } label: {
                    Text("استيراد")
                        .font(.headline)
                        .foregroundStyle(WrdColor.ground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(pasted.isEmpty ? WrdColor.goldDeep.opacity(0.4) : WrdColor.gold))
                }
                .buttonStyle(.plain)
                .disabled(pasted.isEmpty)
                Spacer()
            }
            .padding(20)
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("انضمّ برمز")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
            .alert(resultMessage ?? "", isPresented: Binding(get: { resultMessage != nil },
                                                             set: { if !$0 { resultMessage = nil; dismiss() } })) {
                Button("تمّ", role: .cancel) {}
            }
        }
        .tint(WrdColor.gold)
        .environment(\.layoutDirection, .rightToLeft)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Circle detail

struct CircleDetailView: View {
    @Environment(WrdStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let circleID: UUID
    @State private var showWhoAmI = false
    @State private var showInvite = false

    private var circle: KhatmaCircle? {
        store.circles.first { $0.id == circleID }
    }

    var body: some View {
        Group {
            if let circle {
                content(circle)
            } else {
                Color.clear
            }
        }
        .background(WrdColor.ground.ignoresSafeArea())
        .navigationTitle(circle?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let circle, circle.isCreator {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInvite = true
                    } label: {
                        Image(systemName: "qrcode")
                            .foregroundStyle(WrdColor.gold)
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button(role: .destructive) {
                        if let circle { store.removeCircle(circle) }
                        dismiss()
                    } label: {
                        Label("حذف الحلقة", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(WrdColor.muted)
                }
            }
        }
        .sheet(isPresented: $showInvite) {
            if let circle {
                InviteQRView(circle: circle)
            }
        }
        .confirmationDialog("من أنت في هذه الحلقة؟",
                            isPresented: $showWhoAmI, titleVisibility: .visible) {
            if let circle {
                ForEach(circle.members) { member in
                    Button(member.name) {
                        var updated = circle
                        updated.myMemberID = member.id
                        store.update(updated)
                        Haptics.medium()
                    }
                }
            }
        }
    }

    private func content(_ circle: KhatmaCircle) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                header(circle)
                if circle.isComplete { completeBanner }
                if !circle.isCreator && circle.myMemberID == nil {
                    whoAmIBanner
                }
                ForEach(circle.members) { member in
                    memberCard(circle: circle, member: member)
                }
                Text(circle.isCreator
                     ? "شارك الدعوة من الأعلى — وعندما يرسل الإخوة رموز تقدمهم ألصِقها من «انضمّ برمز»"
                     : "انقر أجزاءك أنت فقط — ثم شارك رمز تقدمك في المجموعة")
                    .font(.caption2)
                    .foregroundStyle(WrdColor.faint)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var whoAmIBanner: some View {
        Button {
            showWhoAmI = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .foregroundStyle(WrdColor.gold)
                Text("حدّد اسمك لتتمكن من تعليم أجزائك")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(WrdColor.gold)
                Spacer()
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(WrdColor.goldWash))
        }
        .buttonStyle(.plain)
    }

    private func header(_ circle: KhatmaCircle) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().stroke(WrdColor.goldWash, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: circle.progress)
                    .stroke(WrdColor.gold, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(arabicNumber(circle.completedCount))
                        .font(.title.weight(.semibold))
                        .foregroundStyle(WrdColor.gold)
                    Text("من ٣٠")
                        .font(.caption2)
                        .foregroundStyle(WrdColor.muted)
                }
            }
            .frame(width: 110, height: 110)
            .shadow(color: circle.isComplete ? WrdColor.gold.opacity(0.5) : Color.clear, radius: 20)
            if let dedication = circle.dedication, !dedication.isEmpty {
                Text(dedication)
                    .font(.subheadline)
                    .foregroundStyle(WrdColor.gold)
            }
        }
        .padding(.top, 8)
    }

    private var completeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "seal.fill")
                .foregroundStyle(WrdColor.gold)
            Text("اكتملت الختمة — تقبّل الله منكم")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WrdColor.gold)
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(WrdColor.goldWash))
    }

    private func memberCard(circle: KhatmaCircle, member: KhatmaMember) -> some View {
        let editable = circle.canEdit(member)
        let isMe = member.id == circle.myMemberID
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(member.name)
                    .font(.subheadline.weight(.medium))
                if isMe {
                    Text("أنت")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(WrdColor.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(WrdColor.goldWash))
                }
                Spacer()
                Text("\(arabicNumber(member.completed.count)) من \(arabicNumber(member.assigned.count))")
                    .font(.caption2)
                    .foregroundStyle(WrdColor.muted)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                ForEach(member.assigned, id: \.self) { juz in
                    juzChip(circle: circle, member: member, juz: juz, editable: editable)
                }
            }
            if isMe && !member.completed.isEmpty {
                ShareLink(item: CircleCodec.progressMessage(circle: circle, member: member)) {
                    Label("شارك تقدمي في المجموعة", systemImage: "paperplane")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WrdColor.gold)
                }
            }
        }
        .padding(14)
        .wrdWash(cornerRadius: 18)
        .opacity(editable ? 1 : 0.75)
    }

    private func juzChip(circle: KhatmaCircle, member: KhatmaMember, juz: Int, editable: Bool) -> some View {
        let done = member.completed.contains(juz)
        return Text(arabicNumber(juz))
            .font(.subheadline.weight(.medium))
            .foregroundStyle(done ? WrdColor.ground : WrdColor.muted)
            .frame(width: 44, height: 36)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(done ? WrdColor.gold : WrdColor.washStrong))
            .contentShape(Rectangle())
            .onTapGesture {
                guard editable else { Haptics.light(); return }
                var updated = circle
                if let index = updated.members.firstIndex(where: { $0.id == member.id }) {
                    if done {
                        updated.members[index].completed.remove(juz)
                    } else {
                        updated.members[index].completed.insert(juz)
                        Haptics.success()
                    }
                    store.update(updated)
                }
            }
    }
}

// MARK: - Invitation as a QR code

struct InviteQRView: View {
    @Environment(\.dismiss) private var dismiss
    let circle: KhatmaCircle

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Text("دعوة «\(circle.name)»")
                        .font(.title3.weight(.semibold))

                    #if canImport(UIKit)
                    if let code = CircleCodec.inviteCode(for: circle),
                       let qr = QRCode.image(from: code) {
                        Image(uiImage: qr)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 240, height: 240)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
                            .shadow(color: Color.black.opacity(0.12), radius: 14, y: 6)

                        VStack(spacing: 4) {
                            Text("يمسحه الضيف بكاميرا الآيفون العادية → «نسخ»")
                                .font(.footnote)
                                .foregroundStyle(WrdColor.muted)
                            Text("ثم في وِرْد: الحلقات → «انضمّ برمز» → لصق")
                                .font(.footnote)
                                .foregroundStyle(WrdColor.muted)
                        }
                        .multilineTextAlignment(.center)

                        ShareLink(item: Image(uiImage: qr),
                                  preview: SharePreview("دعوة \(circle.name)", image: Image(uiImage: qr))) {
                            Label("أرسل الرمز صورةً", systemImage: "qrcode")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(WrdColor.ground)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Capsule().fill(WrdColor.gold))
                        }
                    }
                    #endif

                    ShareLink(item: CircleCodec.inviteMessage(for: circle)) {
                        Label("أو أرسل الدعوة نصًا", systemImage: "text.bubble")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(WrdColor.gold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Capsule().fill(WrdColor.goldWash))
                    }

                    Text("الدعوة صالحة ثلاثة أيام، ولا يمكن إضافتها مرتين على الجهاز نفسه. الدعوة التي تُستهلك مرةً واحدة فقط للجميع قادمة مع المزامنة بإذن الله.")
                        .font(.caption)
                        .foregroundStyle(WrdColor.faint)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("الدعوة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إغلاق") { dismiss() }
                }
            }
        }
        .tint(WrdColor.gold)
        .environment(\.layoutDirection, .rightToLeft)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Create circle — the creator controls the split

struct CreateCircleView: View {
    @Environment(WrdStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dedication = ""
    @State private var memberNames: [String] = ["", ""]
    @State private var memberCounts: [Int] = [15, 15]

    private var validPairs: [(String, Int)] {
        zip(memberNames, memberCounts)
            .map { ($0.trimmingCharacters(in: .whitespaces), $1) }
            .filter { !$0.0.isEmpty }
    }
    private var total: Int { validPairs.reduce(0) { $0 + $1.1 } }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !validPairs.isEmpty && total == 30
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("الحلقة") {
                    WrdField(placeholder: "اسم الحلقة — مثال: ختمة العائلة", text: $name)
                    WrdField(placeholder: "النية أو الإهداء (اختياري)", text: $dedication)
                }
                .listRowBackground(WrdColor.groundHigh)

                Section("الأعضاء وقسمة الأجزاء") {
                    ForEach(memberNames.indices, id: \.self) { index in
                        HStack(spacing: 10) {
                            WrdField(placeholder: "اسم العضو", text: $memberNames[index])
                            Spacer()
                            Text(arabicNumber(memberCounts[index]))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(WrdColor.gold)
                                .frame(minWidth: 28)
                            Stepper("", value: $memberCounts[index], in: 0...30)
                                .labelsHidden()
                        }
                    }
                    Button {
                        memberNames.append("")
                        memberCounts.append(0)
                        rebalance()
                    } label: {
                        Label("أضِف عضوًا", systemImage: "plus")
                            .foregroundStyle(WrdColor.gold)
                    }
                    HStack {
                        Text("المجموع")
                        Spacer()
                        Text("\(arabicNumber(total)) من ٣٠")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(total == 30 ? WrdColor.gold : Color.red.opacity(0.8))
                        Button("قسّم بالتساوي") { rebalance() }
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WrdColor.goldDeep)
                            .buttonStyle(.plain)
                    }
                }
                .listRowBackground(WrdColor.groundHigh)

                Section {
                    Text("أنت من يقرر كم جزءًا لكل أخٍ وأخت — وتُسنَد الأجزاء بالترتيب (الأول من ١، والذي يليه يكمل…). يجب أن يكون المجموع ٣٠.")
                        .font(.caption)
                        .foregroundStyle(WrdColor.muted)
                }
                .listRowBackground(WrdColor.groundHigh)
            }
            .scrollContentBackground(.hidden)
            .background(WrdColor.ground.ignoresSafeArea())
            .navigationTitle("حلقة جديدة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("إنشاء") { create() }
                        .disabled(!canSave)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
            }
        }
        .tint(WrdColor.gold)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func rebalance() {
        let namedIndices = memberNames.indices.filter {
            !memberNames[$0].trimmingCharacters(in: .whitespaces).isEmpty
        }
        let targets = namedIndices.isEmpty ? Array(memberNames.indices) : namedIndices
        let counts = WrdStore.evenCounts(for: targets.count)
        for index in memberCounts.indices { memberCounts[index] = 0 }
        for (position, index) in targets.enumerated() { memberCounts[index] = counts[position] }
    }

    private func create() {
        let pairs = validPairs
        let members = WrdStore.allocateAjza(names: pairs.map(\.0), counts: pairs.map(\.1))
        guard !members.isEmpty else { return }
        let trimmedDedication = dedication.trimmingCharacters(in: .whitespacesAndNewlines)
        let circle = KhatmaCircle(
            name: name.trimmingCharacters(in: .whitespaces),
            dedication: trimmedDedication.isEmpty ? nil : trimmedDedication,
            members: members
        )
        store.add(circle)
        Haptics.success()
        dismiss()
    }
}

#Preview {
    CirclesView()
        .environment(WrdStore())
        .environment(\.layoutDirection, .rightToLeft)
}
