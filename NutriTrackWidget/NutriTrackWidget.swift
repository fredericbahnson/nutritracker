import WidgetKit
import SwiftUI

// MARK: - Stub Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = SimpleEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
}

// MARK: - EntryView

struct NutriTrackWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Widget coming soon")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget declaration

@main
struct NutriTrackWidget: Widget {
    let kind: String = "NutriTrackWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            NutriTrackWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("NutriTrack")
        .description("Track your daily nutrition goals.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    NutriTrackWidget()
} timeline: {
    SimpleEntry(date: Date())
}
