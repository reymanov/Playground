import SwiftUI

struct UserListView: View {
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var currentPage = 0
    @State private var searchText = ""
    @State private var debounceTimer: DispatchWorkItem?
    @State private var sortBy = "firstName"
    @State private var sortOrder = "asc"
    @State private var totalUsers = 0

    let limit = 15

    var body: some View {
        NavigationStack {
            List {
                ForEach(users) { user in
                    Text("\(user.firstName) \(user.lastName)")
                        .onAppear {
                            if users.last == user && totalUsers > users.count {
                                loadNextPage()
                            }
                        }
                }
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Users")
            .searchable(text: $searchText)
            .overlay {
                if users.isEmpty && !isLoading {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "No Users",
                            systemImage: "person.slash",
                            description: Text("There are no users available.")
                        )
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
            .toolbar {
                Menu {
                    Picker("Sort By", selection: $sortBy) {
                        Text("First Name").tag("firstName")
                        Text("Last Name").tag("lastName")
                    }
                    Picker("Sort Order", selection: $sortOrder) {
                        Text("Ascending").tag("asc")
                        Text("Descending").tag("desc")
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }
            .onAppear {
                if users.isEmpty {
                    fetchUsers(reset: true)
                }
            }
            .onChange(of: searchText) { _, _ in
                debounceSearch()
            }
            .onChange(of: sortBy) { _, _ in fetchUsers(reset: true) }
            .onChange(of: sortOrder) { _, _ in fetchUsers(reset: true) }
        }
    }

    func debounceSearch() {
        debounceTimer?.cancel()
        
        let newDebounceTimer = DispatchWorkItem {
            fetchUsers(reset: true)
        }
        
        debounceTimer = newDebounceTimer
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: newDebounceTimer)
    }

    func loadNextPage() {
        guard !isLoading else { return }
        currentPage += 1
        fetchUsers(reset: false)
    }

    func fetchUsers(reset: Bool) {
        if reset {
            users.removeAll()
            currentPage = 0
        }

        guard !isLoading else { return }
        isLoading = true
        
        let skip = currentPage * limit
        var urlString = "https://dummyjson.com/users"
        
        if !searchText.isEmpty {
            urlString += "/search"
        }
        
        var urlComponents = URLComponents(string: urlString)
        var queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "order", value: sortOrder)
        ]
        
        if !searchText.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: searchText))
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                defer { isLoading = false }
                
                guard let data = data else { return }

                do {
                    let result = try JSONDecoder().decode(UserResponse.self, from: data)
                    if reset {
                        users = result.users
                    } else {
                        users.append(contentsOf: result.users)
                    }
                    totalUsers = result.total
                } catch {
                    print("Error decoding users: \(error)")
                }
            }
        }.resume()
    }
}

struct User: Codable, Identifiable, Equatable {
    let id: Int
    let firstName: String
    let lastName: String
}

struct UserResponse: Codable {
    let users: [User]
    let total: Int
    let skip: Int
    let limit: Int
}

#Preview {
    UserListView()
}
