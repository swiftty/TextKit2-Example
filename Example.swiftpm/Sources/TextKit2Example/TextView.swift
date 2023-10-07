import UIKit

open class TextView: UIView {
    public var text: String {
        get { contentView.text }
        set { contentView.text = newValue }
    }
    public var attributedText: NSAttributedString? {
        get { contentView.attributedText }
        set { contentView.attributedText = newValue }
    }

    private let contentView = ContentView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.alwaysBounceVertical = true
        contentView.transform = .init(rotationAngle: .pi / 2)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
    }
}

private final class ContentView: UIScrollView {
    var text: String {
        get { textContentStorage.attributedString?.string ?? "" }
        set { setText(newValue) }
    }
    var attributedText: NSAttributedString? {
        get { textContentStorage.attributedString }
        set { setText(newValue) }
    }

    private let textLayoutManager = NSTextLayoutManager()
    private let textContentStorage = NSTextContentStorage()

    private let layers = NSMapTable<NSTextLayoutFragment, TextLayoutFragmentLayer>.weakToWeakObjects()
    private let contentLayer = TextLayer()

    private var updatingLayers: Set<CALayer> = []
    private var updatingOffsets: Set<CGFloat> = []
    private var updating = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        textContentStorage.addTextLayoutManager(textLayoutManager)
        textLayoutManager.textContainer = NSTextContainer(size: .init(width: 200, height: 0))

        contentLayer.frame = bounds
        layer.addSublayer(contentLayer)

        textLayoutManager.textViewportLayoutController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !updating {
            textLayoutManager.textViewportLayoutController.layoutViewport()
            updateContainerSizeIfNeeded()
        }
        contentLayer.frame = CGRect(origin: .zero, size: contentSize)
    }
}

extension ContentView {
    private func setText(_ string: String?) {
        setText(string.map(NSAttributedString.init(string:)))
    }

    private func setText(_ string: NSAttributedString?) {
        let string = string.map(NSMutableAttributedString.init(attributedString:))
        if let string {
            string.addAttribute(.verticalGlyphForm, value: true, range: NSRange(location: 0, length: string.length))
        }
        textContentStorage.performEditingTransaction {
            textContentStorage.attributedString = string
        }
        layer.setNeedsLayout()
    }

    private func updateContainerSizeIfNeeded() {
        guard let container = textLayoutManager.textContainer else { return }
        if container.size.width != bounds.width {
            container.size = CGSize(width: bounds.width, height: 0)
            layer.setNeedsLayout()
        }
    }

    private func updateContentSizeIfNeeded() {
        let currentHeight = contentSize.height
        var height = 0 as CGFloat
        textLayoutManager.enumerateTextLayoutFragments(from: textLayoutManager.documentRange.endLocation,
                                                       options: [.reverse, .ensuresLayout]) { fragment in
            height = fragment.layoutFragmentFrame.maxY
            return false
        }

        let maxHeight = updatingLayers.map(\.frame.maxY).max() ?? 0
        if abs(currentHeight - height) > 1e-10, height > maxHeight {
            contentSize = CGSize(width: bounds.width, height: height)
        } else if maxHeight > contentSize.height {
            contentSize = CGSize(width: bounds.width, height: maxHeight)
        }
    }

    private func adjustViewportOffsetIfNeeded() {
        guard !updatingOffsets.isEmpty else { return }
        let diff = updatingOffsets.reduce(0, +) / CGFloat(updatingOffsets.count)
        contentOffset.y -= diff
    }
}

extension ContentView: NSTextViewportLayoutControllerDelegate {
    func viewportBounds(for textViewportLayoutController: NSTextViewportLayoutController) -> CGRect {
        CGRect(origin: contentOffset, size: bounds.size)
            .insetBy(dx: 0, dy: -100)
    }

    func textViewportLayoutControllerWillLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        updating = true
        updatingLayers = []
        updatingOffsets = []
    }

    func textViewportLayoutController(_ textViewportLayoutController: NSTextViewportLayoutController,
                                      configureRenderingSurfaceFor textLayoutFragment: NSTextLayoutFragment) {
        func findLayer() -> (TextLayoutFragmentLayer, Bool) {
            if let layer = layers.object(forKey: textLayoutFragment) {
                return (layer, true)
            } else {
                let layer = TextLayoutFragmentLayer(layoutFragment: textLayoutFragment, contentsScale: window?.screen.scale ?? 2)
                layers.setObject(layer, forKey: textLayoutFragment)
                return (layer, false)
            }
        }

        let (layer, found) = findLayer()
        if found {
            let oldPosition = layer.position
            let oldBounds = layer.bounds
            layer.updateGeometry()
            if oldBounds != layer.bounds {
                layer.setNeedsDisplay()
            }
            if oldPosition != layer.position {
                updatingOffsets.insert(oldPosition.y - layer.position.y)
            }
        }

        updatingLayers.insert(layer)
        contentLayer.addSublayer(layer)
    }

    func textViewportLayoutControllerDidLayout(_ textViewportLayoutController: NSTextViewportLayoutController) {
        defer { updating = false }
        for layer in contentLayer.sublayers ?? [] where !updatingLayers.contains(layer) {
            layer.removeFromSuperlayer()
        }
        updateContentSizeIfNeeded()
        adjustViewportOffsetIfNeeded()
    }
}

