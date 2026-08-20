import SwiftUI
import Foundation
import UIKit
import LocalAuthentication
import TigerCore

private enum TiktigerTheme {
    static let cyan = Color(red: 0.08, green: 0.82, blue: 0.96)
    static let blue = Color(red: 0.05, green: 0.24, blue: 0.55)
    static let navy = Color(red: 0.02, green: 0.04, blue: 0.12)
    static let red = Color(red: 0.96, green: 0.08, blue: 0.20)
    static let card = Color.white.opacity(0.09)
}

private struct FeatureSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let features: [FeatureDefinition]
}

private struct FeatureDefinition: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let defaultValue: Bool
}

private let tiktigerSections: [FeatureSection] = [
    FeatureSection(id: "profile", title: "Profile", subtitle: "تحكم في تجربة الملف الشخصي", icon: "person.crop.circle", features: [
        FeatureDefinition(id: "privateProfile", title: "Visit Profiles Privately", detail: "مسار خصوصية للزيارة ضمن البيئة المصرح بها", icon: "eye.slash", defaultValue: true),
        FeatureDefinition(id: "profileStats", title: "Likes & Posts", detail: "تنسيق الإعجابات والمنشورات في بطاقة الملف", icon: "chart.bar.xaxis", defaultValue: false),
        FeatureDefinition(id: "followerFormat", title: "Exact Follower Count", detail: "عرض الرقم بتنسيق كامل", icon: "person.2", defaultValue: false),
        FeatureDefinition(id: "followConfirm", title: "Follow Confirmation", detail: "تأكيد قبل تنفيذ المتابعة", icon: "checkmark.shield", defaultValue: false)
    ]),
    FeatureSection(id: "stories", title: "Stories", subtitle: "التنزيل والتدرجات والمشاهدات", icon: "circle.hexagongrid.circle", features: [
        FeatureDefinition(id: "downloadStories", title: "Download Stories", detail: "تنزيل القصة عبر مزود الوسائط المصرح", icon: "arrow.down.circle", defaultValue: true),
        FeatureDefinition(id: "storyViews", title: "Story View Count", detail: "عرض عدد مشاهدات القصة", icon: "eye", defaultValue: false),
        FeatureDefinition(id: "anonymousStories", title: "Watch Anonymously", detail: "بوابة خصوصية لمسار مشاهدة القصة", icon: "eye.slash", defaultValue: false),
        FeatureDefinition(id: "storyGradient", title: "Gradient Styles", detail: "تخصيص إطار القصة", icon: "paintpalette", defaultValue: false)
    ]),
    FeatureSection(id: "chats", title: "Chats", subtitle: "الرسائل والقفل والتحويل الصوتي", icon: "bubble.left.and.bubble.right", features: [
        FeatureDefinition(id: "readChats", title: "Read Chats Anonymously", detail: "تحكم في مسارات علامات القراءة", icon: "envelope.open", defaultValue: false),
        FeatureDefinition(id: "ghostTyping", title: "Ghost Typing", detail: "التحكم في حالة الكتابة", icon: "ellipsis.bubble", defaultValue: false),
        FeatureDefinition(id: "videoVoice", title: "Video to Voice Message", detail: "تحويل فيديو قصير إلى M4A", icon: "waveform", defaultValue: false),
        FeatureDefinition(id: "undoMessages", title: "Undo Deleted Messages", detail: "حفظ مؤقت قبل الحذف", icon: "arrow.uturn.backward", defaultValue: false),
        FeatureDefinition(id: "keepDeleted", title: "Keep Deleted Messages", detail: "تخزين محلي محمي للمحتوى", icon: "archivebox", defaultValue: false),
        FeatureDefinition(id: "lockChats", title: "Lock Chats", detail: "حماية المحادثات بالمصادقة المحلية", icon: "lock", defaultValue: false)
    ]),
    FeatureSection(id: "downloads", title: "Downloads", subtitle: "مركز تنزيل الوسائط والحفظ", icon: "arrow.down.to.line.compact", features: [
        FeatureDefinition(id: "downloadMedia", title: "Download Media", detail: "فيديو وصور بجودة المصدر المتاحة", icon: "square.and.arrow.down", defaultValue: true),
        FeatureDefinition(id: "downloadAvatar", title: "Download Avatar", detail: "تنزيل الصورة الرمزية بالضغط المطول", icon: "person.crop.circle.badge.arrow.down", defaultValue: false),
        FeatureDefinition(id: "downloadComments", title: "Comment Images", detail: "تنزيل صور التعليقات", icon: "photo", defaultValue: false),
        FeatureDefinition(id: "downloadStickers", title: "Comment Stickers", detail: "حفظ أو نسخ الملصقات", icon: "face.smiling", defaultValue: false)
    ]),
    FeatureSection(id: "videos", title: "Videos", subtitle: "المشغل والتفاعل والتنسيق", icon: "play.rectangle", features: [
        FeatureDefinition(id: "progressBar", title: "Keep Progress Bar Visible", detail: "إبقاء شريط التقدم ظاهرًا", icon: "slider.horizontal.3", defaultValue: false),
        FeatureDefinition(id: "likeConfirm", title: "Like Confirmation", detail: "تأكيد قبل الإعجاب", icon: "hand.thumbsup", defaultValue: true),
        FeatureDefinition(id: "showUsername", title: "Show Username", detail: "عرض اسم المستخدم بدل الاسم", icon: "at", defaultValue: false),
        FeatureDefinition(id: "showFlag", title: "Show Country Flag", detail: "عرض علم الدولة عند توفر الرمز", icon: "flag", defaultValue: false)
    ]),
    FeatureSection(id: "privacy", title: "Privacy", subtitle: "قفل ومحتوى وسجل محلي", icon: "lock.shield", features: [
        FeatureDefinition(id: "lockFavorites", title: "Lock Favorites", detail: "حماية المفضلة بالمصادقة", icon: "heart", defaultValue: false),
        FeatureDefinition(id: "hideAds", title: "Hide Ads", detail: "إخفاء المسارات الإعلانية المعترضة", icon: "nosign", defaultValue: false),
        FeatureDefinition(id: "clearHistory", title: "Auto Clear History", detail: "مسح السجل عند بدء التطبيق وفق الإعداد", icon: "trash", defaultValue: false),
        FeatureDefinition(id: "multiAccount", title: "Multi-account Capacity", detail: "رفع السقف ضمن سياسة التطبيق المصرح", icon: "person.3", defaultValue: false)
    ]),
    FeatureSection(id: "appearance", title: "Appearance", subtitle: "الألوان وLiquid Glass وOLED", icon: "paintbrush.pointed", features: [
        FeatureDefinition(id: "liquidControls", title: "Liquid Glass Controls", detail: "أزرار وقوائم بلمسة زجاجية", icon: "square.on.square", defaultValue: false),
        FeatureDefinition(id: "liquidNotices", title: "Liquid Glass Notices", detail: "تنبيهات وToast محسّنة", icon: "bell", defaultValue: false),
        FeatureDefinition(id: "liquidOverlays", title: "Liquid Glass Overlays", detail: "نوافذ وحوارات محسّنة", icon: "rectangle.on.rectangle", defaultValue: false),
        FeatureDefinition(id: "oledKeyboard", title: "OLED Keyboard", detail: "لون لوحة المفاتيح المخصص", icon: "keyboard", defaultValue: false)
    ]),
    FeatureSection(id: "translation", title: "Translation", subtitle: "لغة واجهة Tiktiger", icon: "character.bubble", features: [
        FeatureDefinition(id: "english", title: "English", detail: "واجهة إنجليزية", icon: "globe", defaultValue: true),
        FeatureDefinition(id: "arabic", title: "العربية", detail: "واجهة عربية مع دعم RTL", icon: "textformat.abc", defaultValue: false),
        FeatureDefinition(id: "spanish", title: "Español", detail: "واجهة إسبانية", icon: "globe.americas", defaultValue: false),
        FeatureDefinition(id: "vietnamese", title: "Tiếng Việt", detail: "واجهة فيتنامية", icon: "globe.asia.australia", defaultValue: false)
    ]),
    FeatureSection(id: "misc", title: "Miscellaneous", subtitle: "أدوات إضافية ومسارات سريعة", icon: "wrench.and.screwdriver", features: [
        FeatureDefinition(id: "copyText", title: "Copy Any Text", detail: "نسخ النص بالضغط المطول", icon: "doc.on.doc", defaultValue: false),
        FeatureDefinition(id: "openLinks", title: "Open Comment Links", detail: "فتح الروابط المصرح بها", icon: "link", defaultValue: false),
        FeatureDefinition(id: "fastLogout", title: "Fast Logout", detail: "خروج سريع مع تأكيد واضح", icon: "rectangle.portrait.and.arrow.right", defaultValue: false)
    ])
]

