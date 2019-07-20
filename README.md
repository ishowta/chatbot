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
1. Copy `./config-sample.plist` to `./config.plist` and fill it
1. If you use XCode, add `config.plist` to `Copy Bundle Resource Phase` for each target using config

## Run
- `swift build`
- `swift run`

## Reference
- [Viber REST API](https://developers.viber.com/docs/api/rest-bot-api/)

## Todo
- ViberAPIの未実装の部分を書く
- KNPのSwiftラッパーを書く
- Refactoring
- Make documentation
