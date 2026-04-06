import SpriteKit
import UIKit

// MARK: - UIColor from Neon Palette

extension UIColor {
    static func neonColor(at index: Int) -> UIColor {
        let palette = GameConstants.neonPalette
        let entry = palette[index % palette.count]
        return UIColor(red: entry.r, green: entry.g, blue: entry.b, alpha: 1.0)
    }

    static var neonCyan: UIColor    { neonColor(at: 0) }
    static var neonMagenta: UIColor { neonColor(at: 1) }
    static var neonYellow: UIColor  { neonColor(at: 2) }
    static var neonGreen: UIColor   { neonColor(at: 3) }

    static var glowBackground: UIColor {
        let c = GameConstants.backgroundDarkColor
        return UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1.0)
    }
}

// MARK: - Programmatic Neon Textures

extension SKTexture {

    /// Creates a neon-outlined rectangle texture with glow.
    static func neonRect(size: CGSize, color: UIColor, cornerRadius: CGFloat = 6, lineWidth: CGFloat = 2.5) -> SKTexture {
        let padding: CGFloat = 16
        let totalSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2)

        let renderer = UIGraphicsImageRenderer(size: totalSize)
        let image = renderer.image { ctx in
            let rect = CGRect(x: padding, y: padding, width: size.width, height: size.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

            // Outer glow
            ctx.cgContext.setShadow(offset: .zero, blur: 12, color: color.withAlphaComponent(0.8).cgColor)
            color.withAlphaComponent(0.3).setFill()
            path.fill()

            // Bright stroke
            ctx.cgContext.setShadow(offset: .zero, blur: 6, color: color.cgColor)
            color.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
        }
        return SKTexture(image: image)
    }

    /// Creates a neon bird texture with configurable wing position.
    /// `wingPhase` ranges from -1 (wings down) through 0 (neutral) to 1 (wings up).
    static func neonPlayer(size: CGSize, color: UIColor, wingPhase: CGFloat = 0) -> SKTexture {
        let padding: CGFloat = 12
        let totalSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2)

        let renderer = UIGraphicsImageRenderer(size: totalSize)
        let image = renderer.image { ctx in
            let cx = totalSize.width / 2
            let cy = totalSize.height / 2
            let w = size.width / 2
            let h = size.height / 2

            // Wing offset based on phase
            let wingOffset = wingPhase * h * 0.4

            // Bird body — a rounded chevron / arrow shape pointing right
            let body = UIBezierPath()
            body.move(to: CGPoint(x: cx + w, y: cy))                              // nose
            body.addLine(to: CGPoint(x: cx - w * 0.3, y: cy + h + wingOffset))    // bottom-back (wing)
            body.addLine(to: CGPoint(x: cx - w * 0.6, y: cy + h * 0.3))           // indent bottom
            body.addLine(to: CGPoint(x: cx - w, y: cy + h * 0.5))                 // tail bottom
            body.addLine(to: CGPoint(x: cx - w, y: cy - h * 0.5))                 // tail top
            body.addLine(to: CGPoint(x: cx - w * 0.6, y: cy - h * 0.3))           // indent top
            body.addLine(to: CGPoint(x: cx - w * 0.3, y: cy - h - wingOffset))    // top-back (wing)
            body.close()

            // Glow
            ctx.cgContext.setShadow(offset: .zero, blur: 10, color: color.cgColor)
            color.withAlphaComponent(0.5).setFill()
            body.fill()
            color.setStroke()
            body.lineWidth = 2.0
            body.stroke()

            // Eye
            let eyeRadius: CGFloat = 3.0
            let eyeCenter = CGPoint(x: cx + w * 0.2, y: cy - h * 0.15)
            let eye = UIBezierPath(arcCenter: eyeCenter, radius: eyeRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            UIColor.white.setFill()
            eye.fill()
        }
        return SKTexture(image: image)
    }

    /// Generates an array of flap animation frames for the player.
    static func neonPlayerFrames(size: CGSize, color: UIColor, shape: SkinManager.Skin.Shape = .chevron) -> [SKTexture] {
        let phases: [CGFloat] = [0.0, 1.0, 0.0, -1.0]
        return phases.map { neonPlayerSkin(size: size, color: color, shape: shape, wingPhase: $0) }
    }

    /// Generates a player texture for any skin shape.
    static func neonPlayerSkin(size: CGSize, color: UIColor, shape: SkinManager.Skin.Shape, wingPhase: CGFloat = 0) -> SKTexture {
        switch shape {
        case .chevron:
            return neonPlayer(size: size, color: color, wingPhase: wingPhase)
        case .orb:
            return neonOrbPlayer(size: size, color: color, wingPhase: wingPhase)
        case .diamond:
            return neonDiamondPlayer(size: size, color: color, wingPhase: wingPhase)
        case .bolt:
            return neonBoltPlayer(size: size, color: color, wingPhase: wingPhase)
        }
    }

