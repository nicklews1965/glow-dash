import GameplayKit
import SpriteKit

/// Marks an invisible zone in the obstacle gap that triggers scoring
/// when the player passes through it.
final class ScoreComponent: GKComponent {

    /// Whether this score zone has already been triggered.
    var hasScored: Bool = false

    override init() {
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Not used") }
}
