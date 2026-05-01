import XCTest
@testable import LibHangul

func string(from chars: [UCSChar]) -> String {
    String(chars.compactMap { UnicodeScalar(HangulCharacter.jamoToCJamo($0)) }.map { Character($0) })
}

func XCTAssertEqual(
    _ expression1: @autoclosure () throws -> [UCSChar],
    _ expression2: @autoclosure () throws -> String,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let lhs = string(from: try expression1())
        let rhs = try expression2()
        XCTAssertEqual(lhs, rhs, message(), file: file, line: line)
    } catch {
        XCTFail("Unexpected thrown error: \(error)", file: file, line: line)
    }
}

func XCTAssertNotEqual(
    _ expression1: @autoclosure () throws -> [UCSChar],
    _ expression2: @autoclosure () throws -> String,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let lhs = string(from: try expression1())
        let rhs = try expression2()
        XCTAssertNotEqual(lhs, rhs, message(), file: file, line: line)
    } catch {
        XCTFail("Unexpected thrown error: \(error)", file: file, line: line)
    }
}
