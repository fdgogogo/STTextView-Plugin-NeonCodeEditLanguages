import Cocoa

import STTextView

import CodeEditLanguages

public struct NeonCodeEditLanguagesPlugin: STPlugin {
    private let theme: Theme
    private let language: CodeLanguage

    public init(theme: Theme = .default, language: CodeLanguage) {
        self.theme = theme
        self.language = language
    }

    public func setUp(context: any Context) {

        context.events.onWillChangeText { affectedRange in
            let range = NSRange(affectedRange, in: context.textView.textContentManager)
            context.coordinator.willChangeContent(in: range)
        }

        context.events.onDidChangeText { affectedRange, replacementString in
            guard let replacementString else { return }

            let range = NSRange(affectedRange, in: context.textView.textContentManager)
            context.coordinator.didChangeContent(context.textView.textContentManager, in: range, delta: replacementString.utf16.count - range.length, limit: context.textView.textContentManager.length)
        }

        context.events.onDidLayoutViewport { viewportRange in
            context.coordinator.updateViewportRange(viewportRange)
        }
    }

    public func makeCoordinator(context: CoordinatorContext) -> Coordinator {
        Coordinator(textView: context.textView, theme: theme, language: language)
    }

}

