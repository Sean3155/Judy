import Foundation

enum ComfortLevel: String {
    case freezing
    case cold
    case cool
    case mild
    case warm
    case hot
}

enum WindImpactLevel: String {
    case low
    case moderate
    case high
}

enum RainImpactLevel: String {
    case none
    case light
    case moderate
    case heavy
}

struct WeatherAdvice {
    let comfortLevel: ComfortLevel
    let windImpact: WindImpactLevel
    let rainImpact: RainImpactLevel
    
    let clothingRecommendations: [String]
    let cautions: [String]
    let summary: String
    let comfortNote: String
    
    let isGoodForShortWalk: Bool
    let isGoodForLongWalk: Bool
    let walkComfortScore: Int
}