    /// Orb-shaped player (circular with pulsing wing lines).
    static func neonOrbPlayer(size: CGSize, color: UIColor, wingPhase: CGFloat = 0) -> SKTexture {
        let padding: CGFloat = 12
        let totalSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2)
        let renderer = UIGraphicsImageRenderer(size: totalSize)
        let image = renderer.image { ctx in
            let cx = totalSize.width / 2
            let cy = totalSize.height / 2
            let r = min(size.width, size.height) / 2

            // Body circle
            let body = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            ctx.cgContext.setShadow(offset: .zero, blur: 10, color: color.cgColor)
            color.withAlphaComponent(0.4).setFill()
            body.fill()
            color.setStroke()
            body.lineWidth = 2.0
            body.stroke()

            // Wing arcs
            let wingOffset = wingPhase * r * 0.3
            let wingPath = UIBezierPath()
            wingPath.addArc(withCenter: CGPoint(x: cx - r * 0.3, y: cy - wingOffset), radius: r * 0.5, startAngle: .pi * 0.8, endAngle: .pi * 1.2, clockwise: true)
            color.withAlphaComponent(0.6).setStroke()
            wingPath.lineWidth = 1.5
            wingPath.stroke()

            // Eye
            ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            let eye = UIBezierPath(arcCenter: CGPoint(x: cx + r * 0.25, y: cy - r * 0.15), radius: 2.5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            UIColor.white.setFill()
            eye.fill()
        }
        return SKTexture(image: image)
    }

    /// Diamond-shaped player.
    static func neonDiamondPlayer(size: CGSize, color: UIColor, wingPhase: CGFloat = 0) -> SKTexture {
        let padding: CGFloat = 12
        let totalSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2)
        let renderer = UIGraphicsImageRenderer(size: totalSize)
        let image = renderer.image { ctx in
            let cx = totalSize.width / 2
            let cy = totalSize.height / 2
            let w = size.width / 2
            let h = size.height / 2
            let wingOff = wingPhase * h * 0.25

            let body = UIBezierPath()
            body.move(to: CGPoint(x: cx + w, y: cy))
            body.addLine(to: CGPoint(x: cx, y: cy + h + wingOff))
            body.addLine(to: CGPoint(x: cx - w, y: cy))
            body.addLine(to: CGPoint(x: cx, y: cy - h - wingOff))
            body.close()

            ctx.cgContext.setShadow(offset: .zero, blur: 10, color: color.cgColor)
            color.withAlphaComponent(0.4).setFill()
            body.fill()
            color.setStroke()
            body.lineWidth = 2.0
            body.stroke()

            // Eye
            ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            let eye = UIBezierPath(arcCenter: CGPoint(x: cx + w * 0.15, y: cy - h * 0.1), radius: 2.5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            UIColor.white.setFill()
            eye.fill()
        }
        return SKTexture(image: image)
    }

