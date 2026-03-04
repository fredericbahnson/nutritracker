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
        TrackerIcon(id: "dna",             displayName: "DNA / Protein",    category: "Nutrition"),
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
            return AnyView(
                Canvas { ctx, canvasSize in
                    let rect = CGRect(origin: .zero, size: canvasSize)
                    ctx.stroke(
                        wheatPath(in: rect),
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
