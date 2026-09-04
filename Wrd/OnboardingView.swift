import SwiftUI

/// First light — one small welcome that makes the app personal:
/// your name, your city (for prayer times), and comfortable type for elders.
struct OnboardingView: View {
    @Environment(WrdStore.self) private var store
    @State private var name = ""
    @State private var selectedCity = City.default
    @State private var isElder = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 20)

            Text("۞")
                .font(.system(size: 52))
                .foregroundStyle(WrdColor.gold)
            VStack(spacing: 6) {
                Text("وِرْد")
                    .font(.system(size: 44, weight: .bold))
                Text("وِردُكَ نُورُك")
                    .font(.title3)
                    .foregroundStyle(WrdColor.gold)
            }

            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("اسمك الكريم")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WrdColor.goldDeep)
                    WrdField(placeholder: "مثال: يحيى", text: $name)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(WrdColor.wash))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("مدينتك — لمواقيت الصلاة")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WrdColor.goldDeep)
                    Picker("المدينة", selection: $selectedCity) {
                        ForEach(City.all) { city in
                            Text(city.arabicName).tag(city)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(WrdColor.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(WrdColor.wash))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("العمر")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(WrdColor.goldDeep)
                    Picker("العمر", selection: $isElder) {
                        Text("دون الخمسين").tag(false)
                        Text("خمسون فما فوق").tag(true)
                    }
                    .pickerStyle(.segmented)
                    Text("لمن بلغ الخمسين نُكبّر الخط تلقائيًا — راحةً للعين")
                        .font(.caption)
                        .foregroundStyle(WrdColor.muted)
                }
            }
            .padding(.horizontal, 28)

            Spacer(minLength: 10)

            Button {
                store.userName = name.trimmingCharacters(in: .whitespaces)
                store.city = selectedCity
                store.largeText = isElder
                store.hasOnboarded = true
                Haptics.success()
            } label: {
                Text("ابدأ رحلة النور")
                    .font(.headline)
                    .foregroundStyle(WrdColor.ground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(WrdColor.gold))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)

            Text("هذا التطبيق مجانيٌّ تمامًا — وتكفينا دعوةٌ صادقةٌ من قلبك 🤍")
                .font(.caption)
                .foregroundStyle(WrdColor.faint)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WrdColor.ground.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .dynamicTypeSize(isElder ? .xxxLarge : .large)
    }
}

#Preview {
    OnboardingView()
        .environment(WrdStore())
}
