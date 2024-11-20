import SwiftUI
import UIKit

struct Token: Identifiable {
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
    @Binding var text: String
    @Binding var showEmailListFlag: Bool
    @Binding var searchText: String
    @Binding var cursorPositionAfterEmailSelection: NSRange?
    @Binding var currentEditingToken: Token?
    @Binding var taggedEmails: [String]
    
    var coordinatorInstanceCallback: ((Coordinator) -> Void)?
    
    func handleSelectedEmail(_ selectedEmail: String) {
        print("Selected email: \(selectedEmail)")
        guard let currentToken = currentEditingToken else {
            print("No current token found for replacement")
            return
        }
        
        let tokenRange = currentToken.range
        let nsRange = NSRange(location: tokenRange.location + selectedEmail.count + 1, length: 0)
        print("<<< nsRange value: \(nsRange)>>>")
        
        // Schedule cursor movement to the main thread after the text update
        DispatchQueue.main.async {
            showEmailListFlag = false
            if let range = Range(tokenRange, in: text) {
                text.replaceSubrange(range, with: "\(selectedEmail) ")
                cursorPositionAfterEmailSelection = nsRange
            }
        }
    }

    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.autocorrectionType = .no
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            let currentSelectedRange = uiView.selectedRange
            if uiView.text != text {
                uiView.text = text
            }
            context.coordinator.highlightTokens(in: uiView)
            
            if let unwrapped = self.cursorPositionAfterEmailSelection {
                uiView.selectedRange = unwrapped
                self.cursorPositionAfterEmailSelection = nil
                print("update cursor after email selection")
            }else{
                uiView.selectedRange = currentSelectedRange
               
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TaggableTextView
        
        init(_ parent: TaggableTextView) {
            self.parent = parent
        }
        
        private func checkIfTokenIsForMention(_ token: Token) -> Bool {
            return token.text.hasPrefix("@") && token.text.dropFirst().contains("@") == false
        }
        
        private func checkIfTokenIsEmailAndIsInTaggedEmail(_ token: Token) -> Bool {
            if token.isTokenAnEmail() {
                return parent.taggedEmails.contains(token.text)
            } else {
                return false
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            let currentSelectedRange = textView.selectedRange
            parent.text = textView.text
            highlightTokens(in: textView)
            textView.selectedRange = currentSelectedRange
            
            // Check if the current token starts with '@'
            if let currentToken = extractCurrentEditingToken(from: textView.text, cursorPosition: currentSelectedRange.location),
               checkIfTokenIsForMention(currentToken){
                parent.currentEditingToken = currentToken
                print("<<<<<< parent.currentEditingToken: \(parent.currentEditingToken?.text ?? "No token")")
                let searchKey = String(currentToken.text.dropFirst()) // Remove '@' for API call
                DispatchQueue.main.async {
                    self.parent.showEmailListFlag = true
                    self.parent.searchText = searchKey
                }
            } else {
                DispatchQueue.main.async {
                    self.parent.showEmailListFlag = false
                    self.parent.searchText = ""
                }
            }
        }
        
        
        private func extractTokens(from text: String) -> [Token] {
            var tokens: [Token] = []
            var currentLocation = 0
            let taggedEmailsSet = Set(parent.taggedEmails) // Convert to set for faster lookup
            
            // Split the text by whitespace and keep track of indices
            let words = text.split { $0.isWhitespace }
            
            for word in words {
                var subTokens: [String] = []
                var wordString = String(word)
                
                // Check if the word contains any tagged email
                for email in taggedEmailsSet {
                    if let range = wordString.range(of: email) {
                        // Split the word by the email and add parts
                        let prefix = String(wordString[..<range.lowerBound])
                        let suffix = String(wordString[range.upperBound...])
                        
                        if !prefix.isEmpty {
                            subTokens.append(prefix)
                        }
                        subTokens.append(email)
                        if !suffix.isEmpty {
                            subTokens.append(suffix)
                        }
                        break // Only split by one email at a time
                    }
                }
                
                // If no tagged email found, keep the original word as a single token
                if subTokens.isEmpty {
                    subTokens.append(wordString)
                }
                
                // Convert subTokens to Token objects and add them to tokens list
                for subToken in subTokens {
                    if let range = text.range(of: subToken, options: .literal, range: text.index(text.startIndex, offsetBy: currentLocation)..<text.endIndex) {
                        let nsRange = NSRange(range, in: text)
                        tokens.append(Token(text: subToken, range: nsRange, isCurrentEditingToken: false))
                        currentLocation = nsRange.location + nsRange.length
                    }
                }
            }
            
            let tokensString = tokens.map { $0.text }.joined(separator: "+++")
            print("Tokens: \(tokensString)")
            
            return tokens
        }

        
        private func extractCurrentEditingToken(from text: String, cursorPosition: Int) -> Token? {
            let tokens = extractTokens(from: text)
            for token in tokens {
                if cursorPosition >= token.range.location && cursorPosition <= token.range.location + token.range.length {
                    return token
                }
            }
            return nil
        }
        
        func highlightTokens(in textView: UITextView) {
            let attributedText = NSMutableAttributedString(string: textView.text)
            var tokens = self.extractTokens(from: textView.text)
            
            if let currentRange = textView.selectedTextRange {
                let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: currentRange.start)
                
                for index in tokens.indices {
                    let token = tokens[index]
                    
                    // Check if the cursor is within the current token range
                    if cursorPosition > token.range.location && cursorPosition <= token.range.location + token.range.length {
                        print("Found current editing token: \(token.text)")
                        tokens[index].isCurrentEditingToken = true
                        attributedText.addAttribute(.foregroundColor, value: UIColor.red, range: token.range)
                        attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: token.range)
                    } else {
                        if checkIfTokenIsEmailAndIsInTaggedEmail(token) {
                            attributedText.addAttribute(.foregroundColor, value: UIColor.brown, range: token.range)
                            attributedText.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.3), range: token.range)
                            attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: token.range)
                        }else{
                            attributedText.addAttribute(.foregroundColor, value: UIColor.blue, range: token.range)
                            attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: token.range)
                        }
                        
                    }
                }
            }
            
            textView.attributedText = attributedText
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Detect if the backspace key was pressed
            let currentText = textView.text as NSString
            let currentCursorPosition = range.location

            // Check if the cursor is within a token range, and not at the start of the token
            if let token = self.tokenContainingCursor(text: currentText as String, cursorPosition: currentCursorPosition) {
                if checkIfTokenIsEmailAndIsInTaggedEmail(token) && currentCursorPosition > token.range.location {
                    // Replace/delete the entire token if it is an email and the cursor is not at the start of the token
                    let updatedText = currentText.replacingCharacters(in: token.range, with: text)
                    textView.text = updatedText

                    // Update the binding and re-highlight tokens
                    parent.text = updatedText
                    self.highlightTokens(in: textView)

                    // Set the cursor position after the deleted/replaced token
                    textView.selectedRange = NSRange(location: text.isEmpty ? token.range.location : token.range.location + 1, length: 0)
                    return false // Prevent the default behavior
                }
            }
            
            // Allow default behavior for non-email tokens or if the cursor is at the start of the token
            return true
        }

        private func tokenContainingCursor(text: String, cursorPosition: Int) -> Token? {
            let tokens = extractTokens(from: text)
            for token in tokens {
                // Check if the cursor is strictly within the token range (not at the start)
                if NSLocationInRange(cursorPosition, token.range) && cursorPosition > token.range.location {
                    return token
                }
            }
            return nil
        }

    }
}

