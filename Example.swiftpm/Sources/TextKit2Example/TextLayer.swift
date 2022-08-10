import Foundation
import UIKit

class TextLayer: CALayer {
    override class func defaultAction(forKey event: String) -> CAAction? {
        NSNull()
    }
}

// MARK: -
final class TextLayoutFragmentLayer: TextLayer {
    var layoutFragment: NSTextLayoutFragment

    init(layoutFragment: NSTextLayoutFragment, contentsScale: CGFloat) {
        self.layoutFragment = layoutFragment
        super.init()
        self.contentsScale = contentsScale
        updateGeometry()
        setNeedsDisplay()
    }

    override init(layer: Any) {
        let layer = layer as! TextLayoutFragmentLayer
        layoutFragment = layer.layoutFragment
        super.init(layer: layer)
        contentsScale = layer.contentsScale
        updateGeometry()
        setNeedsDisplay()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(in ctx: CGContext) {
        layoutFragment.draw(at: .zero, in: ctx)
    }

    func updateGeometry() {
        bounds = layoutFragment.renderingSurfaceBounds

        anchorPoint = CGPoint(x: -bounds.origin.x / bounds.width,
                              y: -bounds.origin.y / bounds.height)
        position = layoutFragment.layoutFragmentFrame.origin
        var newBounds = bounds
        newBounds.origin.x += position.x
        bounds = newBounds
    }
}
