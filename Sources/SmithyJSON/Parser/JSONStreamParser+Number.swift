//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Decimal

extension JSONStreamParser {

    func startNumber() throws -> Event {
        // Check the JSON stack to ensure this JSON value is expected / allowed
        // Then, update the next expected element
        try startJSONValue(index: input.characterIndex, isString: false)

        var negative = false
        var significand: Decimal!
        var significandComponent: UInt64 = 0
        var totalDigitCount = 0
        var componentDigitCount = 0
        var decimalExponent: Int32 = 0
        var afterEExponent: Int32 = 0
        var significandOverflowExponent: Int32 = 0
        var pastDecimal = false
        var leadingZeroIndex: Int?
        var numberComplete = false

        // Check for a negative sign to start the number.
        if currentChar == Self.minus {
            negative = true
            currentChar = try input.next()
        }

        // Check for a leading zero
        leadingZeroIndex = currentChar == Self.zero ? input.characterIndex : nil

        // Ensure the number starts with a numeric digit, or if the number started with
        // a negative sign, that it is followed by a digit.
        guard (Self.zero...Self.nine).contains(currentChar) else {
            throw ParserError.unexpectedCharacter(currentChar, input.characterIndex)
        }

        var digitPastDecimal = true
        while !numberComplete, (currentChar >= Self.zero && currentChar <= Self.nine) || currentChar == Self.period {
            if currentChar == Self.period {

                // Throw if there is a second decimal in the number.
                guard !pastDecimal else {
                    throw ParserError.unexpectedCharacter(Self.period, input.characterIndex)
                }

                // Mark the "pastDecimal" flag true so a second decimal won't be allowed.
                pastDecimal = true

                // Mark the "digitPastDecimal" flag false so parsing fails unless the
                // decimal is followed by at least one digit.
                digitPastDecimal = false
            } else {

                if totalDigitCount < 38 {

                    // Increase the significand for the additional digit that was
                    // encountered.
                    significandComponent *= 10
                    let digitValue = UInt64(currentChar.value - Self.zero.value)
                    significandComponent += digitValue
                    componentDigitCount += 1
                } else {

                    // The 38 decimal digits of the significand have been filled.
                    // Further digits are dropped but the exponent is incremented
                    // so the final number has the correct order of magnitude.
                    significandOverflowExponent += 1
                }
                totalDigitCount += 1
                if pastDecimal { decimalExponent -= 1 }

                // Mark digitPastDecimal true since a digit was parsed.
                digitPastDecimal = true

                // Once 19 decimal digits have been parsed into an Int64, it is full.
                // Add them to the Decimal significand, and start the significand
                // component all over again.
                if componentDigitCount == 19 {
                    significand = updatedSignificand(from: significand, digitCount: 19, adding: significandComponent)
                    componentDigitCount = 0
                    significandComponent = 0
                }
            }
            do {
                // Index past the digit.
                currentChar = try input.nextIf { scalar in
                    let isNumberCharacter = (scalar >= Self.zero && scalar <= Self.nine) || scalar == Self.period || scalar == Self.E || scalar == Self.e
                    numberComplete = !isNumberCharacter
                    return isNumberCharacter
                }

                // If there was a leading zero, ensure it is followed by a decimal or e/E
                if !numberComplete, let leadingZeroIndex, currentChar != Self.period && currentChar != Self.E && currentChar != Self.e {
                    throw ParserError.unexpectedCharacter(Self.zero, leadingZeroIndex)
                }
                leadingZeroIndex = nil
            } catch CharacterStreamControl.endOfJSON {
                numberComplete = true
            }
        }

        // A JSON decimal point must have a digit after it.  Throw if there was a decimal
        // not followed by some digit.
        guard digitPastDecimal else {
            throw ParserError.unexpectedEndOfNumber(input.characterIndex)
        }

        // Compute the final significand.
        significand = updatedSignificand(from: significand, digitCount: componentDigitCount, adding: significandComponent)

        // Check to see if an exponent follows.  It will start with 'E' or 'e'
        if !numberComplete, currentChar == Self.e || currentChar == Self.E {

            // Check for a sign, and set the flag if negative.
            currentChar = try input.next()
            guard (currentChar >= Self.zero && currentChar <= Self.nine) || currentChar == Self.plus || currentChar == Self.minus else {
                throw ParserError.unexpectedCharacter(currentChar, input.characterIndex)
            }

            var afterENegative = false
            if !numberComplete, currentChar == Self.plus || currentChar == Self.minus {
                afterENegative = currentChar == Self.minus
                currentChar = try input.nextIf { scalar in
                    let isDigit = (scalar >= Self.zero && scalar <= Self.nine)
                    numberComplete = !isDigit
                    return isDigit
                }
            }

            // Iterate through the exponent digits to build up the exponent.
            // Swift Decimal stores exponent in a 32-bit signed integer, which
            // can safely handle 9 significant digits.
            var exponentDigitCount = 0
            while !numberComplete, currentChar >= Self.zero && currentChar <= Self.nine {
                exponentDigitCount += 1
                if exponentDigitCount <= 9 {
                    afterEExponent *= 10
                    let digit = Int32(currentChar.value - Self.zero.value)
                    afterEExponent += digit
                }
                do {
                    currentChar = try input.nextIf { scalar in
                        (scalar >= Self.zero && scalar <= Self.nine)
                    }
                } catch CharacterStreamControl.endOfJSON {
                    numberComplete = true
                }
            }

            // Ensure there is at least one digit in the after-E exponent.
            guard exponentDigitCount > 0 else {
                throw ParserError.unexpectedCharacter(currentChar, input.characterIndex)
            }

            // Apply the negative sign to the exponent.
            afterEExponent = (afterENegative ? -1 : 1) * afterEExponent
        }

        // Compose a Decimal for the number from its sign, significand, and exponent.
        let sign: FloatingPointSign = negative ? .minus : .plus
        let exponent = decimalExponent + significandOverflowExponent + afterEExponent
        let decimal = Decimal(sign: sign, exponent: Int(exponent), significand: significand)

        return .number(decimal)
    }

    private func updatedSignificand(from significand: Decimal?, digitCount: Int, adding significandComponent: UInt64) -> Decimal {
        if let significand {
            return Decimal(sign: .plus, exponent: digitCount, significand: significand) + Decimal(significandComponent)
        } else {
            return Decimal(significandComponent)
        }
    }
}