struct ContentView: View {
    @StateObject private var runtime = TiktigerRuntimeCoordinator.shared
    @StateObject private var settings = TiktigerSettingsStore.shared
    @StateObject private var appearance = TiktigerAppearanceService.shared
    @StateObject private var localization = TiktigerLocalizationService.shared
    @State private var showDownloadCenter = false
    @State private var showDiagnostics = false

    var body: some View {
        NavigationView {
            ZStack {
            LinearGradient(colors: [TiktigerTheme.navy, TiktigerTheme.blue.opacity(0.72), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    statusCard
                    runtimeCard
                    quickActions
                    sections
                    developerCard
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
        }
        }
        .background(
            TiktigerRuntimeViewHierarchyProbe(
                onRegistered: { view in runtime.markUIRegistered(from: view) },
                onPresented: { view in runtime.confirmPresented(from: view) }
            )
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
        )
        .onAppear {
            settings.refresh()
            appearance.refresh()
            localization.refresh()
            runtime.start()
        }
        .preferredColorScheme(appearance.mode.colorScheme)
        .environment(\.layoutDirection, localization.layoutDirection)
        .tint(TiktigerTheme.cyan)
        .sheet(isPresented: $showDownloadCenter) {
            DownloadCenterView()
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image("tiktiger_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: TiktigerTheme.cyan.opacity(0.45), radius: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text("app.title"))
                    .font(.system(size: 29, weight: .black, design: .rounded))
                Text(localization.text("app.subtitle"))
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.white.opacity(0.64))
            }

            Spacer()
            Image(systemName: "bolt.fill")
                .font(.title2.weight(.bold))
                .foregroundColor(TiktigerTheme.cyan)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(localization.text("status.core"), systemImage: "checkmark.shield.fill")
                    .font(.headline)
                Spacer()
                Text(localization.text("status.version"))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(TiktigerTheme.cyan.opacity(0.18))
                    .clipShape(Capsule())
            }

            Text(localization.text("app.release"))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.65))

