//
//  TokenManager.swift
//  Mentions
//
//  Created by Ankit Sachan on 21/11/24.
//

import Foundation
import SwiftUI

class TokenManager{
    @ObservedObject var viewModel: TaggableTextEditorViewModel
    
    init(viewModel:TaggableTextEditorViewModel) {
        self.viewModel = viewModel
    }
    
    func extractTokens(from text: String, currentCursorPositon: Int? = nil) -> [TaggableTextViewToken] {
        var tokens: [TaggableTextViewToken] = []
        var currentLocation = 0
        let taggedEmailsSet = Set(viewModel.taggedEmails)
        
        let words = text.split { $0.isWhitespace }
        for word in words {
            var subTokens: [String] = []
            let wordString = String(word)
            for email in taggedEmailsSet {
                if let range = wordString.range(of: email) {
                    let prefix = String(wordString[..<range.lowerBound])
                    let suffix = String(wordString[range.upperBound...])
                    if !prefix.isEmpty {
                        subTokens.append(prefix)
                    }
                    subTokens.append(email)
                    if !suffix.isEmpty {
                        subTokens.append(suffix)
                    }
                    break
                }
            }
            
            if subTokens.isEmpty {
                subTokens.append(wordString)
            }
            
            for subToken in subTokens {
                if let range = text.range(of: subToken, options: .literal, range: text.index(text.startIndex, offsetBy: currentLocation)..<text.endIndex) {
                    let nsRange = NSRange(range, in: text)
                    if let unwrappedCursorPosition = currentCursorPositon,
                        unwrappedCursorPosition > nsRange.location && unwrappedCursorPosition <= nsRange.location + nsRange.length {
                        tokens.append(TaggableTextViewToken(text: subToken, range: nsRange, isCurrentEditingToken: true))
                    }else{
                        tokens.append(TaggableTextViewToken(text: subToken, range: nsRange, isCurrentEditingToken: false))
                    }
                    
                    currentLocation = nsRange.location + nsRange.length
                }
            }
        }
        return tokens
    }
    
    func extractCurrentToken(from text: String, cursorPosition: Int) -> TaggableTextViewToken? {
        let tokens = extractTokens(from: text, currentCursorPositon: cursorPosition)
        return tokens.first(where: { $0.isCurrentEditingToken })
    }
    
    func checkIfTokenIsMention(_ token: TaggableTextViewToken) -> Bool {
        return token.text.hasPrefix("@") && token.text.dropFirst().contains("@") == false
        
    }
    
    func checkIfTokenIsTaggedEmail(_ token: TaggableTextViewToken) -> Bool {
        if token.isTokenAnEmail() {
            return viewModel.taggedEmails.contains(token.text)
        } else {
            return false
        }
    }
    
    func tokenContainingCursor(text: String, cursorPosition: Int) -> TaggableTextViewToken? {
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
