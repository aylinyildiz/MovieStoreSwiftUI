import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(description: String)
    case noData
    case decodingError(description: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL adresi."
        case .requestFailed(let description):
            return "İstek başarısız oldu: \(description)"
        case .noData:
            return "Sunucudan veri alınamadı."
        case .decodingError(let description):
            return "Veri işlenirken bir hata oluştu: \(description)"
        }
    }
}


class MovieRepository {
    static let shared = MovieRepository()
    private init() {}
    
    private let baseURL = "http://kasimadalan.pe.hu/movies/"
    private let imageBaseURL = "http://kasimadalan.pe.hu/movies/images/"

    func getImageUrl(for imageName: String) -> URL? {
        return URL(string: imageBaseURL + imageName)
    }
    
    func fetchAllMovies() async throws -> [Movie] {
        let apiUrl = "\(baseURL)getAllToDos.php"
        
        guard let url = URL(string: apiUrl) else {
            throw URLError(.badURL)
        }
        
        let (data,_) = try await URLSession.shared.data(from: url)
        let toDosResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
        
        return toDosResponse.movies
    }
 
}
