import SwiftUI

/// WRD وِرْد — the root. Arabic-first: the whole app runs right-to-left.
struct RootView: View {
    @State private var store = WrdStore()
    @Environment(\.scenePhase) private var scenePhase

    private var preferredScheme: ColorScheme? {
        switch store.theme {
        case .auto: return nil
        case .parchment: return .light
        case .candlelight: return .dark
        }
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("اليوم", systemImage: "sun.and.horizon") }
            MyAwradView()
                .tabItem { Label("أورادي", systemImage: "bookmark") }
            LibraryView()
                .tabItem { Label("المكتبة", systemImage: "books.vertical") }
            MishkatView()
                .tabItem { Label("المشكاة", systemImage: "moon.stars") }
            CirclesView()
                .tabItem { Label("الحلقات", systemImage: "person.3") }
        }
        .tint(WrdColor.gold)
        .environment(store)
        .environment(\.layoutDirection, .rightToLeft)
        .environment(\.locale, Locale(identifier: "ar"))
        .preferredColorScheme(preferredScheme)
        .dynamicTypeSize(store.largeText ? .xxxLarge : .large)
        .fullScreenCover(isPresented: Binding(get: { !store.hasOnboarded },
                                              set: { _ in })) {
            OnboardingView()
                .environment(store)
        }
        .task {
            NotificationManager.reschedule(store: store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.refreshDayIfNeeded()
                NotificationManager.reschedule(store: store)
            }
        }
    }
}

#Preview {
    RootView()
}
