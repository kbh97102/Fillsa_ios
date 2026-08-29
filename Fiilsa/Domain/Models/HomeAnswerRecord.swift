import Foundation

/// A locally persisted response to the Home question, isolated from quote typing transcripts.
struct HomeAnswerRecord: Codable, Equatable {
    let dateKey: String
    let question: String
    let answer: String
}
