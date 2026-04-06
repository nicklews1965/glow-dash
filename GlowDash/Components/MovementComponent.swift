import GameplayKit
import SpriteKit

/// Moves an entity's sprite node horizontally at a given speed.
/// Used for obstacles and background layers that scroll from right to left.
final class MovementComponent: GKComponent {

    /// Horizontal velocity in points per second (negative = leftward).
    var speed: CGFloat

    init(speed: CGFloat) {
        self.speed = speed
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not used") }

    override func update(deltaTime seconds: TimeInterval) {
        guard let node = entity?.component(ofType: SpriteComponent.self)?.node else { return }
        node.position.x += speed * CGFloat(seconds)
    }
}
