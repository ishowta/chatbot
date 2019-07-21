# chatbot

## Require
- swift
- python3
- cmake (for KNP)
- libz-dev (for KNP)
- libsqlite3-dev (for SQLite.swift)

## Setup
1. Install Python library
    - `pip3 install -r requirements.txt`
1. Install KNP
    - `sudo ./install_knp.sh`
    - add path to bin and lib
1. Copy `./config-sample.plist` to `./config.plist` and fill it

## Update package
1. Edit Package.swift
1. If you use XCode, type `swift package generate-xcodeproj`
1. If you use XCode, add `config.plist` to `Copy Bundle Resource Phase` for each target using config

## Run
- `swift build`
- `swift run`

## Documents
- `./make_doc.sh`

## Tree
```bash
.
├── Package.resolved # Swiftのライブラリの依存関係？を示す自動生成されるファイル
├── Package.swift # Swiftの設定ファイル（Swiftのライブラリーはここに追加する）
├── Sources
│   ├── Bot # チャットボット本体
│   │   ├── Models # 内部で用いるDBのモデル
│   │   │   ├── Plan.swift
│   │   │   ├── User.swift
│   │   │   └── model.swift
│   │   ├── Modules # チャットボットが使うモジュール(ドメイン)を入れるところ
│   │   │   ├── PlanManager # 予定を立ててくれるモジュール
│   │   │   │   ├── planmanager.swift
│   │   │   │   ├── pm_actor.swift
│   │   │   │   ├── pm_generator.swift
│   │   │   │   └── pm_recognizer.swift
│   │   │   ├── WeatherReporter # 天気を教えてくれるモジュール
│   │   │   │   ├── weatherreporter.swift
│   │   │   │   ├── wr_actor.swift
│   │   │   │   ├── wr_generator.swift
│   │   │   │   └── wr_recognizer.swift
│   │   │   └── module.swift
│   │   ├── Algorithms
│   │   │   ├── Actor # 行動選択のアルゴリズムを入れるところ
│   │   │   ├── Generator # 言語生成のアルゴリズムを入れるところ
│   │   │   └── Recognizer # 言語理解のアルゴリズムを入れるところ
│   │   │       └── case_analysis.swift
│   │   ├── bot.swift # チャットボット
│   │   └── extensions.swift # Util
│   ├── Interfaces # チャットボットと会話するためのインターフェース
│   │   ├── interface.swift # インターフェースの設定
│   │   ├── shell.swift # 端末上で対話
│   │   └── viberbot.swift # Viberで対話
│   ├── Library
│   │   └── Viber # Viber APIのラッパー
│   │       ├── viber.swift # ↓のUser friendlyなラッパー　基本はこれを使う
│   │       └── viberapi.swift # Viber REST APIの生のラッパー
│   └── Run
│       └── main.swift # エントリー
├── Tests # テスト（未実装）
│   │
│   ...
├── chatbot.xcodeproj # XCodeの設定ファイル（ignore）
│   │
│   ...
├── config-sample.plist # 設定ファイルのサンプル
├── config.plist # 設定ファイル(ignore)
├── db.sqlite3 # SQLite.swiftで使われているDB(ignore)
├── gitignore.txt
├── install_knp.sh # KNP(構文・意味解析器)のインストールスクリプト
└── requirements.txt # Pythonライブラリーのリスト
```

## Reference
- [Viber REST API](https://developers.viber.com/docs/api/rest-bot-api/)

## Todo
- ViberAPIの未実装の部分を書く
- KNPのSwiftラッパーを書く
- Refactoring
- Make documentation
- Viber InterfaceがSIGINTに反応してくれないのを治す
- `Copy Bundle Resource Phase`が毎回リセットされるのをどうにかする