            HStack(spacing: 10) {
                Circle()
                    .fill(settings.isEnabled ? Color.green : Color.orange)
                    .frame(width: 9, height: 9)
                Text(settings.isEnabled ? localization.text("status.ready") : localization.text("status.disabled"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                    Toggle("", isOn: Binding(
                        get: { settings.isEnabled },
                        set: { _ = settings.setEnabled($0) }
                    ))
                    .labelsHidden()
            }
        }
        .padding(18)
        .background(.ultraThinMaterial.opacity(0.72))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.14), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var runtimeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(localization.text("runtime.title"), systemImage: "bolt.horizontal.circle.fill")
                    .font(.headline)
                Spacer()
                Text(runtime.overallState)
                    .font(.caption.weight(.bold))
                    .foregroundColor(runtime.overallState == "VERIFIED" ? .green : .orange)
            }
            runtimeRow(localization.text("runtime.dylib_loaded"), runtime.dylibLoaded)
            runtimeRow(localization.text("runtime.initializer_executed"), runtime.initializerExecuted)
            runtimeRow(localization.text("runtime.core_started"), runtime.coreStarted)
            runtimeRow(localization.text("runtime.feature_registry"), runtime.featureRegistryReady)
            runtimeRow(localization.text("runtime.ui_registered"), runtime.uiRegistered)
            runtimeRow(localization.text("runtime.ui_presented"), runtime.uiPresented)
            if !runtime.lastError.isEmpty {
                Text(runtime.lastError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.24))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.12), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func runtimeRow(_ title: String, _ value: Bool) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.72))
            Spacer()
            Text(value ? "VERIFIED" : "FAILED")
                .font(.caption.weight(.bold))
                .foregroundColor(value ? .green : .red)
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(title: "Downloads", icon: "arrow.down.circle.fill", color: TiktigerTheme.cyan) {
                showDownloadCenter = true
            }
            QuickActionButton(title: "Diagnostics", icon: "waveform.path.ecg", color: .white) {
                showDiagnostics = true
            }
        }
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.text("features.title"))
                .font(.title3.weight(.bold))
                .padding(.top, 4)

            ForEach(tiktigerSections) { section in
                NavigationLink(destination: destination(for: section)) {
                    HStack(spacing: 14) {
                        Image(systemName: section.icon)
                            .font(.title3.weight(.bold))
                            .foregroundColor(TiktigerTheme.cyan)
                            .frame(width: 38, height: 38)
                            .background(TiktigerTheme.cyan.opacity(0.13))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(localization.text("section.\(section.id).title"))
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(localization.text("section.\(section.id).subtitle"))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.56))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(14)
                    .background(TiktigerTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08), lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func destination(for section: FeatureSection) -> some View {
        switch section.id {
        case "appearance":
            AppearanceSectionView()
        case "translation":
            TranslationSectionView()
        default:
            FeatureSectionView(section: section)
        }
    }

    private var developerCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 13) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [TiktigerTheme.cyan, TiktigerTheme.red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image("tiktiger_logo")
                        .resizable()
                        .scaledToFit()
                        .padding(7)
                        .clipShape(Circle())
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.35), lineWidth: 2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.text("developer.title"))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.55))
                    Text("@ucorc")
                        .font(.headline)
                }
                Spacer()
                Link(destination: URL(string: "https://t.me/ucorc")!) {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color(red: 0.10, green: 0.55, blue: 0.86))
                        .clipShape(Circle())
                }
            }
            Text(localization.text("developer.footer"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.52))
        }
        .padding(16)
        .background(TiktigerTheme.card)
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.08), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.top, 4)
        .padding(.bottom, 20)
    }
}

