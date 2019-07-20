import Interfaces

switch CONFIG["interface"] as! String {
case "shell":
    Shell.run()
case "viberbot":
    ViberBot.run()
default:
    fatalError("インターフェイスが指定されていません。")
}
