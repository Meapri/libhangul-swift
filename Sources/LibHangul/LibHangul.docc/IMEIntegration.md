# 입력기 연동과 조합 밑줄 처리

LibHangul 엔진을 실제 입력기(IME)에 연결하는 방법과, 조합 중 글자 아래의 밑줄을 다루는 방법을 설명합니다.

## 개요

LibHangul은 **순수 조합 엔진**입니다. 화면에 아무것도 그리지 않으며, 호스트에 두 가지 문자열만 넘깁니다.

- **조합 중 문자열(preedit)** — `getPreeditString()`. 아직 확정되지 않은, 계속 바뀔 수 있는 글자(예: `ㄱ` → `가` → `각`).
- **확정 문자열(commit)** — `getCommitString()` / `flush()`. 음절 경계를 넘어 더 이상 바뀌지 않는 글자.

입력기(InputMethodKit, 키보드 확장 등)는 이 `preedit`를 화면에 **"마크된 텍스트(marked text)"**로 표시하고, 음절이 확정되면 `commit`을 문서에 삽입합니다.

```
[키 입력] → LibHangul 엔진 → preedit:[UCSChar]  ──┐
                            → commit:[UCSChar] ──┤
                                                  ▼
                              입력기/OS 텍스트 시스템이 표시
                              (preedit = 마크된 텍스트, 밑줄은 여기서 그려짐)
```

## 조합 중 글자 아래의 밑줄은 누가 그리는가

> Important: 조합 중 글자 아래에 보이는 밑줄은 **엔진이 그리는 것이 아닙니다.** 호스트 텍스트 시스템(AppKit/TextKit, UIKit 등)이 *마크된 텍스트*를 표시할 때 기본 속성으로 긋습니다.

따라서 한글 조합 로직이나 ``HangulOutputMode``로는 밑줄을 끌 수 없습니다(`HangulOutputMode`는 preedit에 합성 음절 `가`를 담을지 낱자모 `ㄱㅏ`를 담을지만 결정하며, 표시 스타일과 무관합니다). 밑줄은 **입력기 연동 계층에서 마크된 텍스트의 속성**으로 제어합니다.

## macOS: InputMethodKit에서 밑줄 끄기

`IMKInputController`에서 마크된 텍스트를 설정할 때, 평문 대신 **밑줄 없는 `NSAttributedString`**을 넘깁니다.

```swift
import InputMethodKit
import LibHangul

final class MyInputController: IMKInputController {
    private let context = LibHangul.createThreadSafeInputContext(keyboard: "2")

    private func updateMarkedText(client: IMKTextInput) {
        let preedit = context.getPreeditString()
        let string = String(preedit.compactMap { UnicodeScalar($0) }.map { Character($0) })

        // 밑줄 없이 마크된 텍스트 표시
        let attributed = NSAttributedString(string: string, attributes: [
            .underlineStyle: 0        // 0 = 밑줄 없음
            // 필요하면 밑줄 대신 배경색으로 강조:
            // .backgroundColor: NSColor.selectedTextBackgroundColor
        ])

        client.setMarkedText(
            attributed,
            selectionRange: NSRange(location: string.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: 0)
        )
    }

    private func commit(client: IMKTextInput) {
        let committed = context.getCommitString()
        guard !committed.isEmpty else { return }
        let string = String(committed.compactMap { UnicodeScalar($0) }.map { Character($0) })
        client.insertText(string, replacementRange: NSRange(location: NSNotFound, length: 0))
    }
}
```

또는 `IMKInputController`의 `compositionAttributesAtRange:`를 오버라이드해 밑줄 없는 속성을 주입하는 방법도 있습니다.

> Warning: **모든 앱에서 밑줄이 사라지는 것은 보장되지 않습니다.** `.underlineStyle = 0`은 협조적인 클라이언트만 존중합니다. 표준 TextKit 뷰, 웹 브라우저, 터미널, Electron 기반 앱 등은 자체 밑줄을 강제해 이 속성을 무시할 수 있습니다. 앱 전반에 걸친 확실한 제거는 불가능합니다.

## iOS: 호스트 뷰의 markedTextStyle

호스트 텍스트 뷰(`UITextView` 등 `UITextInput` 채택)가 마크된 텍스트를 그리는 방식은 `markedTextStyle`로 제어합니다.

```swift
textView.markedTextStyle = [
    .underlineStyle: 0        // 밑줄 제거
]
```

> Note: `markedTextStyle = nil`은 "스타일 없음"이 아니라 **기본 스타일(밑줄 복귀)**을 의미하므로 주의하세요. 또한 `.underlineStyle`을 이용한 밑줄 제거는 공식 계약 API가 아닌 사실상의 관행이라, iOS 버전·뷰 종류에 따라 동작이 달라질 수 있습니다.

> Warning: **커스텀 키보드 확장(`UIInputViewController`)은 호스트의 `markedTextStyle`에 접근할 수 없습니다.** `UITextDocumentProxy.setMarkedText(_:selectedRange:)`로 마크된 텍스트를 *요청*할 수는 있어도, 그 밑줄을 어떻게 그릴지는 호스트가 결정합니다.

## 하지 말아야 할 것: 중간 상태를 커밋해 밑줄 숨기기

밑줄을 피하려고 preedit를 두지 않고 **매 키 입력마다 확정(commit)**하는 우회로가 있습니다. 마크된 텍스트가 없으니 밑줄도 없습니다. 그러나 한글에는 **권장하지 않습니다.**

- 한글 조합은 본질적으로 다중 키 입력이며 재진입적입니다. 한 음절(`ㄱ` → `가` → `각` → `간`)은 여러 키에 걸쳐 *제자리에서* 변합니다. 중간 상태를 확정하면 **음절 내 편집(백스페이스 포함)을 잃습니다.**
- 확정된 텍스트는 엔진을 떠납니다(`getCommitString()`은 읽으면서 비웁니다). 다시 고치려면 호스트 문서에서 지우고 재입력해야 합니다.
- `replacementRange`로 덮어쓰는 방식은 가능하지만 이는 **호스트/`NSTextInputClient` 메커니즘**이지 엔진의 책임이 아니며, 불완전한 클라이언트에서 깨지고 실행 취소 단위·자동 수정·접근성을 망가뜨립니다.

요약하면, 직접 커밋은 장식(밑줄)을 위해 입력 정확성을 맞바꾸는 잘못된 계층의 해법입니다.

## 책임 경계

| 관심사 | 소유 주체 |
|---|---|
| 무엇이 preedit/commit인가, 음절 flush 시점, 음절 경계 | **LibHangul 엔진** (``HangulInputContext``) |
| preedit를 어떻게 표시하는가 — 마크된 텍스트, 밑줄, 강조, `replacementRange` | **입력기 / OS 텍스트 시스템** |

밑줄 제거는 명백히 입력기 쪽 작업입니다. 엔진은 *무엇이* 조합 중인지(``HangulInputContext/getPreeditString()``)까지만 책임지며, *어떻게* 보여줄지는 호스트가 결정합니다.
