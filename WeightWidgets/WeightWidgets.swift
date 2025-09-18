import WidgetKit
import SwiftUI
import AppIntents
import HealthKit

struct Provider: TimelineProvider {
    let healthKitManager = HealthKitManager()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), weight: 68.5, goal: 65.0, startWeight: 75.0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), weight: 68.5, goal: 65.0, startWeight: 75.0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        healthKitManager.fetchMostRecentWeight { weight in
            let userDefaults = UserDefaults(suiteName: "group.com.pineapple.fitness")
            let goal = userDefaults?.double(forKey: "targetWeight") ?? 65.0
            let startWeight = userDefaults?.double(forKey: "startWeight") ?? 75.0

            let entry = SimpleEntry(date: Date(), weight: weight ?? 0, goal: goal, startWeight: startWeight)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let weight: Double
    let goal: Double
    let startWeight: Double
}

struct WeightWidgetsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if entry.weight == 0 {
            VStack {
                Text("No Weight Data")
                    .font(.headline)
                Text("Please add a weight record in the app.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack {
                Spacer()

                PersonView(progress: progress)

                ZStack {
                    ProgressBar(progress: progress)
                        .frame(height: 50)
                    
                    AddButton()
                }

                HStack {
                    Text("\(entry.weight, specifier: "%.1f")kg")
                        .font(.title2) // Changed from .title to .title2
                        .fontWeight(.bold)
                        .contentTransition(.numericText())
                        .animation(.default, value: entry.weight)

                    Spacer()
                    Text("\(entry.goal, specifier: "%.1f")kg")
                        .font(.title2) // Changed from .title to .title2
                        .fontWeight(.bold)
                }
            }
            .containerBackground(for: .widget) {
                Color(.sRGB, red: 242/255, green: 242/255, blue: 247/255, opacity: 1.0)
            }
        }
    }

    private var progress: Double {
        return max(0, min(1, (entry.startWeight - entry.weight) / (entry.startWeight - entry.goal)))
    }
}

struct PersonView: View {
    let progress: Double

    var body: some View {
        Image(systemName: progress < 0.8 ? "figure.run" : "figure.run.circle") // Changed to running icons
            .font(.system(size: 50)) // Increased font size for better visibility
            .foregroundColor(progressColor)
            .animation(.easeInOut, value: progress)
    }

    private var progressColor: Color {
        switch progress {
        case ..<0.5:
            return .red
        case 0.5..<0.9:
            return .orange
        case 0.9..<1.0:
            return .green
        default:
            return .yellow
        }
    }
}

struct ArcProgressBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let arcRadius: CGFloat = 25 // Reduced radius for a more subtle arc
        let arcCenter = CGPoint(x: rect.midX, y: rect.height / 2)

        path.move(to: CGPoint(x: 0, y: rect.height / 2))
        path.addLine(to: CGPoint(x: rect.midX - arcRadius, y: rect.height / 2))
        path.addArc(center: arcCenter, radius: arcRadius, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false) // Corrected arc direction
        path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))

        return path
    }
}


struct ProgressBar: View {
    let progress: Double

    var body: some View {
        ZStack {
            ArcProgressBarShape()
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundColor(Color(UIColor.systemGray3))

            ArcProgressBarShape()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .foregroundColor(progressColor)
                .animation(.linear, value: progress)
        }
    }

    private var progressColor: Color {
        switch progress {
        case ..<0.5:
            return .red
        case 0.5..<0.9:
            return .orange
        case 0.9..<1.0:
            return .green
        default:
            return .yellow
        }
    }
}

struct AddButton: View {
    var body: some View {
        if let url = URL(string: "fitness://add-weight") {
            Button(intent: OpenURLIntent(url)) {
                Image(systemName: "plus")
                    .font(.title3) // Reduced font size further
                    .foregroundColor(.white)
                    .padding(8) // Reduced padding further
                    .background(Color.blue) // Changed background to blue
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle()) // Added to remove default button styling
            .tint(.clear) // Explicitly set tint to clear
        }
    }
}


struct WeightWidgets: Widget {
    let kind: String = "WeightWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeightWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("体重小组件")
        .description("显示您的体重变化.")
    }
}

#Preview(as: .systemSmall) {
    WeightWidgets()
} timeline: {
    SimpleEntry(date: .now, weight: 68.5, goal: 65.0, startWeight: 75.0)
    SimpleEntry(date: .now, weight: 66.0, goal: 65.0, startWeight: 75.0)
}
