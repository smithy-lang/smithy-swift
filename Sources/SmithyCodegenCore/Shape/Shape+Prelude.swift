//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Prelude
import struct Smithy.ShapeID

extension Shape {

    static var prelude: [ShapeID: Shape] {[
        unit.id: unit,
        boolean.id: boolean,
        string.id: string,
        integer.id: integer,
        blob.id: blob,
        timestamp.id: timestamp,
        byte.id: byte,
        short.id: short,
        long.id: long,
        float.id: float,
        double.id: double,
        document.id: document,
        primitiveBoolean.id: primitiveBoolean,
        primitiveInteger.id: primitiveInteger,
        primitiveByte.id: primitiveByte,
        primitiveLong.id: primitiveLong,
        primitiveFloat.id: primitiveFloat,
        primitiveDouble.id: primitiveDouble,
    ]}

    static var unit: Shape {
        let schema = Smithy.Prelude.unitSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var boolean: Shape {
        let schema = Smithy.Prelude.booleanSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var string: Shape {
        let schema = Smithy.Prelude.stringSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var integer: Shape {
        let schema = Smithy.Prelude.integerSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var blob: Shape {
        let schema = Smithy.Prelude.blobSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var timestamp: Shape {
        let schema = Smithy.Prelude.timestampSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var byte: Shape {
        let schema = Smithy.Prelude.byteSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var short: Shape {
        let schema = Smithy.Prelude.shortSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var long: Shape {
        let schema = Smithy.Prelude.longSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var float: Shape {
        let schema = Smithy.Prelude.floatSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var double: Shape {
        let schema = Smithy.Prelude.doubleSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var document: Shape {
        let schema = Smithy.Prelude.documentSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var primitiveBoolean: Shape {
        let schema = Smithy.Prelude.primitiveBooleanSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var primitiveInteger: Shape {
        let schema = Smithy.Prelude.primitiveIntegerSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var primitiveByte: Shape {
        let schema = Smithy.Prelude.primitiveByteSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var primitiveShort: Shape {
        let schema = Smithy.Prelude.primitiveShortSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var primitiveLong: Shape {
        let schema = Smithy.Prelude.primitiveLongSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var primitiveFloat: Shape {
        let schema = Smithy.Prelude.primitiveFloatSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }

    static var primitiveDouble: Shape {
        let schema = Smithy.Prelude.primitiveDoubleSchema
        return Shape(id: schema.id, type: schema.type, traits: schema.traits)
    }
}
