#!/usr/bin/env swift

import LibHangul

// LibHangul 한자 기능 데모
print("LibHangul 한자 기능 데모")
print("=======================\n")

// 1. 한자 사전 로드
print("1. 한자 사전 로드:")
if let hanjaTable = LibHangul.loadHanjaTable() {
    print("✅ 한자 사전 로드 성공")
} else {
    print("❌ 한자 사전 로드 실패 (기본 사전이 없음)")
    print("   테스트용 사전을 생성합니다...")

    // 테스트용 간단한 사전 데이터 생성
    let testData = """
    # 테스트 한자 사전
    한자:漢字:한자
    한국:韓國:한국
    삼국사기:三國史記:삼국사기
    """

    let tempDir = FileManager.default.temporaryDirectory
    let tempFile = tempDir.appendingPathComponent("test-hanja.txt")

    try? testData.write(to: tempFile, atomically: true, encoding: .utf8)

    if let hanjaTable = LibHangul.loadHanjaTable(filename: tempFile.path) {
        print("✅ 테스트 사전 로드 성공")

        // 2. 정확한 매칭 검색
        print("\n2. 정확한 매칭 검색:")
        if let results = LibHangul.searchHanja(table: hanjaTable, key: "한자") {
            print("검색된 항목: \(results.getSize())개")
            for i in 0..<results.getSize() {
                if let key = results.getNthKey(i),
                   let value = results.getNthValue(i),
                   let comment = results.getNthComment(i) {
                    print("  키: \(key), 한자: \(value), 설명: \(comment)")
                }
            }
        } else {
            print("검색 결과 없음")
        }

        // 3. 접두사 매칭 검색
        print("\n3. 접두사 매칭 검색 (삼국으로 시작하는 단어):")
        if let results = LibHangul.searchHanjaPrefix(table: hanjaTable, key: "삼국") {
            print("검색된 항목: \(results.getSize())개")
            for i in 0..<results.getSize() {
                if let key = results.getNthKey(i),
                   let value = results.getNthValue(i) {
                    print("  키: \(key), 한자: \(value)")
                }
            }
        } else {
            print("검색 결과 없음")
        }

        // 4. 접미사 매칭 검색
        print("\n4. 접미사 매칭 검색 (국으로 끝나는 단어):")
        if let results = LibHangul.searchHanjaSuffix(table: hanjaTable, key: "국") {
            print("검색된 항목: \(results.getSize())개")
            for i in 0..<results.getSize() {
                if let key = results.getNthKey(i),
                   let value = results.getNthValue(i) {
                    print("  키: \(key), 한자: \(value)")
                }
            }
        } else {
            print("검색 결과 없음")
        }

    } else {
        print("❌ 테스트 사전 로드 실패")
    }
}
else {
    print("❌ 한자 사전 로드 실패")
}

// 5. 한자 호환성 변환
print("\n5. 한자 호환성 변환:")
var hanjaChars: [UCSChar] = [0x4E00, 0x4E8C] // 일, 이
var hangulChars: [UCSChar] = [0x1100, 0x1102] // ㄱ, ㄷ

let converted = LibHangul.convertHanjaToCompatibility(hanja: &hanjaChars, hangul: hangulChars)
print("변환된 문자 수: \(converted)")

// 6. 통합 형태 변환
print("\n6. 통합 형태 변환:")
var compatChars: [UCSChar] = [0xF900, 0xF901] // 호환성 일, 이
let unified = LibHangul.convertHanjaToUnified(&compatChars)
print("통합된 문자 수: \(unified)")

print("\n한자 기능 데모 완료!")
