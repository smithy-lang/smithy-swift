# Swift Smithy SDK 

## Core Spec

Reference the Smithy [Core Spec](https://awslabs.github.io/smithy/spec/core.html)

### Identifiers and Naming
Swift keywords can be found [here](https://docs.swift.org/swift-book/ReferenceManual/LexicalStructure.html) under Keywords & Punctuation. You can use a reserved word as an identifier if you put backticks (`func`) before and after it.  Keywords other than `inout`, `var`, and `let` can be used as parameter names in a function declaration or function call without being escaped with backticks.

The list of reserved keywords that shouldn't be used as identifiers in Swift is:
* `Any`
* `#available`
* `associatedtype`
* `associativity`
* `as`
* `break`
* `case`
* `catch`
* `class`
* `#colorLiteral`
* `#column`
* `continue`
* `convenience`
* `deinit`
* `default`
* `defer`
* `didSet`
* `do`
* `dynamic`
* `enum`
* `extension`
* `else`
* `#else`
* `#elseif`
* `#endif`
* `#error`
* `fallthrough`
* `false`
* `#file`
* `#fileLiteral`
* `fileprivate`
* `final`
* `for`
* `func`
* `#function`
* `get`
* `guard`
* `indirect`
* `infix`
* `if`
* `#if`
* `#imageLiteral`
* `in`
* `is`
* `import`
* `init`
* `inout`
* `internal`
* `lazy`
* `left`
* `let`
* `#line`
* `mutating`
* `none`
* `nonmutating`
* `nil`
* `open`
* `operator`
* `optional`
* `override`
* `postfix`
* `private`
* `protocol`
* `Protocol`
* `public`
* `repeat`
* `rethrows`
* `return`
* `required`
* `right`
* `#selector`
* `self`
* `Self`
* `set`
* `#sourceLocation`
* `super`
* `static`
* `struct`
* `subscript`
* `switch`
* `this`
* `throw`
* `throws`
* `true`
* `try`
* `Type`
* `typealias`
* `unowned`
* `var`
* `#warning`
* `weak`
* `willSet`
* `where`
* `while`

### Simple Shapes


|Smithy Type| Description                                                       | Swift Type
|-----------|-------------------------------------------------------------------|------------------------
|blob       | Uninterpreted binary data                                         | Data
|boolean    | Boolean value type                                                | Bool
|string     | UTF-8 encoded string                                              | String
|byte       | 8-bit signed integer ranging from -128 to 127 (inclusive)         | Int8
|short      | 16-bit signed integer ranging from -32,768 to 32,767 (inclusive)  | Int16
|integer    | 32-bit signed integer ranging from -2^31 to (2^31)-1 (inclusive)  | Int
|long       | 64-bit signed integer ranging from -2^63 to (2^63)-1 (inclusive)  | Int
|float      | Single precision IEEE-754 floating point number                   | Float
|double     | Double precision IEEE-754 floating point number                   | Double
|bigInteger | Arbitrarily large signed integer                                  | 3rd party libraries avail and apple wrote a prototype [here](https://github.com/apple/swift/blob/master/test/Prototypes/BigInt.swift)
|bigDecimal | Arbitrary precision signed decimal number                         | possibly `Decimal` can be used here
|timestamp  | Represents an instant in time with no UTC offset or timezone. The serialization of a timestamp is determined by a protocol. | Date
|document   | Unstable Represents an untyped JSON-like value that can take on one of the following types: null, boolean, string, byte, short, integer, long, float, double, an array of these types, or a map of these types where the key is string. | Custom type provided by client runtime

**QUESTION**: We should support the `document` type but perhaps we can wait until it's marked stable to do anything with it? At the very least we should annotate the type as unstable if it's going to be in a public API


#### `document` Type

The `document` type is an  untyped JSON-like value that can take on the following types: null, boolean, string, byte, short, integer, long, float, double, an array of these types, or a map of these types where the key is string.


This type is best represented as an enum type. Here we would use the magic of enums in Swift with associated types. The best example of this is from the package [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON/blob/master/Source/SwiftyJSON/SwiftyJSON.swift). We can import this file as our own and just use it in code like JSON


```swift


/**
 * Class representing a Smithy Document type.
 * Can be a [SmithyNumber], [SmithyBool], [SmithyString], [SmithyNull], [SmithyArray], or [SmithyMap]
 */

public enum Document {
    //protocol that all smithy types inherit form to check for nil
    protocol SmithyType {
        public let isNil: Boolean {
            get {
                self == nil
            }
        }
    }

    /**
     * struct representing document `bool` type
    */
    struct SmithyBool : SmithyType {
        public let value: Bool
    }
    /**
    * struct representing document `string` type
    */
    struct SmithyString : SmithyType {
        public let value: String
    }
    /**
    * struct representing document `null` type.
    */
    struct SmithyNull : SmithyType {
        public let value: nil
    }



	case number
	case string(SmithyString)
	case bool (SmithyBool)
	case array
	case dictionary
	case null(SmithyNull)
	case unknown
}

```

Example usage of building a doc or processing one

```swift
func foo() {
    let doc = Document.string(SmithyString(value: "a string"))
    print(doc)

    processDoc(doc: doc)
}

func processDoc(doc: Document) {
    switch(doc) {
        case string(let smithyString):
            print(smithyString.value)
        case bool(let smithyBool):
            print(smithyBool.value)
        //....and on and on and on
    }
}

```



### Aggregate types


| Smithy Type | Kotlin Type
|-------------|-------------
| list        | Array
| set         | Set
| map         | Dictionary
| structure   | struct or class **
| union       | enum


#### Structure

A [structure](https://awslabs.github.io/smithy/spec/core.html#structure) type represents a fixed set of named heterogeneous members. In Swift this can be represented
as either a struct or a class. 

Non boxed member values will be defaulted according to the spec: `The default value of a byte, short, integer, long, float, and double shape that is not boxed is zero`

```
list MyList {
    member: String
}

structure Foo {
    bar: String,
    baz: Integer,
    quux: MyList
}
```

##### ALTERNATIVE 1

```swift
class Foo {
    let bar: String?
    let baz: Int
    let quux: List<String>?

    init(bar: String? = nil, baz: Int = 0, quux: List<String>? = nil) {
        self.bar = bar
        self.baz = baz
        self.quux = quux
    }
}
```

##### ALTERNATIVE 2

```swift
struct Foo{
    let bar: String?
    let baz = 0
    let quux: List<String>?
}
```

Usually in Swift we usually go with structs for several reasons. You get a default constructor out of the box with structs that you do not need to declare and they are value types not reference types. Because classes are reference types, it’s possible for multiple constants and variables to refer to the same single instance of a class behind the scenes which is something to think about.

Structs and classes in Swift both:
- Define properties to store values
- Define methods to provide functionality
- Define subscripts to provide access to their values using subscript syntax
- Define initializers to set up their initial state
- Be extended to expand their functionality beyond a default implementation
- Conform to protocols to provide standard functionality of a certain kind

Classes can do a few other things:
- Inheritance enables one class to inherit the characteristics of another. (but you can only inherit one class whereas you can inherit multiple protocols so class inheritance with a class hierachy isn't used often in Swift)
- Type casting enables you to check and interpret the type of a class instance at runtime.
- Deinitializers enable an instance of a class to free up any resources it has assigned.
- Reference counting allows more than one reference to a class instance. (this is automatic using ARC which stands for Automatic reference counting. refernce to instance isn't removed until all references are removed)


#### Union

A [union](https://awslabs.github.io/smithy/spec/core.html#union) is a fixed set of types where only one type is used at any one time. In Swift this maps well to a [enum](https://docs.swift.org/swift-book/LanguageGuide/Enumerations.html). Enums in swift are like enums on steroids, they can have associated types, raw values, and recursive enums.

Example

```
# smithy

union MyUnion {
    bar: Integer,
    foo: String
}
```

```swift
enum MyUnion {
    struct Bar {
        public let bar: Int
    }
    struct Foo {
        public let foo: String
    }
    case bar(Bar)
    case foo(Foo)
}

```


### Service types

Services will generate both an interface as well as a concrete client implementation.

Each operation will generate a method with the given operation name and the `input` and `output` shapes of that operation.


The following example from the Smithy quickstart has been abbreviated. All input/output operation structure bodies have been omitted as they aren't important to how a service is defined.

```
service Weather {
    version: "2006-03-01",
    resources: [City],
    operations: [GetCurrentTime]
}

@readonly
operation GetCurrentTime {
    output: GetCurrentTimeOutput
}

structure GetCurrentTimeOutput {
    @required
    time: Timestamp
}

resource City {
    identifiers: { cityId: CityId },
    read: GetCity,
    list: ListCities,
    resources: [Forecast],
}

resource Forecast {
    identifiers: { cityId: CityId },
    read: GetForecast,
}

// "pattern" is a trait.
@pattern("^[A-Za-z0-9 ]+$")
string CityId

@readonly
operation GetCity {
    input: GetCityInput,
    output: GetCityOutput,
    errors: [NoSuchResource]
}

structure GetCityInput { ... }

structure GetCityOutput { ...  }

@error("client")
structure NoSuchResource { ... } 

@readonly
@paginated(items: "items")
operation ListCities {
    input: ListCitiesInput,
    output: ListCitiesOutput
}

structure ListCitiesInput { ... }

structure ListCitiesOutput { ... }

@readonly
operation GetForecast {
    input: GetForecastInput,
    output: GetForecastOutput
}

structure GetForecastInput { ... }
structure GetForecastOutput { ... }
```


```swift
protocol Weather {
    func getCurrentTime() -> GetCurrentTimeOutput

    /**
     * ...
     * 
     * @throws NoSuchResource
     */
    func getCity(input: GetCityInput) -> GetCityOutput


    func listCities(input: ListCitiesInput) -> ListCitiesOutput


    func getForecast(input: GetForecastInput) -> GetForecastOutput
}

class WeatherClient : Weather {

    typealias GetCurrentTimeOutputCompletion = (GetCurrentTimeOutput) -> Void

    typealias GetCityOutputCompletion = (GetCityOutput) -> Void

    typealias ListCitiesOutputCompletion = (ListCitiesOutput) -> Void

    typealias GetForecastOutputCompletion = (GetForecaseOutput) -> Void

    func getCurrentTime(completion: GetCurrentTimeOutputCompletion) { 
        ... 
        let result = //calls to server
        completion(result)
    }

    func getCity(input: GetCityInput, completion: GetCityOutputCompletion) { 
        ...
        let result = //calls to server
        completion(result)
    }

    func listCities(input: ListCitiesInput, completion: ListCitiesOutputCompletion) { 
        ... 
    }

    func getForecast(input: GetForecastInput, completion: GetForecastOutputCompletion){ 
        ... 
    }
}

```


#### Considerations

1. Closures. Closures in swift are how we can represent async operations.

All service operations are expected to be async operations under the hood since they imply a network call. Making this explicit in the interface with closures sets expectations up front.


2. OperationQueues. how will we use them to send concurrent requests?



3. Backwards Compatibility




### Resource types

Each resources will be processed for each of the corresponding lifecycle operations as well as the non-lifecycle operations. 

Every operation, both lifecycle and non-lifecycle, will generate a method on the service class to which the resource belongs. 

This will happen recursively since resources can have child resources. 

See the Service section which has a detailed example of how resources show up on a service.


### Traits

### Type Refinement Traits

#### `box` trait

Indicates that a shape is boxed which means the member may or may not contain a value and that the member has no default value. We would use optionals in Swift to represent this.

NOTE: all shapes other than primitives are always considered boxed in the Smithy spec

```
structure Foo {
    @box
    bar: integer

}
```


```swift
struct Foo {
    let bar: Int?
}
```

**QUESTION**: If all non-primitive types (e.g. String, Structure, List, etc) are considered boxed should they all be generated as nullable in Kotlin?
e.g.

```
structure Baz {
    quux: integer
}

structure Foo {
    bar: String,
    baz: Baz
}

```

```swift
struct Baz{
    let quux = 0
}

struct Foo {
    let bar: String?
    let baz: Baz?
}

```


#### `deprecated` trait

Will generate the equivalent code for the shape annotated with Swifts's `@available` attribute and pass in the deprecated and message arguments with the version and message.

```
@deprecated
structure Foo

@deprecated(message: "no longer used", since: "1.3")
```

```swift
@available(deprecated: 1.3, message: "no longer used")
class Foo {}

```

#### `error` trait

The `error` trait will be processed as an exception type in Swift. This requires support from the client-runtime lib. See "Exceptions" in the Appendix.


Note the Smithy core spec indicates: `The message member of an error structure is special-cased. It contains the human-readable message that describes the error. If the message member is not defined in the structure, code generated for the error may not provide an idiomatic way to access the error message (e.g., an exception message in Java).`

If present these should be translated to the `ServiceException::errorMessage` property.


The `httpError` trait should not need additional processing assuming the HTTP response itself is exposed in someway on `ServiceException`. 


```
@error("server")
@httpError(501)
structure NotImplemented {}

@error("client")
@retryable
structure ThrottlingError {
    @required
    message: String,
}

```


```swift

enum ErrorType {
    case server
    case client
}

enum ServiceException : Error {
    case notImplementedException(NotImplementedException)
    case throttlingError(ThrottlingError)
}

struct NotImplementedException: Exception {
    public let isRetryable = false
    public let errorType = .server
    public let serviceName = "MyService"
}

struct ThrottlingError : Exception {
    public let isRetryable = true
    public let errorType = .client
    public let serviceName = "MyService"
}

protocol Exception {
    public let message: String
    public let serviceName: String
    public let errorType: ErrorType
    public let isRetryable: Bool
}

```


### Constraint traits

#### `enum` trait

Swift has first class support for enums and the SDK should make use of them to provide a type safe interface.

When no `name` is provided the enum name will be the same as the value, otherwise the Swift SDK will use the provided enum name.


```
@enum("YES": {}, "NO": {})
string SimpleYesNo

@enum("Yes": {name: "YES"}, "No": {name: "NO"})
string TypedYesNo
```

```swift
enum SimpleYesNo : String {
    case yes = "yes"
    case no = "no"

}
enum TypedYesNo : String {
    case yes = "yes"
    case no = "no"
}
```


```
@enum(
    t2.nano: {
        name: "T2_NANO",
        documentation: """
            T2 instances are Burstable Performance
            Instances that provide a baseline level of CPU
            performance with the ability to burst above the
            baseline.""",
        tags: ["ebsOnly"]
    },
    t2.micro: {
        name: "T2_MICRO",
        documentation: """
            T2 instances are Burstable Performance
            Instances that provide a baseline level of CPU
            performance with the ability to burst above the
            baseline.""",
        tags: ["ebsOnly"]
    },
    m256.mega: {
        name: "M256_MEGA",
        deprecated: true
    }
)
string MyString
```


```swift
enum MyString : String {

    /**
     * T2 instances are Burstable Performance Instances that provide a baseline level of CPU performance with the ability to burst above the baseline.
     */
    case t2_nano = "t2.nano"

    /**
     * T2 instances are Burstable Performance Instances that provide a baseline level of CPU performance with the ability to burst above the baseline.
     */
    case t2_micro = "t2.micro"

    @available(deprecated: 1.3)
    case m256.mega = "m256.mega"

}
```

#### Considerations

**Deprecation**

Concern here is that with deprecating something in Swift you need to provide the version as the value of the argument and looks like here it isn't provided in the Smithy enum model. How do we account for that?

**Unknown Enum Names**

The Smithy core spec indicates that unknown enum values need to be handled as well. 

```
Consumers that choose to represent enums as constants SHOULD ensure that unknown enum names returned from a service do not cause runtime failures.
```

This is fine for swift because we can use the @unknown attribute in a swift statement to handle it and not fail like this:
```swift
switch string {
case .t2_micro:
   //do something here
case .t2_nano:
    //do something here
@unknown default:
    print("unknown value")
}
```

In terms of deserialization of unknown enum values we need to do a litle extra work and there are alternatives to what that is

**ALTERNATIVE 1**

use custom encoding when deserializing
```swift
enum Material: String, Codable {
	case wood, metal, glass, unknown
}

extension Material {
	init(from decoder: Decoder) throws {
		self = try Material(from: decoder, default: .unknown)
	}
}

//here we are mapping unknown values to the .other case

extension RawRepresentable where RawValue: Decodable {
	init(from decoder: Decoder, default: Self) throws {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(RawValue.self)
		self = Self(rawValue: rawValue) ?? `default`
	}
}   
//If a RawRepresentable’s RawValue type is decodable, we’re offering an initialiser that tries to decode a raw value of that type. If that raw value does not match a represented value, it will fallback to a provided default.

//then we can change extension
```

**ALTERNATIVE 2**

We can use CaseIterable here to loop through all the cases and see if it matches our raw value given and if not we can provide an unknonw option. This allows us to handle it not just at the decoding level but also at the instantiation level like this 
```swift
protocol UnknownCaseRepresentable: RawRepresentable, CaseIterable where RawValue: Equatable {
	static var unknownCase: Self { get }
}

extension UnknownCaseRepresentable {
	init(rawValue: RawValue) {
		let value = Self.allCases.first(where: { $0.rawValue == rawValue })
		self = value ?? Self.unknownCase
	}
}

enum Material: String {
	case wood, metal, glass, unknown
}

extension Material: Codable {}

extension Material: UnknownCaseRepresentable {
	static let unknownCase: Material = .unknown
}

//then when you instantiate like this
Material(rawValue: "stone") // -> .other
```
 I think alternative 2 might be the best option here to capture both the decoding of the unknonw values in enums in smithy and also the instantiation of them but not sure what is important here for these unknown values. The quesiton is what is happening to these ennums with unknown values being returned from a service? Are we just deserializing them? Are we taking some action that needs to be handled first?


#### `idRef` trait
Not processed

#### `length` trait
**TODO**
**QUESTION** I don't even see where these constraints (length, range, pattern, etc) are processed in the smithy-typescript/smithy-go code generators. Are they not implemented?

#### `pattern` trait
**TODO**

#### `private` trait
Not processed 

#### `range` trait
**TODO**

#### `required` trait

```
struct Foo {
    @required
    bar: String
}
```

##### ALTERNATIVE 1

All members marked `required` should show up in the class as nonoptional

```swift
struct Foo {
    let bar: Sttring
}
```

#### `uniqueItems` trait
**TODO**

### Behavior traits

#### `idempotentcyToken` trait
**TODO** The spec states that `clients MAY automatically provide a value`. This could be interpreted to provide a default UUID and allow it to be overridden.

#### `idempotent` trait

Not processed

**FUTURE** It may be worthwhile generating documentation that indicates the operation is idempotent.

#### `readonly` trait

Not processed

#### `retryable` trait

This trait influences errors, see the `error` trait for how it will be handled.


#### `paginated` trait

Not processed

### Resource traits

#### `references` trait
Not processed

#### `resourceIdentifier` trait
Not processed

### Protocol traits

#### `protocols` trait

Inspected to see if the protocol is supported by the code generator/client-runtime. If no protocol is supported codegen will fail.

The `auth` peroperty of this trait will be inspected just to confirm at least one of the authentication schemes is supported.

All of the built-in HTTP authentication schemes will be supported by being able to customize the request headers.


#### `auth` trait

Processed the same as the `auth` property of the `protocols` trait. 

#### `jsonName` trait

The generated class member will have the `@SerialName("...")` annotation added to the property. 

This will create an enum in the class with its coding keys like below:

```swift
struct Employee: Codable {
  public let barFoo: Int
  public let fooBar: String

  enum CodingKeys: String, CodingKey {
    case barFoo = "bar_foo"
    case fooBar = "foo_bar"
  }
  //the coding keys represent the keys= names in json
}
```

#### `mediaType` trait

The media type trait SHOULD influence the HTTP Content-Type header if not already set.



#### `timestampFormat` trait

We will use the `Date` type in swift. I presume we will need some Date extensions to handle various date formats.

### Documentation traits

#### `documentation` trait

All top level classes, enums, and their members will be generated with the given documentation.

#### `examples` trait

Not processed

**FUTURE** We probably should process this but I think it's ok to put it lower priority

#### `externalDocumentation` trait

Processed the same as the `documentation` trait. The link will be processed appropriately for the target documentation engine (e.g. [dokka](https://github.com/Kotlin/dokka)).

#### `sensitive` trait

Not processed

#### `since` trait

Not processed

**FUTURE** We should probably process this into the generated documentation at least.

#### `tags` trait

Not processed

#### `title` trait

Combined with the generated documentation as the first text to show up for a service or resource.


### Endpoint traits

#### `endpoint` trait
**TODO**

#### `hostLabel` trait
**TODO**


# HTTP Protocol Bindings

**TODO**


# Appendix

