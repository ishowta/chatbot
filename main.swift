import Interfaces

switch CONFIG["interface"] as! String {
case "shell":
    Shell.run()
case "viber":
    Viber.run()
default:
    fatalError("インターフェイスが指定されていません。")
}
