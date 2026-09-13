import SwiftUI
import WebKit
import WatchConnectivity

@main
struct StudioTriApp: App {
    @StateObject private var link = WatchLink()

    var body: some Scene {
        WindowGroup { TriWebView(link: link).ignoresSafeArea(edges: .bottom) }
    }
}

final class WatchLink: NSObject, ObservableObject, WCSessionDelegate {
    var deliver: ((String, [String: Any]) -> Void)?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func command(_ action: String) {
        guard ["start", "stop"].contains(action) else { return }
        guard WCSession.isSupported(), WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else {
            deliver?("studioTriWatchState", ["message": "Watch-App installieren und Watch koppeln."])
            return
        }
        guard WCSession.default.isReachable else {
            deliver?("studioTriWatchState", ["message": "Watch-App öffnen; dann dort Start tippen."])
            return
        }
        WCSession.default.sendMessage(["action": action], replyHandler: nil) { [weak self] _ in
            DispatchQueue.main.async { self?.deliver?("studioTriWatchState", ["message": "Watch-App öffnen und dort starten."]) }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let bpm = message["bpm"] as? Int,
              let timestamp = message["timestamp"] as? Double,
              (35...230).contains(bpm) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.deliver?("studioTriHeartRate", ["bpm": bpm, "timestamp": timestamp])
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            let ready = session.isWatchAppInstalled
            self?.deliver?("studioTriWatchState", ["message": ready ? "Watch-App starten; Puls erscheint automatisch." : "Watch-App auf der Apple Watch installieren."])
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}

struct TriWebView: UIViewRepresentable {
    @ObservedObject var link: WatchLink
    private let origin = URL(string: "https://indoor-triathlon-wolfgang.vercel.app/")!

    func makeCoordinator() -> Coordinator { Coordinator(link: link, origin: origin) }
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.userContentController.add(context.coordinator, name: "studioTri")
        let view = WKWebView(frame: .zero, configuration: config)
        context.coordinator.webView = view
        view.navigationDelegate = context.coordinator
        view.load(URLRequest(url: origin))
        link.deliver = { [weak view] name, detail in
            guard let view else { return }
            Coordinator.dispatch(name, detail: detail, to: view)
        }
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        weak var webView: WKWebView?
        let link: WatchLink
        let origin: URL
        init(link: WatchLink, origin: URL) { self.link = link; self.origin = origin }

        static func dispatch(_ name: String, detail: [String: Any], to webView: WKWebView) {
            guard JSONSerialization.isValidJSONObject(["name": name, "detail": detail]),
                  let data = try? JSONSerialization.data(withJSONObject: ["name": name, "detail": detail]),
                  let json = String(data: data, encoding: .utf8) else { return }
            webView.evaluateJavaScript("window.dispatchEvent(new CustomEvent((\(json)).name,{detail:(\(json)).detail}));", completionHandler: nil)
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Self.dispatch("studioTriNativeReady", detail: [:], to: webView)
        }
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard webView?.url?.host == origin.host,
                  let body = message.body as? [String: String],
                  let action = body["action"] else { return }
            link.command(action)
        }
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = action.request.url else { decisionHandler(.cancel); return }
            if url.scheme == "https", url.host == origin.host { decisionHandler(.allow) }
            else {
                if action.navigationType == .linkActivated { UIApplication.shared.open(url) }
                decisionHandler(.cancel)
            }
        }
    }
}
