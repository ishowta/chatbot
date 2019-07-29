# Chatbot

## Require
- swift
- python3
- ruby
- xcodeproj (ruby gem)
- cmake (for KNP)
- libz-dev (for KNP)
- libsqlite3-dev (for SQLite.swift)

## Setup
1. Install required libraries
1. Install Python library
    - `pip3 install -r requirements.txt`
1. Install KNP
    - `./install_knp.sh /path/to/install`
1. Copy `config-sample.plist` to `config.plist` and fill it

## Install or Update package
### XCode
1. (Edit Package.swift)
1. `./update.sh`
### Swift command line
1. (Edit Package.swift)
1. `swift build`

## Run
- `swift run`

## REPL
1. `swift build`
1. `swift -I .build/debug -L .build/debug -lchatbot`

## Documents
- `./make_doc.sh`
- open `docs/`

## Tree
```bash
.
├── Package.resolved # Swiftのライブラリの依存関係？を示す自動生成されるファイル
├── Package.swift # Swiftの設定ファイル（Swiftのライブラリーはここに追加する）
├── README.md
├── Sources
│   ├── Bot # チャットボット本体
│   │   ├── Algorithms
│   │   │   ├── Actor # 行動選択のアルゴリズム
│   │   │   │   └── datehelper.swift # Actorで使う日付に関するUtil
│   │   │   ├── DomainSelector # ドメイン選択のアルゴリズム
│   │   │   │   ├── domainselector.swift # ドメイン選択のプロトコル
│   │   │   │   ├── ds_onedomain.swift # ドメインを一つだけ使う
│   │   │   │   ├── ds_simple.swift # １ターンごとに選択する
│   │   │   │   └── ds_stack.swift # スタックでドメインを管理する
│   │   │   ├── Generator # 言語生成のアルゴリズム
│   │   │   └── Recognizer # 言語理解のアルゴリズム
│   │   │       └── case_analysis.swift # 格解析を使った言語理解	
│   │   ├── Models # 内部で用いるDBのモデル
│   │   │   ├── Plan.swift # Plan Managerで使う予定モデル
│   │   │   ├── User.swift # ユーザーを記憶するユーザーモデル
│   │   │   └── model.swift # モデルのプロトコル・Util
│   │   ├── Modules # モジュール
│   │   │   ├── PlanManager # 予定管理モジュール
│   │   │   │   ├── planmanager.swift
│   │   │   │   ├── pm_actor.swift
│   │   │   │   ├── pm_generator.swift
│   │   │   │   └── pm_recognizer.swift
│   │   │   ├── WeatherReporter # 天気レポートモジュール
│   │   │   │   ├── weatherreporter.swift
│   │   │   │   ├── wr_actor.swift
│   │   │   │   ├── wr_generator.swift
│   │   │   │   └── wr_recognizer.swift
│   │   │   ├── module.swift # モジュールのプロトコル
│   │   │   └── stackplanmodule.swift # プランスタックを用いるモジュールのプロトコル
│   │   ├── bot.swift # チャットボット本体
│   │   └── extensions.swift # Util
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
│
├── chatbot.xcodeproj # XCodeの設定ファイルなど
│   │
│   ...
│
├── config-sample.plist # 設定ファイルのサンプル
├── config.plist # 設定ファイル(ignore)
├── db.sqlite3 # SQLite.swiftで使われているDB(ignore)
├── gitignore.txt
├── install_knp.sh # KNP(構文・意味解析器)のインストールスクリプト
├── make_doc.sh # ドキュメントを作成するスクリプト
└── requirements.txt # Pythonライブラリーのリスト


```

## Reference
- [Viber REST API](https://developers.viber.com/docs/api/rest-bot-api/)
- [KNP](http://nlp.ist.i.kyoto-u.ac.jp/index.php?KNP)
