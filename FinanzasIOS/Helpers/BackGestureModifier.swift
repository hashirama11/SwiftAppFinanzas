import SwiftUI
import UIKit

extension View {
    func enableBackGesture() -> some View {
        modifier(BackGestureModifier())
    }
}

private struct BackGestureModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(BackGestureViewController())
    }
}

private struct BackGestureViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BackGestureHostController {
        BackGestureHostController()
    }

    func updateUIViewController(_ uiViewController: BackGestureHostController, context: Context) {
        uiViewController.enableSwipeBack()
    }
}

private final class BackGestureHostController: UIViewController {
    func enableSwipeBack() {
        guard let nav = navigationController else { return }
        nav.interactivePopGestureRecognizer?.isEnabled = true
        nav.interactivePopGestureRecognizer?.delegate = nil
    }
}