private struct TiktigerRuntimeViewHierarchyProbe: UIViewRepresentable {
    let onRegistered: (UIView) -> Void
    let onPresented: (UIView) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            guard view.window != nil, view.superview != nil else { return }
            onRegistered(view)
            guard !view.bounds.isEmpty else { return }
            onPresented(view)
        }
    }
}

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.subheadline.weight(.bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct AppearanceSectionView: View {
    @ObservedObject private var diagnostics = TiktigerDeviceDiagnostics.shared
    @ObservedObject private var appearance = TiktigerAppearanceService.shared
    @ObservedObject private var localization = TiktigerLocalizationService.shared
    @AppStorage("tiktiger.appearance.liquidControls") private var liquidControls = false
    @AppStorage("tiktiger.appearance.liquidNotices") private var liquidNotices = false
    @AppStorage("tiktiger.appearance.liquidOverlays") private var liquidOverlays = false
    @AppStorage("tiktiger.appearance.oledKeyboard") private var oledKeyboard = false
    @AppStorage("tiktiger.appearance.gradient") private var gradient = "Tiktiger Default"
    @AppStorage("tiktiger.color.red") private var red = 0.08
    @AppStorage("tiktiger.color.green") private var green = 0.82
    @AppStorage("tiktiger.color.blue") private var blue = 0.96

    private var accentColor: Binding<Color> {
        Binding(
            get: { Color(red: red, green: green, blue: blue) },
            set: { value in
                let uiColor = UIColor(value)
                var r: CGFloat = 0
                var g: CGFloat = 0
                var b: CGFloat = 0
                var a: CGFloat = 0
                if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
                    red = Double(r)
                    green = Double(g)
                    blue = Double(b)
                }
            }
        )
    }

    var body: some View {
        List {
            Section(localization.text("appearance.glass")) {
                Toggle(localization.text("appearance.liquid_controls"), isOn: $liquidControls)
                    .onChange(of: liquidControls) { value in auditAppearance("liquidControls", value: value) }
                Toggle(localization.text("appearance.liquid_notices"), isOn: $liquidNotices)
                    .onChange(of: liquidNotices) { value in auditAppearance("liquidNotices", value: value) }
                Toggle(localization.text("appearance.liquid_overlays"), isOn: $liquidOverlays)
                    .onChange(of: liquidOverlays) { value in auditAppearance("liquidOverlays", value: value) }
            }
            Section(localization.text("appearance.stories")) {
                Picker(localization.text("appearance.gradient"), selection: $gradient) {
                    Text(localization.text("appearance.default")).tag("Tiktiger Default")
                    Text(localization.text("appearance.green")).tag("Green Gradient")
                    Text(localization.text("appearance.blue")).tag("Blue Gradient")
                    Text(localization.text("appearance.pink")).tag("Pink Gradient")
                }
                .onChange(of: gradient) { value in
                    diagnostics.recordFeatureEvent(feature: "Appearance", event: "action_started", detail: "gradient=\(value)")
                    diagnostics.recordFeatureEvent(feature: "Appearance", event: "service_called", detail: "AppStorage")
                    diagnostics.recordFeatureEvent(feature: "Appearance", event: "result_success", detail: "Gradient saved")
                }
            }
            Section(localization.text("appearance.keyboard")) {
                Toggle(localization.text("appearance.oled_keyboard"), isOn: $oledKeyboard)
                    .onChange(of: oledKeyboard) { value in auditAppearance("oledKeyboard", value: value) }
                ColorPicker(localization.text("appearance.accent_color"), selection: accentColor, supportsOpacity: false)
                    .onChange(of: red) { _ in auditAppearance("accentColor", value: true) }
            }
            Section(localization.text("appearance.theme")) {
                Picker(localization.text("appearance.theme"), selection: Binding(
                    get: { appearance.mode },
                    set: { appearance.setMode($0) }
                )) {
                    Text(localization.text("appearance.system")).tag(TiktigerAppearanceService.Mode.system)
                    Text(localization.text("appearance.light")).tag(TiktigerAppearanceService.Mode.light)
                    Text(localization.text("appearance.dark")).tag(TiktigerAppearanceService.Mode.dark)
                }
            }
            Section {
                Button(localization.text("appearance.reset"), role: .destructive) {
                    appearance.setMode(.dark)
                    liquidControls = false
                    liquidNotices = false
                    liquidOverlays = false
                    oledKeyboard = false
                    gradient = "Tiktiger Default"
                    red = 0.08
                    green = 0.82
                    blue = 0.96
                }
            }
        }
        .navigationTitle(localization.text("appearance.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func auditAppearance(_ control: String, value: Bool) {
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "action_started", detail: "\(control)=\(value)")
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "service_called", detail: "AppStorage")
        diagnostics.recordFeatureEvent(feature: "Appearance", event: "result_success", detail: "Appearance setting saved")
    }
}

