import Foundation

@MainActor
class MoviesViewModel: ObservableObject {

    @Published var movies: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    @Published var searchText: String = ""

    var filteredMovies: [Movie] {
        guard !searchText.isEmpty else {
            return movies
        }

        return movies.filter { movie in
            movie.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    private let apiURL = "http://kasimadalan.pe.hu/movies/getAllMovies.php"

    func loadMovies() async {
        guard movies.isEmpty && !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: apiURL) else {
            errorMessage = "Geçersiz URL!"
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedResponse = try JSONDecoder().decode(MovieResponse.self, from: data)
            self.movies = decodedResponse.movies
        } catch {
            self.errorMessage = "Filmler yüklenirken bir hata oluştu: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
