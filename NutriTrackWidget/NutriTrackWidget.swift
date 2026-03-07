import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct NutriTrackEntry: TimelineEntry {
    let date: Date
}

// MARK: - Timeline Provider

struct NutriTrackProvider: TimelineProvider {
    func placeholder(in context: Context) -> NutriTrackEntry {
        NutriTrackEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (NutriTrackEntry) -> Void) {
        completion(NutriTrackEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NutriTrackEntry>) -> Void) {
        // Static widget — never needs refreshing
        let entry = NutriTrackEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Widget View

struct NutriTrackWidgetView: View {
    var entry: NutriTrackEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "drop")
                .font(.system(size: 28, weight: .light))
                .widgetAccentable()
        }
        .widgetURL(URL(string: "nutritrack://"))
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Widget Configuration

@main
struct NutriTrackWidget: Widget {
    let kind: String = "NutriTrackLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NutriTrackProvider()) { entry in
            NutriTrackWidgetView(entry: entry)
        }
        .configurationDisplayName("NutriTrack")
        .description("Open NutriTrack from your lock screen.")
        .supportedFamilies([.accessoryCircular])
    }
}
