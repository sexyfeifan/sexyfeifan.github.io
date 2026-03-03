import AppKit
import SwiftUI

struct NativeInputField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> FocusTextField {
        let field = FocusTextField(string: text)
        field.placeholderString = placeholder
        field.isEditable = true
        field.isSelectable = true
        field.isBezeled = true
        field.isBordered = true
        field.drawsBackground = true
        field.focusRingType = .default
        field.lineBreakMode = .byTruncatingTail
        field.delegate = context.coordinator
        field.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        field.target = context.coordinator
        field.action = #selector(Coordinator.commit)
        return field
    }

    func updateNSView(_ nsView: FocusTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeInputField

        init(_ parent: NativeInputField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        @objc func commit() {}
    }
}

final class FocusTextField: NSTextField {
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        window?.makeFirstResponder(self)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.window?.firstResponder == nil {
                self.window?.makeFirstResponder(self)
            }
        }
    }
}
