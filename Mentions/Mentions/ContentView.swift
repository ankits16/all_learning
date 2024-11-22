import SwiftUI
import UIKit



struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Taggable Text Editor")
                    .font(.headline)
                    .padding()
                Spacer()
                PresenterView()
                    .frame(height: 100)
                    .background(Color.red)
            }
        }
    }
}

