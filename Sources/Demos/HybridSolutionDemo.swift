#!/usr/bin/env swift

import Foundation
import AppKit
import LibHangul

print("LibHangul Swift 하이브리드 솔루션 데모")
print("=====================================\n")

// MARK: - 라이브러리 레벨 API
print("1. 라이브러리 레벨 API 사용법:")
print("   - 앱이 직접 입력 컨텍스트 관리")
print("   - NSTextInputClient 프로토콜 구현")

class TextEditor {
    private let inputContext = LibHangul.createInputContext(keyboard: "2")

    func handleKeyInput(_ keyCode: Int) -> Bool {
        if inputContext.process(keyCode) {
            // 커밋된 텍스트 처리
            let committed = inputContext.getCommitString()
            if !committed.isEmpty {
                insertText(committed)
            }

            // 사전 편집 텍스트 표시
            let preedit = inputContext.getPreeditString()
            showPreeditText(preedit)

            return true
        }
        return false
    }

    private func insertText(_ text: [UCSChar]) {
        print("   텍스트 삽입: \(text)")
    }

    private func showPreeditText(_ text: [UCSChar]) {
        print("   조합중 텍스트: \(text)")
    }
}

// MARK: - 입력기 앱 레벨 API
print("\n2. 입력기 앱 레벨 API 사용법:")
print("   - 시스템 레벨에서 입력 처리")
print("   - 모든 앱에 자동 적용")

class HangulInputMethod {
    private let inputContext = LibHangul.createInputContext(keyboard: "2")
    private var currentClient: NSTextInputClient?

    // macOS IMKInputController 구현
    func handleEvent(_ event: NSEvent) -> Bool {
        guard let keyCode = event.characters?.unicodeScalars.first?.value else {
            return false
        }

        // 한글 입력 처리
        if inputContext.process(Int(keyCode)) {
            // 현재 포커스된 앱에 텍스트 삽입
            if let client = currentClient {
                insertTextToClient(client)
            }
            return true
        }

        return false
    }

    private func insertTextToClient(_ client: NSTextInputClient) {
        let committed = inputContext.getCommitString()
        if !committed.isEmpty {
            let text = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })
            client.insertText(text, replacementRange: NSRange(location: NSNotFound, length: 0))
        }
    }
}

// MARK: - 하이브리드 접근
print("\n3. 하이브리드 접근:")
print("   - 라이브러리: 기본 엔진")
print("   - 앱: 사용자 친화적 인터페이스")

class HangulIMEApp {
    // 라이브러리 레벨 엔진
    private let inputEngine = LibHangul.createInputContext(keyboard: "2")

    func processInput(_ input: String) -> String {
        // 라이브러리 엔진으로 처리
        let result = inputEngine.processText(input)
        return result
    }
}

// 간단한 결과 구조체
struct InputResult {
    let text: String
    let hanjaCandidates: [String]?
}

print("\n✅ 하이브리드 접근이 가장 이상적입니다:")
print("   1. 라이브러리: 코어 엔진, 재사용성, 유연성")
print("   2. 앱: 사용자 인터페이스, 시스템 통합, 관리 기능")
print("   3. 결합: 최상의 사용자 경험")