    /// Lightning bolt-shaped player.
    static func neonBoltPlayer(size: CGSize, color: UIColor, wingPhase: CGFloat = 0) -> SKTexture {
        let padding: CGFloat = 12
        let totalSize = CGSize(width: size.width + padding * 2, height: size.height + padding * 2)
        let renderer = UIGraphicsImageRenderer(size: totalSize)
        let image = renderer.image { ctx in
            let cx = totalSize.width / 2
            let cy = totalSize.height / 2
            let w = size.width / 2
            let h = size.height / 2
            let wingOff = wingPhase * h * 0.2

            let body = UIBezierPath()
            body.move(to: CGPoint(x: cx + w * 0.6, y: cy + h + wingOff))
            body.addLine(to: CGPoint(x: cx - w * 0.1, y: cy + h * 0.1))
            body.addLine(to: CGPoint(x: cx + w * 0.3, y: cy + h * 0.1))
            body.addLine(to: CGPoint(x: cx - w * 0.6, y: cy - h - wingOff))
            body.addLine(to: CGPoint(x: cx + w * 0.1, y: cy - h * 0.1))
            body.addLine(to: CGPoint(x: cx - w * 0.3, y: cy - h * 0.1))
            body.close()

            ctx.cgContext.setShadow(offset: .zero, blur: 10, color: color.cgColor)
            color.withAlphaComponent(0.5).setFill()
            body.fill()
            color.setStroke()
            body.lineWidth = 2.0
            body.stroke()

            // Eye
            ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            let eye = UIBezierPath(arcCenter: CGPoint(x: cx + w * 0.05, y: cy - h * 0.15), radius: 2.5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            UIColor.white.setFill()
            eye.fill()
        }
        return SKTexture(image: image)
    }

    /// Creates a city silhouette texture for the far parallax layer.
    static func neonCitySilhouette(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            // Transparent background
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let buildingColor = color.withAlphaComponent(0.08)
            let outlineColor = color.withAlphaComponent(0.15)

            // Generate buildings
            var x: CGFloat = 0
            let count = GameConstants.cityBuildingCount
            let avgWidth = size.width / CGFloat(count)

            for _ in 0..<count {
                let bWidth = CGFloat.random(
                    in: GameConstants.cityBuildingMinWidth...GameConstants.cityBuildingMaxWidth
                )
                let bHeight = size.height * CGFloat.random(
                    in: GameConstants.cityMinHeightFraction...GameConstants.cityMaxHeightFraction
                )

                let rect = CGRect(
                    x: x,
                    y: size.height - bHeight,
                    width: bWidth,
                    height: bHeight
                )
                let path = UIBezierPath(rect: rect)

                buildingColor.setFill()
                path.fill()

                // Subtle outline glow
                ctx.cgContext.setShadow(offset: .zero, blur: 4, color: color.withAlphaComponent(0.2).cgColor)
                outlineColor.setStroke()
                path.lineWidth = 0.5
                path.stroke()
                ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

                // Tiny "window" dots
                let windowSpacing: CGFloat = 8
                var wy = rect.minY + 6
                while wy < rect.maxY - 4 {
                    var wx = rect.minX + 4
                    while wx < rect.maxX - 4 {
                        if Bool.random() && Bool.random() {  // ~25% chance lit
                            let dot = UIBezierPath(
                                rect: CGRect(x: wx, y: wy, width: 2, height: 2)
                            )
                            color.withAlphaComponent(CGFloat.random(in: 0.1...0.3)).setFill()
                            dot.fill()
                        }
                        wx += windowSpacing
                    }
                    wy += windowSpacing
                }

                x += avgWidth + CGFloat.random(in: -5...5)
            }
        }
        return SKTexture(image: image)
    }

    /// Creates a simple ground stripe texture.
    static func neonGround(size: CGSize, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            // Dark fill
            UIColor.glowBackground.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Top neon line
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: 0, y: 1.5))
            linePath.addLine(to: CGPoint(x: size.width, y: 1.5))
            ctx.cgContext.setShadow(offset: .zero, blur: 8, color: color.cgColor)
            color.setStroke()
            linePath.lineWidth = 2.0
            linePath.stroke()

            // Grid lines
            let spacing: CGFloat = 20
            ctx.cgContext.setShadow(offset: .zero, blur: 3, color: color.withAlphaComponent(0.3).cgColor)
            color.withAlphaComponent(0.15).setStroke()
            var x: CGFloat = 0
            while x < size.width {
                let gridLine = UIBezierPath()
                gridLine.move(to: CGPoint(x: x, y: 0))
                gridLine.addLine(to: CGPoint(x: x, y: size.height))
                gridLine.lineWidth = 0.5
                gridLine.stroke()
                x += spacing
            }
        }
        return SKTexture(image: image)
    }
}

// MARK: - SKEmitterNode Helpers

extension SKEmitterNode {
    /// Creates a neon particle trail emitter.
    static func neonTrail(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = GameConstants.trailBirthRate
        emitter.particleLifetime = GameConstants.trailLifetime
        emitter.particleLifetimeRange = 0.15
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleSize = CGSize(width: GameConstants.trailParticleSize, height: GameConstants.trailParticleSize)
        emitter.particleSizeRange = 2.0
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -2.0
        emitter.emissionAngle = .pi  // emit backward (left)
        emitter.emissionAngleRange = .pi / 6
        emitter.particleSpeed = GameConstants.trailSpeed
        emitter.particleSpeedRange = 15
        emitter.particleBlendMode = .add
        emitter.targetNode = nil  // set to scene so particles stay in world space
        return emitter
    }

    /// Creates a small sparkle effect for scoring.
    static func scoreSparkle(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 150
        emitter.numParticlesToEmit = 12
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.15
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleSize = CGSize(width: 4, height: 4)
        emitter.particleSizeRange = 3
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -2.5
        emitter.emissionAngle = .pi / 2  // upward
        emitter.emissionAngleRange = .pi / 3
        emitter.particleSpeed = 60
        emitter.particleSpeedRange = 30
        emitter.particleBlendMode = .add
        return emitter
    }

