import SwiftUI

func loadRichText() -> NSAttributedString {
    let text = NSMutableAttributedString(string: """
    　あのイーハトーヴォのすきとおった風、夏でも底に冷たさをもつ青いそら、うつくしい森で飾られたモリーオ市、郊外のぎらぎらひかる草の波。
    　またそのなかでいっしょになったたくさんのひとたち、ファゼーロとロザーロ、羊飼のミーロや、顔の赤いこどもたち、地主のテーモ、山猫博士のボーガント・デストゥパーゴなど、いまこの暗い巨きな石の建物のなかで考えていると、みんなむかし風のなつかしい青い幻燈のように思われます。では、わたくしはいつかの小さなみだしをつけながら、しずかにあの年のイーハトーヴォの五月から十月までを書きつけましょう。
    """)
    text.addAttribute(.font, value: UIFont(name: "HiraMinProN-W3", size: 24)!, range: NSRange(location: 0, length: text.length))
    return text
}

@main
struct MyApp: App {
    @State var value: NSAttributedString?

    var body: some Scene {
        WindowGroup  {
            ZStack {
                TabView {
                    UITextViewPage(text: value ?? .init(string: ""))
                        .tabItem {
                            Label("original", systemImage: "a.square")
                        }

                    TextViewPage(text: value ?? .init(string: ""))
                        .tabItem {
                            Label("custom", systemImage: "b.square")
                        }
                }

                Button {
                    value = loadRichText()
                } label: {
                    Text("set text")
                        .padding()
                        .border(.tint)
                }
                .opacity(value != nil ? 0 : 1)
            }
        }
    }
}

// MARK: -
struct UITextViewPage: UIViewRepresentable {
    let text: NSAttributedString

    func makeUIView(context: Context) -> UITextView {
        let view: UITextView
        if #available(iOS 16, *) {
            view = UITextView(usingTextLayoutManager: true)
        } else {
            view = UITextView()
        }
        view.attributedText = text
        view.isEditable = false
        view.isSelectable = false
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = text
    }
}

// MARK: -
struct TextViewPage: UIViewRepresentable {
    let text: NSAttributedString

    func makeUIView(context: Context) -> TextView {
        let view = TextView()
        view.attributedText = text
        return view
    }

    func updateUIView(_ uiView: TextView, context: Context) {
        uiView.attributedText = text
    }
}
