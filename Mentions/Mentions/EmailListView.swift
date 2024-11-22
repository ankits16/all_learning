//
//  EmailListView.swift
//  Mentions
//
//  Created by Ankit Sachan on 21/11/24.
//

import SwiftUI

struct EmailFetchView : View {
    @ObservedObject var viewModel: TaggableTextEditorViewModel
//    let searchState: SearchState<String>
    let handleEmailSelection: (String) -> Void
    
    var body: some View {
        switch viewModel.searchState {
        case .idle:
            Text("Start typing to search emails...")
                .padding()  // Add padding around the content
                .background(Color.gray)  // Green background
                .cornerRadius(10)  // Rounded corners
                .foregroundColor(.white)  // White text color
                
        case .fetching:
            HStack {
                ProgressView()
                Spacer().frame(width: 10) // Adds a 10-point space
                Text("FETCH_RECORDS")
            }
            .padding()  // Add padding around the content
            .background(Color.gray)  // Green background
            .cornerRadius(10)  // Rounded corners
            .foregroundColor(.white)  // White text color
        case .fetched(let emails):
            if emails.isEmpty {
                EmptyView()
            } else {
                EmailListView(emails: emails, handleEmailSelection: handleEmailSelection)
            }
        case .failed(let errorMessage):
            //in main app we'll show banner instead
            Text("Error: \(errorMessage)")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct EmailListView: View {
    var emails : [String]
    let handleEmailSelection: (String) -> Void
    
    private func calculateListHeight(_ emails : [String]) -> CGFloat {
       
        var totalHeight: CGFloat = 0
        
        for _ in emails {
            let estimatedHeight = 44.0
            totalHeight += estimatedHeight
            if totalHeight >= 150 {
                return 150
            }
        }
        
        return totalHeight
    }
    
    
    var body: some View {
        List(emails, id: \.self) { email in
            Text(email)
                .onTapGesture {
                    handleEmailSelection(email)
                }
                .foregroundColor(Color.green)
        }
        .listStyle(PlainListStyle())
        .frame(width: UIScreen.main.bounds.width - 40, height: calculateListHeight(emails))
        .cornerRadius(10)  // Rounded corners
        .shadow(radius: 10)
    }
}
