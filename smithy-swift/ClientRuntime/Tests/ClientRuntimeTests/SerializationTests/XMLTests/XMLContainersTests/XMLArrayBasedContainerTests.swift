// TODO:: Add copyrights

import XCTest
@testable import ClientRuntime

class XMLArrayBasedContainerTests: XCTestCase {

    let box: XMLArrayBasedContainer = [XMLStringContainer("foo"), XMLIntContainer(42)]

    func testIsNull() {
        let box = XMLArrayBasedContainer()
        XCTAssertEqual(box.isNull, false)
    }

    func testUnbox() {
        XCTAssertEqual(box.count, 2)
        XCTAssertEqual(box[0] as? XMLStringContainer, XMLStringContainer("foo"))
        XCTAssertEqual(box[1] as? XMLIntContainer, XMLIntContainer(42))
    }

    func testXMLString() {
        XCTAssertEqual(box.xmlString, nil)
    }

    func testDescription() {
        XCTAssertEqual(box.description, "[foo, 42]")
    }

    func testSequence() {
        let sequence = IteratorSequence(box.makeIterator())
        let array: [XMLContainer] = Array(sequence)
        XCTAssertEqual(array[0] as? XMLStringContainer, XMLStringContainer("foo"))
        XCTAssertEqual(array[1] as? XMLIntContainer, XMLIntContainer(42))
    }

    func testSubscript() {
        var box = self.box
        box[0] = XMLNullContainer()
        XCTAssertEqual(box.count, 2)
        XCTAssertEqual(box[0] as? XMLNullContainer, XMLNullContainer())
        XCTAssertEqual(box[1] as? XMLIntContainer, XMLIntContainer(42))
    }

    func testInsertAt() {
        var box = self.box
        box.insert(XMLNullContainer(), at: 1)
        XCTAssertEqual(box.count, 3)

        XCTAssertEqual(box[0] as? XMLStringContainer, XMLStringContainer("foo"))
        XCTAssertEqual(box[1] as? XMLNullContainer, XMLNullContainer())
        XCTAssertEqual(box[2] as? XMLIntContainer, XMLIntContainer(42))
    }
}
