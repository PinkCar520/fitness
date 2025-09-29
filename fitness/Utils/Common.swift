import SwiftUI

func openUrl(urlString: String) {
    guard let url = URL(string: urlString) else {
        return
    }

    if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
