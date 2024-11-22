//
//  TokenHighlighter.swift
//  Mentions
//
//  Created by Ankit Sachan on 21/11/24.
//

import Foundation
import Foundation
import UIKit
import SwiftUI

protocol TokenHighlighter {
    func canHighlight(_ token: TaggableTextViewToken) -> Bool
    func highlight(_ token: TaggableTextViewToken, in attributedText: NSMutableAttributedString)
}

class DefaultTokenHighlighter: TokenHighlighter {
    @ObservedObject var viewModel: TaggableTextEditorViewModel
    
    init(viewModel:TaggableTextEditorViewModel) {
        self.viewModel = viewModel
    }
    
    func canHighlight(_ token: TaggableTextViewToken) -> Bool {
        return !token.isCurrentEditingToken && !(viewModel.taggedEmails.contains(token.text))
    }
    
    func highlight(_ token: TaggableTextViewToken, in attributedText: NSMutableAttributedString) {
        attributedText.addAttribute(.foregroundColor, value: UIColor.blue, range: token.range)
        attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: token.range)
    }
}

class EmailTokenHighlighter: TokenHighlighter {
    @ObservedObject var viewModel: TaggableTextEditorViewModel
    
    init(viewModel:TaggableTextEditorViewModel) {
        self.viewModel = viewModel
    }
    
    func canHighlight(_ token: TaggableTextViewToken) -> Bool {
        viewModel.taggedEmails.contains(token.text)
    }
    
    func highlight(_ token: TaggableTextViewToken, in attributedText: NSMutableAttributedString) {
        attributedText.addAttribute(.foregroundColor, value: UIColor.brown, range: token.range)
        attributedText.addAttribute(.backgroundColor, value: UIColor.lightGray.withAlphaComponent(0.3), range: token.range)
        attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: token.range)
    }
}

class CurrentEditTokenHighlighter: TokenHighlighter {
    func canHighlight(_ token: TaggableTextViewToken) -> Bool {
        return token.isCurrentEditingToken
    }
    
    func highlight(_ token: TaggableTextViewToken, in attributedText: NSMutableAttributedString) {
        attributedText.addAttribute(.foregroundColor, value: UIColor.red, range: token.range)
        attributedText.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 16), range: token.range)
    }
}
