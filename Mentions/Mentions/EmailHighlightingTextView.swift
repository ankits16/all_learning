//
//  EmailHighlightingTextView.swift
//  Mentions
//
//  Created by Ankit Sachan on 19/11/24.
//

import SwiftUI

struct EmailHighlightingTextView: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: EmailHighlightingTextView
        
        init(parent: EmailHighlightingTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            let currentSelectedRange = textView.selectedRange
            parent.text = textView.text
            parent.highlightEmails(in: textView)
            textView.selectedRange = currentSelectedRange
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Detect if the backspace key was pressed
            let currentText = textView.text as NSString
            let currentCursorPosition = range.location
            
            // Check if the cursor is within an email range
            if let emailRange = self.emailRangeContainingCursor(text: currentText, cursorPosition: currentCursorPosition) {
                // Delete the entire email range
                let updatedText = currentText.replacingCharacters(in: emailRange, with: text)
                textView.text = updatedText
                
                // Update the binding and re-highlight emails
                parent.text = updatedText
                parent.highlightEmails(in: textView)
                
                // Set the cursor position after the deleted email
                textView.selectedRange = NSRange(location: text.isEmpty ?  emailRange.location : emailRange.location + 1, length: 0)
                return false // Prevent the default backspace behavior
            }
            return true
        }
        
        // Helper function to find the range of the email containing the cursor
        private func emailRangeContainingCursor(text: NSString, cursorPosition: Int) -> NSRange? {
            let emailRegex = try! NSRegularExpression(
                pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
                options: []
            )
            let range = NSRange(location: 0, length: text.length)
            let matches = emailRegex.matches(in: text as String, options: [], range: range)
            
            for match in matches {
                // Check if the cursor is within the email range
                if NSLocationInRange(cursorPosition, match.range) {
                    return match.range
                }
            }
            return nil
        }
    }

    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.attributedText = NSAttributedString(string: text)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Save the current cursor position
        let currentSelectedRange = uiView.selectedRange
        
        // Update the text and highlight emails
        uiView.text = text
        highlightEmails(in: uiView)
        
        // Restore the cursor position
        uiView.selectedRange = currentSelectedRange
    }

    func highlightEmails(in textView: UITextView) {
        let attributedText = NSMutableAttributedString(string: text)
        
        let emailRegex = try! NSRegularExpression(
            pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
            options: []
        )
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = emailRegex.matches(in: text, options: [], range: range)

        for match in matches {
            // Add a blue foreground color for the text
            attributedText.addAttribute(.foregroundColor, value: UIColor.blue, range: match.range)
            
            // Add a background color to simulate a bubble
            attributedText.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.3), range: match.range)
            
            // Optionally, you can add a corner radius using a custom text container (only visually simulated)
            // UITextView's attributed strings can't directly add true corner radii to backgrounds.
        }
        
        textView.attributedText = attributedText
    }
    

}

//struct ContentView: View {
//    @State private var text = "Editable SwiftUI TextView"
//    
//    var body: some View {
//        VStack {
//            EmailHighlightingTextView(text: $text)
//                .frame(height: 200)
//                .border(Color.gray, width: 1)
//            Text("Text: \(text)")
//        }
//        .padding()
//    }
//}

