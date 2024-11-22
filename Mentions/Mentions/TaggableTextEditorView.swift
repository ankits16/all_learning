//
//  TaggableTextEditorView.swift
//  Mentions
//
//  Created by Ankit Sachan on 21/11/24.
//

import SwiftUI
import Combine

struct TaggableTextEditorView: View {
    @StateObject private var viewModel = TaggableTextEditorViewModel()
    @State private var cancellable: AnyCancellable?
    
    private var taggableTextview: TaggableTextView {
        TaggableTextView(viewModel: viewModel)
    }
    
    
    var body: some View {
        VStack {
            taggableTextview
                .frame(minHeight: 40, maxHeight: 120)
                .border(Color.gray, width: 1)
                .padding()
                .onAppear {
                    // Bind the searchText changes manually for earlier iOS versions
                    cancellable = viewModel.$searchText
                        .sink { searchText in
                            if viewModel.showEmailListFlag {
                                viewModel.fetchEmails(searchText: searchText)
                            }
                        }
                }
                .onDisappear {
                    // Cancel the subscription when the view disappears
                    cancellable?.cancel()
                }
                .overlay(
                    Group {
                        if viewModel.showEmailListFlag {
                            EmailFetchView(
                                viewModel: viewModel,
                                handleEmailSelection: { email in
                                    viewModel.taggedEmails.append(email)
                                    taggableTextview.handleSelectedEmail(email)
                                }
                            )
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            viewModel.emailViewHeight = geometry.size.height
                                        }
                                }
                            )
                            .offset(y: -(viewModel.emailViewHeight - 10))
                        }
                    }
                    
                    ,
                    alignment: .top
                )
            

        }
        .padding()
    }
}

//            Text("Tokens:")
//            Text("\(taggableTextview.postableText())")