private struct TranslationSectionView: View {
    @ObservedObject private var diagnostics = TiktigerDeviceDiagnostics.shared
    @ObservedObject private var localization = TiktigerLocalizationService.shared
    private var language: String { localization.language }

    var body: some View {
        List {
            Section(localization.text("translation.language")) {
                Picker(localization.text("translation.interface_language"), selection: Binding(
                    get: { localization.language },
                    set: { localization.setLanguage($0) }
                )) {
                    Text(localization.text("translation.english")).tag("en")
                    Text(localization.text("translation.arabic")).tag("ar")
                    Text(localization.text("translation.spanish")).tag("es")
                    Text(localization.text("translation.vietnamese")).tag("vi")
                }
                .pickerStyle(.inline)
            }
            Section {
                Text(localization.text("translation.restart_note"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle(localization.text("translation.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FeatureSectionView: View {
    let section: FeatureSection

    var body: some View {
        ZStack {
            LinearGradient(colors: [TiktigerTheme.navy, TiktigerTheme.blue.opacity(0.55), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            List {
                Section {
                    ForEach(section.features) { feature in
                        TiktigerFeatureRow(feature: feature)
                            .listRowBackground(Color.white.opacity(0.08))
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: section.icon)
                            .font(.largeTitle)
                            .foregroundColor(TiktigerTheme.cyan)
                        Text(TiktigerLocalizationService.shared.text("section.\(section.id).subtitle"))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.66))
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .navigationTitle(TiktigerLocalizationService.shared.text("section.\(section.id).title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
private enum TiktigerLocalAuth {
    static func authenticate(feature: String, completion: @escaping (Bool) -> Void) {
        let diagnostics = TiktigerDeviceDiagnostics.shared
        diagnostics.recordFeatureEvent(feature: feature, event: "action_started", detail: "authentication requested")
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            let message = error?.localizedDescription ?? "Local authentication unavailable"
            diagnostics.recordFeatureEvent(feature: feature, event: "result_failed", detail: message)
            completion(false)
            return
        }
        diagnostics.recordFeatureEvent(feature: feature, event: "service_called", detail: "LocalAuthentication")
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: TiktigerLocalizationService.shared.text("auth.reason")) { success, evaluationError in
            let message = evaluationError?.localizedDescription ?? (success ? "Authentication accepted" : "Authentication rejected")
            let isCancellation: Bool
            if let evaluationError = evaluationError as NSError? {
                isCancellation = evaluationError.domain == LAError.errorDomain && (evaluationError.code == LAError.userCancel.rawValue || evaluationError.code == LAError.systemCancel.rawValue)
            } else {
                isCancellation = false
            }
            if isCancellation {
                diagnostics.recordFeatureEvent(feature: feature, event: "cancel", detail: message)
            }
            diagnostics.recordFeatureEvent(feature: feature, event: success ? "result_success" : "result_failed", detail: message)
            diagnostics.recordFeatureEvent(feature: feature, event: success ? "success" : "failure", detail: message)
            completion(success)
        }
    }
}

private struct TiktigerFeatureRow: View {
    let feature: FeatureDefinition
    @ObservedObject private var localization = TiktigerLocalizationService.shared
    @StateObject private var settings = TiktigerSettingsStore.shared
    @State private var enabled: Bool

    init(feature: FeatureDefinition) {
        self.feature = feature
        let stored = TigerManager.shared.featureEnabled(forKey: feature.id, defaultValue: feature.defaultValue)
        _enabled = State(initialValue: stored)
    }

    var body: some View {
        Toggle(isOn: Binding(get: { enabled }, set: { value in
            let protectedFeature = feature.id == "lockChats" || feature.id == "lockFavorites"
            let auditFeature = feature.id == "lockChats" ? "Chats Lock" : (feature.id == "lockFavorites" ? "Favorites Lock" : feature.title)
            guard value && protectedFeature else {
                if settings.setFeature(value, forKey: feature.id, diagnosticName: auditFeature) {
                    enabled = value
                }
                return
            }
            TiktigerLocalAuth.authenticate(feature: auditFeature) { success in
                DispatchQueue.main.async {
                    guard success else { return }
                    if settings.setFeature(true, forKey: feature.id, diagnosticName: auditFeature) {
                        enabled = true
                    }
                }
            }
        })) {
            HStack(spacing: 12) {
                Image(systemName: feature.icon)
                    .foregroundColor(TiktigerTheme.cyan)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                        Text(localization.text("feature.\(feature.id).title"))
                            .font(.subheadline.weight(.semibold))
                        Text(localization.text("feature.\(feature.id).detail"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .disabled(!settings.isEnabled)
        .onReceive(settings.$isEnabled) { _ in
            enabled = settings.effectiveFeatureEnabled(for: feature.id, defaultValue: feature.defaultValue)
        }
    }
}

private struct DownloadCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = TiktigerMediaDownloadService()
    @State private var urlText = ""
    @State private var mode = "media"
    @State private var showShare = false
    @State private var shareURL: URL?
    @State private var shareError = ""
    @ObservedObject private var localization = TiktigerLocalizationService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [TiktigerTheme.cyan.opacity(0.34), TiktigerTheme.red.opacity(0.28)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay(Circle().stroke(.white.opacity(0.26), lineWidth: 1))
                            .shadow(color: TiktigerTheme.cyan.opacity(0.30), radius: 16)
                        Image("download_arrow")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                    }
                    .frame(width: 96, height: 96)

                    Text(localization.text("download.title"))
                        .font(.title2.weight(.bold))

                    Text(localization.text("download.description"))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)

                    Picker(localization.text("download.output"), selection: $mode) {
                        Text(localization.text("download.media")).tag("media")
                        Text(localization.text("download.audio")).tag("audio")
                    }
                    .pickerStyle(.segmented)

                    TextField(localization.text("download.placeholder"), text: $urlText)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled(true)
                        .padding(14)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Button {
                        service.download(urlString: urlText, mode: mode)
                    } label: {
                            Label(service.isBusy ? localization.text("download.processing") : localization.text("download.start"), systemImage: "arrow.down.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(service.isBusy || urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if service.isBusy {
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(.circular)
                            Text(service.stage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button(localization.text("download.cancel")) {
                                service.cancel()
                            }
                            .buttonStyle(.bordered)
                        }
                    }

                    if let lastError = service.lastError {
                        Text(lastError)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color.red.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    if service.lastFileURL != nil {
                        Button {
                            guard let fileURL = service.lastFileURL else {
                                shareError = TiktigerShareService.ShareError.missingFile.localizedDescription
                                return
                            }
                            do {
                                shareURL = try TiktigerShareService.shared.validate(fileURL: fileURL)
                                shareError = ""
                                showShare = true
                            } catch {
                                shareError = error.localizedDescription
                            }
                        } label: {
                            Label(localization.text("download.share"), systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    if service.canRetry {
                        Button {
                            service.retryLast()
                        } label: {
                            Label(localization.text("download.retry"), systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    if !shareError.isEmpty {
                        Text(shareError)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !service.history.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(localization.text("download.history"))
                                    .font(.headline)
                                Spacer()
                                Button(localization.text("download.clear")) {
                                    service.clearHistory()
                                }
                                .font(.caption)
                            }
                            ForEach(service.history) { record in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.filename)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                    Text("\(record.mode == "audio" ? localization.text("download.audio") : localization.text("download.media")) · \(record.date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }

                    VStack(spacing: 10) {
                        DownloadStatusRow(title: localization.text("download.stage"), value: service.stage, color: service.stateColor)
                        DownloadStatusRow(title: localization.text("download.photo_library"), value: service.photoStatus, color: .secondary)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
            }
            .navigationTitle(localization.text("download.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.text("download.done")) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let fileURL = shareURL {
                TiktigerShareSheet(fileURLs: [fileURL])
            }
        }
    }
}

private struct TiktigerShareSheet: UIViewControllerRepresentable {
    let fileURLs: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: fileURLs, applicationActivities: nil)
        controller.completionWithItemsHandler = { activityType, completed, _, error in
            Task { @MainActor in
                TiktigerShareService.shared.recordCompletion(
                    activityType: activityType,
                    completed: completed,
                    error: error,
                    fileURLs: fileURLs
                )
            }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct DownloadStatusRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .font(.caption.weight(.semibold))
        }
    }
}

private struct TiktigerDiagnostic: Identifiable {
    let id: String
    let title: String
    let state: String
    let icon: String
    let color: Color
}

private struct TiktigerDiagnosticRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
            Spacer(minLength: 12)
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var runtime = TiktigerRuntimeCoordinator.shared
    @ObservedObject private var deviceDiagnostics = TiktigerDeviceDiagnostics.shared
    @ObservedObject private var localization = TiktigerLocalizationService.shared
    @State private var exportedReportURLs: [URL] = []
    @State private var showExportShare = false
    @State private var exportError = ""

    private let modules: [TiktigerDiagnostic] = [
        TiktigerDiagnostic(id: "settings", title: "module.settings", state: "IMPLEMENTED NOT TESTED", icon: "checkmark.circle.fill", color: .orange),
        TiktigerDiagnostic(id: "branding", title: "module.branding", state: "IMPLEMENTED NOT TESTED", icon: "checkmark.circle.fill", color: .orange),
        TiktigerDiagnostic(id: "downloads", title: "module.downloads", state: "IMPLEMENTED NOT TESTED", icon: "arrow.down.circle.fill", color: .orange),
        TiktigerDiagnostic(id: "history", title: "module.history", state: "IMPLEMENTED NOT TESTED", icon: "clock.arrow.circlepath", color: .orange),
        TiktigerDiagnostic(id: "photos", title: "module.photos", state: "DEVICE TEST REQUIRED", icon: "photo.fill", color: .orange),
        TiktigerDiagnostic(id: "provider", title: "module.provider", state: "PROVIDER REQUIRED", icon: "link.badge.plus", color: .red),
        TiktigerDiagnostic(id: "host", title: "module.host", state: "PARTIAL", icon: "app.badge", color: .orange),
        TiktigerDiagnostic(id: "hooks", title: "module.hooks", state: "NOT IMPLEMENTED", icon: "wrench.and.screwdriver", color: .red)
    ]

    var body: some View {
        NavigationView {
            List {
                Section(localization.text("diagnostics.tiktiger")) {
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.core"), value: TigerManager.shared.version)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.state"), value: TigerManager.shared.statusText())
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.environment"), value: localization.text("diagnostics.host_framework"))
                }
                Section(localization.text("diagnostics.runtime")) {
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.overall"), value: runtime.overallState)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.platform"), value: runtime.runtimePlatform)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.loaded_path"), value: runtime.dylibPath.isEmpty ? "NONE" : runtime.dylibPath)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.dylib_loaded"), value: runtime.dylibLoaded ? "VERIFIED" : "FAILED")
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.initializer"), value: runtime.initializerExecuted ? "VERIFIED" : "FAILED")
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.core_started"), value: runtime.coreStarted ? "VERIFIED" : "FAILED")
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.feature_registry"), value: runtime.featureRegistryReady ? "VERIFIED" : "FAILED")
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.registry_keys"), value: "\(runtime.registeredFeatureKeys.count)")
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.ui_registered"), value: runtime.uiRegistered ? "VERIFIED" : "FAILED")
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.ui_presented"), value: runtime.uiPresented ? "VERIFIED" : "FAILED")
                    if !runtime.lastError.isEmpty {
                        Text(runtime.lastError)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    Text(runtime.diagnosticsJSON)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                }
                Section(localization.text("diagnostics.load_attempts")) {
                    if runtime.loadAttempts.isEmpty {
                        Text(localization.text("diagnostics.no_dlopen"))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(runtime.loadAttempts.enumerated()), id: \.offset) { item in
                            Text(item.element)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
                Section(localization.text("diagnostics.resolved_symbols")) {
                    ForEach(runtime.symbolReports) { symbol in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(symbol.id)
                                    .font(.system(.caption, design: .monospaced))
                                Spacer()
                                Text(symbol.found ? "FOUND" : "FAILED")
                                    .foregroundColor(symbol.found ? .green : .red)
                                    .font(.caption.weight(.bold))
                            }
                            Text("\(symbol.timestamp) · \(symbol.detail)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section(localization.text("diagnostics.runtime_milestones")) {
                    ForEach(runtime.milestoneEvents) { event in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(event.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(event.state)
                                    .foregroundColor(event.state == "VERIFIED" ? .green : (event.state == "SKIPPED" ? .orange : .red))
                                    .font(.caption.weight(.bold))
                            }
                            Text("\(event.timestamp) · \(event.detail)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section(localization.text("diagnostics.runtime_verification")) {
                    ForEach(deviceDiagnostics.milestoneReports) { milestone in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(milestone.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(milestone.state)
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(milestone.state == "VERIFIED" ? .green : (milestone.state == "FAILED" ? .red : .orange))
                            }
                            Text("\(milestone.timestamp ?? "NOT REACHED") · \(milestone.detail ?? "NOT REACHED")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.dylib_path"), value: deviceDiagnostics.dylibPath.isEmpty ? "NONE" : deviceDiagnostics.dylibPath)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.dylib_sha"), value: deviceDiagnostics.dylibSHA256.isEmpty ? "NOT AVAILABLE" : deviceDiagnostics.dylibSHA256)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.dlopen"), value: deviceDiagnostics.dlopenResult)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.core_version"), value: deviceDiagnostics.coreVersion)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.app_ios"), value: "\(deviceDiagnostics.appVersion) / \(deviceDiagnostics.iOSVersion)")
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.device_model"), value: deviceDiagnostics.deviceModelIdentifier)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.last_dlerror"), value: deviceDiagnostics.lastDlError.isEmpty ? "NONE" : deviceDiagnostics.lastDlError)
                    TiktigerDiagnosticRow(title: localization.text("diagnostics.last_runtime_error"), value: deviceDiagnostics.lastRuntimeError.isEmpty ? "NONE" : deviceDiagnostics.lastRuntimeError)
                    Button {
                        do {
                            exportedReportURLs = try deviceDiagnostics.exportRuntimeReport()
                            exportError = ""
                            showExportShare = true
                        } catch {
                            exportError = error.localizedDescription
                        }
                    } label: {
                        Label(localization.text("diagnostics.export"), systemImage: "square.and.arrow.up")
                    }
                    if !exportError.isEmpty {
                        Text(exportError)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
                Section(localization.text("diagnostics.feature_audit")) {
                    ForEach(["Master Switch", "Appearance", "Translation", "Download", "Photos", "M4A", "Share", "Face ID", "Chats Lock", "Favorites Lock"], id: \.self) { feature in
                        TiktigerDiagnosticRow(title: feature, value: deviceDiagnostics.featureStatus(for: feature))
                    }
                    ForEach(Array(deviceDiagnostics.featureAuditEvents.suffix(80))) { event in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(event.feature) · \(event.event)")
                                .font(.caption.weight(.semibold))
                            Text("\(event.timestamp) · \(event.detail)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section(localization.text("diagnostics.modules")) {
                    ForEach(modules) { module in
                        HStack(spacing: 12) {
                            Image(systemName: module.icon)
                                .foregroundColor(module.color)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(localization.text(module.title))
                                    .font(.subheadline.weight(.semibold))
                                Text(module.state)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Text(localization.text("diagnostics.note"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(localization.text("diagnostics.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.text("diagnostics.done")) { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showExportShare) {
            TiktigerShareSheet(fileURLs: exportedReportURLs)
        }
    }
}
