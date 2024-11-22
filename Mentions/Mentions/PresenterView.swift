//
//  PresenterView.swift
//  Mentions
//
//  Created by Ankit Sachan on 21/11/24.
//

import SwiftUI

struct PresenterView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // TaggableTextEditorView on the left
            TaggableTextEditorView()
                .frame(maxWidth: .infinity) // Allow it to take as much space as possible
            
            
            // Post button on the right
            Button(action: {
                // Handle post action here
                print("Post button tapped")
            }) {
                Text("Post")
                    .fontWeight(.bold)
                    .padding()
                    .frame(minWidth: 80, minHeight: 40) // Ensure a minimum size for the button
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}