    /// Creates a burst particle effect for death / collision.
    static func neonBurst(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 300
        emitter.numParticlesToEmit = 40
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.3
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.particleSizeRange = 4
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.8
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 120
        emitter.particleSpeedRange = 60
        emitter.particleBlendMode = .add
        return emitter
    }
}

// MARK: - CGFloat Helpers

extension CGFloat {
    /// Clamp value between min and max.
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Liquid Glass Textures

extension SKTexture {

    /// Creates a Liquid Glass panel texture — translucent, frosted, with a subtle top highlight.
    static func glassPanel(size: CGSize, cornerRadius: CGFloat = GameConstants.glassPanelCornerRadius, tintColor: UIColor = .white) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

            // Dark translucent fill
            UIColor(white: 0.08, alpha: GameConstants.glassPanelAlpha).setFill()
            path.fill()

            // Top highlight gradient (simulates light refraction)
            ctx.cgContext.saveGState()
            let highlightRect = CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.45)
            let highlightPath = UIBezierPath(
                roundedRect: highlightRect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            )
            highlightPath.addClip()
            let colors = [
                UIColor(white: 1.0, alpha: GameConstants.glassHighlightAlpha).cgColor,
                UIColor(white: 1.0, alpha: 0.0).cgColor,
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: highlightRect.height),
                options: []
            )
            ctx.cgContext.restoreGState()

            // Inner glow edge
            ctx.cgContext.setShadow(offset: .zero, blur: 6, color: tintColor.withAlphaComponent(0.06).cgColor)

            // Border
            tintColor.withAlphaComponent(GameConstants.glassBorderAlpha).setStroke()
            path.lineWidth = 1.0
            path.stroke()
        }
        return SKTexture(image: image)
    }

    /// Creates a neon-styled button texture with glass interior.
    static func neonButton(size: CGSize, color: UIColor, cornerRadius: CGFloat = GameConstants.buttonCornerRadius) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

            // Glass fill
            UIColor(white: 0.1, alpha: 0.45).setFill()
            path.fill()

            // Neon border with glow
            ctx.cgContext.setShadow(offset: .zero, blur: 8, color: color.withAlphaComponent(0.6).cgColor)
            color.withAlphaComponent(0.7).setStroke()
            path.lineWidth = 1.5
            path.stroke()

            // Inner top highlight
            ctx.cgContext.saveGState()
            let topRect = CGRect(x: 2, y: 2, width: size.width - 4, height: size.height * 0.4)
            let topPath = UIBezierPath(
                roundedRect: topRect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: cornerRadius - 2, height: cornerRadius - 2)
            )
            topPath.addClip()
            let colors = [
                UIColor(white: 1.0, alpha: 0.1).cgColor,
                UIColor(white: 1.0, alpha: 0.0).cgColor,
            ]
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            )!
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: topRect.height), options: [])
            ctx.cgContext.restoreGState()
        }
        return SKTexture(image: image)
    }

    /// Creates a toggle button texture (on/off state).
    static func toggleButton(size: CGSize, isOn: Bool, color: UIColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: size.height / 2)

            // Track
            let trackColor = isOn ? color.withAlphaComponent(0.3) : UIColor(white: 0.2, alpha: 0.4)
            trackColor.setFill()
            path.fill()

            // Border
            let borderColor = isOn ? color.withAlphaComponent(0.6) : UIColor(white: 0.4, alpha: 0.3)
            ctx.cgContext.setShadow(offset: .zero, blur: isOn ? 6 : 0, color: color.withAlphaComponent(0.4).cgColor)
            borderColor.setStroke()
            path.lineWidth = 1.5
            path.stroke()

            // Knob
            let knobSize = size.height - 6
            let knobX = isOn ? size.width - knobSize - 3 : CGFloat(3)
            let knobRect = CGRect(x: knobX, y: 3, width: knobSize, height: knobSize)
            let knobPath = UIBezierPath(ovalIn: knobRect)
            ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            let knobColor = isOn ? color : UIColor(white: 0.6, alpha: 1.0)
            knobColor.setFill()
            knobPath.fill()
        }
        return SKTexture(image: image)
    }
}

// MARK: - SKNode Glass Panel Helper

extension SKSpriteNode {
    /// Creates a glass panel sprite node.
    static func glassPanel(size: CGSize, tintColor: UIColor = .white) -> SKSpriteNode {
        let texture = SKTexture.glassPanel(size: size, tintColor: tintColor)
        let node = SKSpriteNode(texture: texture, size: size)
        node.name = "glassPanel"
        return node
    }
}
