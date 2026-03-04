import SwiftUI

// MARK: - TrackerIcon

struct TrackerIcon: Identifiable, Hashable {
    let id: String
    let displayName: String
    let category: String
    let isCustomPath: Bool

    init(id: String, displayName: String, category: String, isCustomPath: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.category = category
        self.isCustomPath = isCustomPath
    }
}

// MARK: - TrackerIconLibrary

enum TrackerIconLibrary {

    static let all: [TrackerIcon] = [
        // Nutrition
        TrackerIcon(id: "custom.helix",    displayName: "Protein / DNA",    category: "Nutrition",
                    isCustomPath: true),
        TrackerIcon(id: "fork.knife",      displayName: "Meals",            category: "Nutrition"),
        TrackerIcon(id: "leaf",            displayName: "Vegetables",       category: "Nutrition"),
        TrackerIcon(id: "flame",           displayName: "Calories",         category: "Nutrition"),
        TrackerIcon(id: "drop",            displayName: "Water / Liquids",  category: "Nutrition"),
        TrackerIcon(id: "cup.and.saucer",  displayName: "Drinks",           category: "Nutrition"),
        // Activity
        TrackerIcon(id: "figure.run",      displayName: "Running",          category: "Activity"),
        TrackerIcon(id: "bicycle",         displayName: "Cycling",          category: "Activity"),
        TrackerIcon(id: "figure.walk",     displayName: "Walking",          category: "Activity"),
        TrackerIcon(id: "bolt",            displayName: "Energy",           category: "Activity"),
        // Wellness
        TrackerIcon(id: "heart",           displayName: "Heart",            category: "Wellness"),
        TrackerIcon(id: "moon.zzz",        displayName: "Sleep",            category: "Wellness"),
        TrackerIcon(id: "lungs",           displayName: "Breathing",        category: "Wellness"),
        TrackerIcon(id: "cross.case",      displayName: "Supplements",      category: "Wellness"),
        // General
        TrackerIcon(id: "star",            displayName: "Favorite",         category: "General"),
        TrackerIcon(id: "custom.wheat",    displayName: "Grains / Wheat",   category: "General",
                    isCustomPath: true),
    ]

    // MARK: - Custom path: double helix

    static func helixPath(in rect: CGRect) -> Path {
        let inset     = rect.width * 0.12
        let left      = rect.minX + inset
        let right     = rect.maxX - inset
        let top       = rect.minY + inset
        let bottom    = rect.maxY - inset
        let height    = bottom - top
        let centerX   = rect.midX
        let amplitude = (right - left) / 2
        let periods   = 2
        let steps     = 60

        var path = Path()

        // Strand A
        for i in 0...steps {
            let t     = Double(i) / Double(steps)
            let angle = t * Double(periods) * 2 * .pi
            let x     = centerX + amplitude * sin(angle)
            let y     = top + height * t
            let pt    = CGPoint(x: x, y: y)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }

        // Strand B (half-period offset)
        for i in 0...steps {
            let t     = Double(i) / Double(steps)
            let angle = t * Double(periods) * 2 * .pi
            let x     = centerX + amplitude * sin(angle + .pi)
            let y     = top + height * t
            let pt    = CGPoint(x: x, y: y)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
        }

        // Cross-bars at quarter-period crossings: angle = π/2 + k*π, k = 0...3
        let totalAngle = Double(periods) * 2 * .pi
        for k in 0..<(periods * 2) {
            let angle = Double.pi / 2 + Double(k) * .pi
            let t     = angle / totalAngle
            let xA    = centerX + amplitude * sin(angle)
            let xB    = centerX + amplitude * sin(angle + .pi)
            let y     = top + height * t
            path.move(to: CGPoint(x: xA, y: y))
            path.addLine(to: CGPoint(x: xB, y: y))
        }

        return path
    }

    // MARK: - Custom path: wheat stalk with branch pairs

    static func wheatPath(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let top = rect.minY + rect.height * 0.05
        let bottom = rect.maxY - rect.height * 0.05
        let stemHeight = bottom - top

        // Vertical stalk
        path.move(to: CGPoint(x: cx, y: bottom))
        path.addLine(to: CGPoint(x: cx, y: top))

        // 4 pairs of diagonal branches
        let branchCount = 4
        let spacing = stemHeight / CGFloat(branchCount + 1)
        let branchLen = rect.width * 0.28
        let angle = CGFloat.pi / 4 // 45°
        let dx = branchLen * cos(angle)
        let dy = branchLen * sin(angle)

        for i in 1...branchCount {
            let y = bottom - spacing * CGFloat(i)
            // Left branch
            path.move(to: CGPoint(x: cx, y: y))
            path.addLine(to: CGPoint(x: cx - dx, y: y - dy))
            // Right branch
            path.move(to: CGPoint(x: cx, y: y))
            path.addLine(to: CGPoint(x: cx + dx, y: y - dy))
        }

        return path
    }

    // MARK: - Icon view factory

    static func iconView(for icon: TrackerIcon, size: CGFloat, color: Color) -> AnyView {
        if icon.isCustomPath {
            let boundingRect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            let path: Path
            switch icon.id {
            case "custom.helix":
                path = helixPath(in: boundingRect)
            case "custom.wheat":
                path = wheatPath(in: boundingRect)
            default:
                return AnyView(EmptyView())
            }
            return AnyView(
                Canvas { context, _ in
                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
                }
                .frame(width: size, height: size)
            )
        } else {
            return AnyView(
                Image(systemName: icon.id)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .fontWeight(.light)
                    .foregroundStyle(color)
            )
        }
    }
}
