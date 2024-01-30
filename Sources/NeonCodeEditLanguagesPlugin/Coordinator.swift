import Cocoa
import STTextView

import Neon
import TreeSitterClient
import SwiftTreeSitter

import CodeEditLanguages

public class Coordinator {
    private(set) var highlighter: Neon.Highlighter?
    private let language: CodeLanguage
    private let tsLanguage: SwiftTreeSitter.Language
    private let tsClient: TreeSitterClient
    private var prevViewportRange: NSTextRange?

    init(textView: STTextView, theme: Theme, language: CodeLanguage) {
        tsLanguage = language.language!
        self.language = language

        tsClient = try! TreeSitterClient(language: tsLanguage) { codePointIndex in
            guard let location = textView.textContentManager.location(at: codePointIndex),
                  let position = textView.textContentManager.position(location)
            else {
                return .zero
            }

            return Point(row: position.row, column: position.column)
        }


        tsClient.invalidationHandler = { [weak self] indexSet in
            DispatchQueue.main.async {
                self?.highlighter?.invalidate(.set(indexSet))
            }
        }

        // set textview default font to theme default font
        textView.font = theme.tokens[.default]?.font?.value ?? textView.font
        
        DispatchQueue.main.async {
            self.highlighter = Neon.Highlighter(textInterface: STTextViewSystemInterface(textView: textView) { neonToken in
                var attributes: [NSAttributedString.Key: Any] = [:]
                if let tvFont = textView.font {
                    attributes[.font] = tvFont
                }
                
                if let themeValue = theme.tokens[TokenName(neonToken.name)] {
                    attributes[.foregroundColor] = themeValue.color.value
                    
                    if let font = themeValue.font?.value {
                        attributes[.font] = font
                    }
                } else if let themeValue = theme.tokens[.default]{
                    attributes[.foregroundColor] = themeValue.color.value
                    
                    if let font = themeValue.font?.value {
                        attributes[.font] = font
                    }
                }
                
                return !attributes.isEmpty ? attributes : nil
            }, tokenProvider: self.tokenProvider(textContentManager: textView.textContentManager))
        }

        // initial parse of the whole content
        tsClient.willChangeContent(in: NSRange(textView.textContentManager.documentRange, in: textView.textContentManager))
        tsClient.didChangeContent(in: NSRange(textView.textContentManager.documentRange, in: textView.textContentManager), delta: textView.textContentManager.length, limit: textView.textContentManager.length, readHandler: Parser.readFunction(for: textView.textContentManager.attributedString(in: nil)?.string ?? ""), completionHandler: {})
    }

    private func tokenProvider(textContentManager: NSTextContentManager) -> Neon.TokenProvider? {
        guard let highlightsQuery = try? tsLanguage.query(contentsOf: language.queryURL!) else {
            return nil
        }

        return tsClient.tokenProvider(with: highlightsQuery) { range, _ in
            guard range.isEmpty == false else { return nil }
            return textContentManager.attributedString(in: NSTextRange(range, provider: textContentManager))?.string
        }
    }

    func updateViewportRange(_ range: NSTextRange?) {
        if range != prevViewportRange {
            DispatchQueue.main.async {
                self.highlighter?.visibleContentDidChange()
            }
        }
        prevViewportRange = range
    }

    func willChangeContent(in range: NSRange) {
        tsClient.willChangeContent(in: range)
    }

    func didChangeContent(_ textContentManager: NSTextContentManager, in range: NSRange, delta: Int, limit: Int) {
        /// TODO: Instead get the *whole* string over and over (can be expensive for large documents)
        /// implement maybe a reader function that read what needed only (is it possible?)
        if let str = textContentManager.attributedString(in: nil)?.string {
            let readFunction = Parser.readFunction(for: str)
            tsClient.didChangeContent(in: range, delta: delta, limit: limit, readHandler: readFunction, completionHandler: {})
        }

    }
}
