//
//  TokenHighlighterManager.swift
//  Mentions
//
//  Created by Ankit Sachan on 21/11/24.
//

import Foundation


class TokenHighlighterManager {
    private let highlighters: [TokenHighlighter]
    
    init(highlighters: [TokenHighlighter]) {
        self.highlighters = highlighters
    }
    
    func applyHighlights(to text: String, tokens: [TaggableTextViewToken]) -> NSAttributedString {
            let attributedText = NSMutableAttributedString(string: text)
            tokens.forEach { token in
                highlighters.first { $0.canHighlight(token) }?.highlight(token, in: attributedText)
            }
            return attributedText
        }
}
