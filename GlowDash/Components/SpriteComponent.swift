import GameplayKit
import SpriteKit

/// Holds a reference to the entity's visual node in the SpriteKit scene.
final class SpriteComponent: GKComponent {

    let node: SKNode

    init(node: SKNode) {
        self.node = node
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not used") }
}
