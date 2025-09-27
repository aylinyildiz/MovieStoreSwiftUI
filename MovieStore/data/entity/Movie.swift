import Foundation

struct Movie: Codable, Identifiable {
    let id: Int
    let name: String?
    let image: String?
    let price: Int?
    let category: String?
    let rating: Double?
    let year: Int?
    let director: String?
    let description: String?
    
    var imageUrl: URL? {
        guard let imageName = image else { return nil }
        return URL(string: "http://kasimadalan.pe.hu/movies/images/\(imageName)")
    }
}
