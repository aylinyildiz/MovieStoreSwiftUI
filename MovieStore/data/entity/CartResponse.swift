import Foundation

struct CartResponse: Codable {
    let cartMovies: [CartMovie]
    
    enum CodingKeys: String, CodingKey {
        case cartMovies = "movie_cart"
    }
}
