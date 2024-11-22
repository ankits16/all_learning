//
//  TaggableTextView.swift
//  Mentions
//
//  Created by Ankit Sachan on 21/11/24.
//

import Foundation
import SwiftUI

struct TaggableTextViewToken: Identifiable {
    var id: UUID = UUID()
    var text: String
    var range: NSRange
    var isCurrentEditingToken: Bool
    
    func isTokenAnEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: text)
    }
}


struct TaggableTextView: UIViewRepresentable {
    @ObservedObject var viewModel: TaggableTextEditorViewModel
    
    var coordinatorInstanceCallback: ((Coordinator) -> Void)?
    
    func handleSelectedEmail(_ selectedEmail: String) {
        print("Selected email: \(selectedEmail)")
        guard let currentToken = viewModel.currentEditingToken else {
            print("No current token found for replacement")
            return
        }
        
        let nsRange = NSRange(location: currentToken.range.location + selectedEmail.count + 1, length: 0)
        print("<<< nsRange value: \(nsRange)>>>")
        
        // Schedule cursor movement to the main thread after the text update
        DispatchQueue.main.async {
            viewModel.showEmailListFlag = false
            if let range = Range(currentToken.range, in: viewModel.text) {
                viewModel.text.replaceSubrange(range, with: "\(selectedEmail) ")
                viewModel.cursorPositionAfterEmailSelection = nsRange
            }
        }
    }
    
    func postableText() -> String {
        let tokenManager = makeCoordinator().tokenManager
        var updatedText = viewModel.text
        let tokens = tokenManager.extractTokens(from: viewModel.text, currentCursorPositon: nil) // Extract all tokens
        for token in tokens {
            if token.isTokenAnEmail(),
               let emailIndex = viewModel.taggedEmails.firstIndex(of: token.text) {
                let formattedEmail = "@[\(token.text)](user:\(emailIndex))"
                updatedText = updatedText.replacingOccurrences(of: token.text, with: formattedEmail)
            }
        }
        return updatedText
    }
    
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.autocorrectionType = .no
        textView.text = viewModel.text.isEmpty ? "Type something here..." : viewModel.text
        textView.textColor = viewModel.text.isEmpty ? UIColor.lightGray : UIColor.black
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            let currentSelectedRange = uiView.selectedRange
            if uiView.text != viewModel.text {
                uiView.text = viewModel.text
            }
            context.coordinator.highlightTokens(in: uiView)
            
            if let unwrapped = viewModel.cursorPositionAfterEmailSelection {
                uiView.selectedRange = unwrapped
                viewModel.cursorPositionAfterEmailSelection = nil
                print("update cursor after email selection")
            }else{
                uiView.selectedRange = currentSelectedRange
                
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(
            self,
            tokenManager: TokenManager(viewModel: viewModel),
            highlighters: [
                DefaultTokenHighlighter(viewModel: viewModel),
                EmailTokenHighlighter(viewModel: viewModel),
                CurrentEditTokenHighlighter()
            ])
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TaggableTextView
        let tokenManager: TokenManager
        private let highlighters: [TokenHighlighter]
        
        init(_ parent: TaggableTextView, tokenManager: TokenManager, highlighters: [TokenHighlighter]) {
            self.parent = parent
            self.tokenManager = tokenManager
            self.highlighters = highlighters
        }
        
        private func checkIfTokenIsForMention(_ token: TaggableTextViewToken) -> Bool {
            return token.text.hasPrefix("@") && token.text.dropFirst().contains("@") == false
        }
        
        private func checkIfTokenIsEmailAndIsInTaggedEmail(_ token: TaggableTextViewToken) -> Bool {
            if token.isTokenAnEmail() {
                return parent.viewModel.taggedEmails.contains(token.text)
            } else {
                return false
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            let currentSelectedRange = textView.selectedRange
            parent.viewModel.text = textView.text
            highlightTokens(in: textView)
            textView.selectedRange = currentSelectedRange
            
            // Check if the current token starts with '@'
            if let currentToken = tokenManager.extractCurrentToken(from: textView.text, cursorPosition: currentSelectedRange.location),
               tokenManager.checkIfTokenIsMention(currentToken){
                parent.viewModel.currentEditingToken = currentToken
                print("<<<<<< parent.currentEditingToken: \(parent.viewModel.currentEditingToken?.text ?? "No token")")
                let searchKey = String(currentToken.text.dropFirst()) // Remove '@' for API call
                DispatchQueue.main.async {
                    self.parent.viewModel.showEmailListFlag = true
                    self.parent.viewModel.searchText = searchKey
                }
            } else {
                DispatchQueue.main.async {
                    self.parent.viewModel.showEmailListFlag = false
                    self.parent.viewModel.searchText = ""
                }
            }
        }
        
        
        func highlightTokens(in textView: UITextView) {
            let attributedText = NSMutableAttributedString(string: textView.text)
            if let currentRange = textView.selectedTextRange {
                let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: currentRange.start)
                let tokens = tokenManager.extractTokens(from: textView.text, currentCursorPositon: cursorPosition)
                tokens.forEach { token in
                    highlighters.first(where: { $0.canHighlight(token) })?.highlight(token, in: attributedText)
                }
            }
            
            textView.attributedText = attributedText
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Detect if the backspace key was pressed
            let currentText = textView.text as NSString
            let currentCursorPosition = range.location
            
            // Check if the cursor is within a token range, and not at the start of the token
            if let token = tokenManager.tokenContainingCursor(text: currentText as String, cursorPosition: currentCursorPosition) {
                if checkIfTokenIsEmailAndIsInTaggedEmail(token) && currentCursorPosition > token.range.location {
                    // Replace/delete the entire token if it is an email and the cursor is not at the start of the token
                    let updatedText = currentText.replacingCharacters(in: token.range, with: text)
                    textView.text = updatedText
                    
                    // Update the binding and re-highlight tokens
                    parent.viewModel.text = updatedText
                    self.highlightTokens(in: textView)
                    
                    // Set the cursor position after the deleted/replaced token
                    textView.selectedRange = NSRange(location: text.isEmpty ? token.range.location : token.range.location + 1, length: 0)
                    return false // Prevent the default behavior
                }
            }
            
            // Allow default behavior for non-email tokens or if the cursor is at the start of the token
            return true
        }
    }
}