struct ContentView: View {
    @State private var text: String = "Type something here..."
    @State private var tokens: [String] = []
    @State private var showEmailListFlag: Bool = false
    @State private var searchText: String = ""
    @State private var filteredEmails: [String] = []
    @State private var cursorPositionAfterEmailSelection: NSRange?
    @State private var currentEditingToken: Token?
    @State private var taggedEmails: [String] = []
    
    private var taggableTextview: TaggableTextView {
        TaggableTextView(
                text: $text,
                showEmailListFlag: $showEmailListFlag,
                searchText: $searchText,
                cursorPositionAfterEmailSelection : $cursorPositionAfterEmailSelection,
                currentEditingToken: $currentEditingToken,
                taggedEmails: $taggedEmails
            )
        }
    
    
    var body: some View {
        VStack {
            taggableTextview
                .frame(height: 200)
                .border(Color.gray, width: 1)
                .padding()
                .onChange(of: searchText) {
                    if showEmailListFlag {
                        fetchEmails(searchText: searchText)
                    }
                }
            if showEmailListFlag {
                List(filteredEmails, id: \.self) { email in
                    Text(email)
                        .onTapGesture {
                            taggedEmails.append(email)
                            taggableTextview.handleSelectedEmail(email)
                        }
                }
                .frame(maxHeight: 150) // Limit the height of the list
            }
            
            Text("Tokens:")
            ForEach(tokens, id: \.self) { token in
                Text(token)
                    .padding(.horizontal)
                    .background(Color.yellow.opacity(0.3))
                    .cornerRadius(5)
            }
        }
        .padding()
    }
    
    func fetchEmails(searchText: String) {
        // Simulate an API call to fetch emails
        print("<<<<<<< search for \(searchText)")
        let allEmails = ["user1@example.com", "user2@example.com", "test@example.com", "sample@example.com"]
        filteredEmails = allEmails.filter { $0.contains(searchText) }
    }
}

