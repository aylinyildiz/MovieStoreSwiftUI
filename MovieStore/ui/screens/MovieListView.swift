import SwiftUI

struct MovieListView: View {
    
    @StateObject private var viewModel = MoviesViewModel()
    @StateObject private var cartViewModel = CartViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
    
                VStack(spacing: 0) {
                    headerView

                    SearchBarView(searchText: $viewModel.searchText)

                    if viewModel.isLoading && viewModel.movies.isEmpty {
                        Spacer()
                        ProgressView().scaleEffect(1.5).tint(.white)
                        Spacer()
                    } else if !viewModel.searchText.isEmpty {
                        searchResultsView
                    } else {
                        mainContent
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadMovies()
                await cartViewModel.loadCart()
            }
            .onAppear {
                Task { await cartViewModel.loadCart() }
            }
            .environmentObject(cartViewModel)
        }
        .accentColor(.white)
        .navigationViewStyle(.stack)
    }

    private var headerView: some View {
        HStack {
            Text("MOVIE STORE")
                .font(.headline).fontWeight(.heavy).foregroundColor(.red)
            
            Spacer()
            
            NavigationLink(destination: CartView()) {
                cartIconWithBadge
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var mainContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {
                if let featuredMovie = viewModel.movies.first {
                    FeaturedMovieView(movie: featuredMovie)
                }
                if viewModel.movies.count > 1 {
                    MovieSectionView(title: "Popüler Filmler", movies: Array(viewModel.movies.dropFirst()))
                }
                if viewModel.movies.count > 5 {
                     MovieSectionView(title: "Yeniden Keşfet", movies: viewModel.movies.shuffled())
                }
                Spacer(minLength: 40)
            }
        }
        .transition(.opacity)
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(viewModel.filteredMovies) { movie in
                    NavigationLink(destination: MovieDetailView(movie: movie)) {
                        MoviePosterCell(movie: movie)
                    }
                }
                
            }
            .padding()
        }
        .transition(.opacity)
    }

    private var cartIconWithBadge: some View {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart.fill")
                    .font(.title2).foregroundColor(.white)
                if cartViewModel.totalItemCount > 0 {
                    Text("\(cartViewModel.totalItemCount)")
                        .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                        .padding(5).background(Color.red).clipShape(Circle())
                        .offset(x: 10, y: -10)
                }
            }
        }
}


struct SearchBarView: View {
    
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white)
            
            TextField("Film Ara...", text: $searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .overlay(
                    Image(systemName: "xmark.circle.fill")
                        .padding()
                        .offset(x: 10)
                        .foregroundColor(.white)
                        .opacity(searchText.isEmpty ? 0 : 1)
                        .onTapGesture {
                            searchText = ""
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    , alignment: .trailing
                )
        }
        .font(.headline)
        .padding(12)
        .background(Color(white: 0.15))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}


struct FeaturedMovieView: View {
    let movie: Movie
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: movie.imageUrl) { image in image.resizable().aspectRatio(contentMode: .fill) } placeholder: { Rectangle().fill(.gray.opacity(0.5)) }
                .frame(height: 450).clipped()
            VStack { Spacer(); LinearGradient(colors: [.clear, .black.opacity(0.8), .black], startPoint: .top, endPoint: .bottom).frame(height: 150) }
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.name ?? "Film Adı").font(.largeTitle).fontWeight(.black).shadow(radius: 10)
                Text(movie.category ?? "").font(.subheadline).fontWeight(.medium).foregroundColor(.white.opacity(0.8))
                NavigationLink(destination: MovieDetailView(movie: movie)) {
                    Text("Şimdi Göz At").fontWeight(.bold).padding(.horizontal, 20).padding(.vertical, 10).background(.red).cornerRadius(8)
                }
            }.foregroundColor(.white).padding()
        }
    }
}

struct MovieSectionView: View {
    let title: String
    let movies: [Movie]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title2).fontWeight(.bold).foregroundColor(.white).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        NavigationLink(destination: MovieDetailView(movie: movie)) { MoviePosterCell(movie: movie) }
                    }
                }.padding(.horizontal)
            }
        }
    }
}

struct MoviePosterCell: View {
    let movie: Movie
    var body: some View {
        AsyncImage(url: movie.imageUrl) { image in image.resizable() } placeholder: { ZStack { Color.gray.opacity(0.3); ProgressView() } }
            .aspectRatio(2/3, contentMode: .fill)
            .frame(width: 140, height: 210)
            .cornerRadius(12)
            .shadow(radius: 5)
    }
}

struct MovieListView_Previews: PreviewProvider {
    static var previews: some View {
        MovieListView()
            .preferredColorScheme(.dark)
    }
}
