//
//  TaggableTextEditorViewModel.swift
//  Mentions
//
//  Created by Ankit Sachan on 21/11/24.
//

import SwiftUI
import Combine

enum SearchState<T : Equatable> : Equatable{
    case idle
    case fetching
    case fetched([T])  // Contains an array of fetched records
    case failed(String)     // Contains an error message
    
    static func ==(lhs: SearchState<T>, rhs: SearchState<T>) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.fetching, .fetching):
            return true
        case (.fetched(let a), .fetched(let b)):
            return a == b
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}



class TaggableTextEditorViewModel: ObservableObject {
    
    @Published var filteredEmails: [String] = []
    @Published var searchState: SearchState<String> = .idle
    private var cancellables = Set<AnyCancellable>()
    @Published var emailViewHeight: CGFloat = 0
    @Published var text: String = ""
    @Published var showEmailListFlag: Bool = false
    @Published var searchText: String = ""
    @Published var cursorPositionAfterEmailSelection: NSRange?
    @Published var currentEditingToken: TaggableTextViewToken?
    @Published var taggedEmails: [String] = []
    
    func fetchEmails(searchText: String) {
        // Set state to fetching
        searchState = .fetching
        
        // Simulate an API call with a delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let allEmails = ["user1@example.com", "user2@example.com", "test@example.com", "sample@example.com"]
            
            // Simulate success or failure
            if searchText.isEmpty {
                DispatchQueue.main.async {
                    self.searchState = .failed("Search text is empty")
                }
            } else {
                let filteredEmails = allEmails.filter { $0.contains(searchText) }
                DispatchQueue.main.async {
                    self.searchState = .fetched(filteredEmails)
                }
            }
        }
    }
}
