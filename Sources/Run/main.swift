import Foundation
import Interfaces

switch config.interface {
case .Shell:
    Shell.run()
case .ViberBot:
    ViberBot.run()
}
