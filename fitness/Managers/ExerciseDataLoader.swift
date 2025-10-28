
import Foundation

class ExerciseDataLoader {
    static func loadExercises() -> [Exercise] {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            fatalError("Failed to find exercises.json in app bundle.")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([Exercise].self, from: data)
        } catch {
            fatalError("Failed to load or decode exercises.json: \(error)")
        }
    }
}
