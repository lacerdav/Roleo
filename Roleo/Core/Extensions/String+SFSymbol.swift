import UIKit

extension String {
    var validSFSymbolName: String {
        UIImage(systemName: self) == nil ? "sparkles" : self
    }
}
