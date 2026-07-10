import UIKit
import WebKit
import AVFoundation

// Affiche l'application web (index.html) dans une WKWebView et fournit le "pont"
// natif attendu par la page (objet AndroidBridge) : requêtes réseau, synthèse
// vocale, partage. Ainsi tout le code web est réutilisé tel quel, sans modification.
class WebViewController: UIViewController, WKScriptMessageHandler, AVSpeechSynthesizerDelegate {

    private var webView: WKWebView!
    private let synth = AVSpeechSynthesizer()

    override func viewDidLoad() {
        super.viewDidLoad()

        let controller = WKUserContentController()
        controller.add(self, name: "native")

        // Recrée l'objet AndroidBridge côté JS, branché sur le natif iOS.
        let bridge = """
        window.AndroidBridge = {
          fetchUrl: function(url, id){ window.webkit.messageHandlers.native.postMessage({t:'fetch', url:url, id:id}); },
          speak: function(t){ window.webkit.messageHandlers.native.postMessage({t:'speak', text:t}); },
          stopSpeak: function(){ window.webkit.messageHandlers.native.postMessage({t:'stop'}); },
          share: function(t){ window.webkit.messageHandlers.native.postMessage({t:'share', text:t}); },
          saveCache: function(d){ try { localStorage.setItem('tcd_cache', d); } catch(e) {} },
          loadCache: function(){ try { return localStorage.getItem('tcd_cache') || ''; } catch(e) { return ''; } }
        };
        """
        controller.addUserScript(WKUserScript(source: bridge, injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        synth.delegate = self

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(webView)

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }

    // Messages venus du JS
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let t = body["t"] as? String else { return }
        switch t {
        case "fetch":
            fetchUrl(body["url"] as? String ?? "", id: body["id"] as? Int ?? 0)
        case "speak":
            let u = AVSpeechUtterance(string: body["text"] as? String ?? "")
            u.voice = AVSpeechSynthesisVoice(language: "fr-FR")
            synth.stopSpeaking(at: .immediate)
            synth.speak(u)
        case "stop":
            synth.stopSpeaking(at: .immediate)
        case "share":
            let av = UIActivityViewController(activityItems: [body["text"] as? String ?? ""], applicationActivities: nil)
            av.popoverPresentationController?.sourceView = self.view
            present(av, animated: true)
        default:
            break
        }
    }

    private func fetchUrl(_ urlStr: String, id: Int) {
        guard let url = URL(string: urlStr) else { deliver(id, "") ; return }
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue("Mozilla/5.0 (iPhone)", forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: req) { data, resp, _ in
            var text = ""
            if let data = data {
                var enc = String.Encoding.utf8
                if let name = (resp as? HTTPURLResponse)?.textEncodingName {
                    let cf = CFStringConvertIANACharSetNameToEncoding(name as CFString)
                    if cf != kCFStringEncodingInvalidId {
                        enc = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cf))
                    }
                }
                text = String(data: data, encoding: enc) ?? String(data: data, encoding: .isoLatin1) ?? ""
            }
            self.deliver(id, text)
        }.resume()
    }

    private func deliver(_ id: Int, _ text: String) {
        let b64 = Data(text.utf8).base64EncodedString()
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("onFetchDone(\(id),'\(b64)')", completionHandler: nil)
        }
    }

    // Fin de lecture vocale -> l'app enchaîne (mode podcast)
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        webView.evaluateJavaScript("window.onSpeakDone && onSpeakDone()", completionHandler: nil)
    }
}
