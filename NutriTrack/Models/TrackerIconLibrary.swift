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
        var path = Path()

        // ── Geometry constants ────────────────────────────────────────────────
        let inset     = rect.width * 0.12
        let left      = rect.minX + inset
        let right     = rect.maxX - inset
        let top       = rect.minY + inset
        let bottom    = rect.maxY - inset

        let usableW   = right - left
        let usableH   = bottom - top
        let centerX   = rect.midX
        let periods   = 2.0              // 2 full sine periods → 4 half-period segments
        let segments  = Int(periods * 2) // = 4

        // ── Helpers ───────────────────────────────────────────────────────────
        func yPos(_ t: Double) -> Double { top + usableH * t }

        // Strand A: sin(angle), Strand B: its mirror across centerX
        func xA(_ t: Double) -> Double {
            let angle = t * periods * 2 * Double.pi
            return centerX + (usableW * 0.5) * 0.5 * sin(angle)
        }
        func xB(_ t: Double) -> Double { 2 * centerX - xA(t) }

        // ── Draw strands as cubic Bézier curves ───────────────────────────────
        // Each half-period segment is one cubic Bézier. Control points at 35% of
        // segment height from each endpoint, x held at endpoint x-value. This
        // produces the characteristic elongated S-curve of a projected helix strand.
        let segH = 1.0 / Double(segments)

        func addSegment(to p: inout Path, t0: Double, t1: Double,
                        xFunc: (Double) -> Double) {
            let p0    = CGPoint(x: xFunc(t0), y: yPos(t0))
            let p3    = CGPoint(x: xFunc(t1), y: yPos(t1))
            // Push control-point x to the half-period's amplitude peak (×4/3 for Bézier accuracy)
            let peakX = centerX + (xFunc((t0 + t1) / 2) - centerX) * (4.0 / 3.0)
            let cp1   = CGPoint(x: peakX, y: yPos(t0 + segH / 3))
            let cp2   = CGPoint(x: peakX, y: yPos(t1 - segH / 3))
            p.move(to: p0)
            p.addCurve(to: p3, control1: cp1, control2: cp2)
        }

        for i in 0..<segments {
            let t0 = Double(i) * segH
            let t1 = Double(i + 1) * segH
            addSegment(to: &path, t0: t0, t1: t1, xFunc: xA)
            addSegment(to: &path, t0: t0, t1: t1, xFunc: xB)
        }

        // ── Draw cross-bars at interior strand crossings only ─────────────────
        // Crossings occur at segment boundaries: t = k * segH for k = 1, 2, 3.
        // Exclude k=0 and k=segments (top and bottom endpoints) — bars there
        // close the icon into a rectangle and hurt readability at small sizes.
        // At each crossing, xA(t) == xB(t) == centerX by construction, so the
        // bar is always centered. Span 40% of usable width (20% each side).
        let barHalfWidth = usableW * 0.20

        for k in 1..<segments {
            let t = Double(k) * segH
            let y = yPos(t)
            path.move(to:    CGPoint(x: centerX - barHalfWidth, y: y))
            path.addLine(to: CGPoint(x: centerX + barHalfWidth, y: y))
        }

        // ── Rotate 20° clockwise around the rect center ───────────────────────
        // Rotating around rect.mid keeps the icon centered in its frame.
        let angle = CGFloat(20 * Double.pi / 180)
        var transform = CGAffineTransform(translationX: rect.midX, y: rect.midY)
        transform = transform.rotated(by: angle)
        transform = transform.translatedBy(x: -rect.midX, y: -rect.midY)

        return path.applying(transform)
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
