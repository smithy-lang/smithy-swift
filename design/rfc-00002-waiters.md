# Waiters

* Proposal: **RFC-00002**
* Author: [Josh Elkins](https://github.com/jbelkins)
* Status: **Implemented**

## Introduction

Waiters are a Smithy feature, and are defined in the Smithy specification at https://awslabs.github.io/smithy/2.0/additional-specs/waiters.html.  From this spec:

>Waiters are a client-side abstraction used to poll a resource until a desired state is reached, or until it is determined that the resource will never enter into the desired state.


Waiters are defined in Smithy using the `@waitable` trait on an API operation.  Here is an example (from the Smithy spec document) that defines a waiter that polls until a S3 bucket exists:

```
@waitable(
    BucketExists: {
        documentation: "Wait until a bucket exists"
        acceptors: [
            {
                state: "success"
                matcher: {
                    success: true
                }
            }
            {
                state: "retry"
                matcher: {
                    errorType: "NotFound"
                }
            }
        ]
    }
)
operation HeadBucket {
    input: HeadBucketInput
    output: HeadBucketOutput
    errors: [NotFound]
}
```

The waiter name (here, `BucketExists`) is just an alphanumeric name that can be used to identify waiters that wait for specific conditions.
The waiter structure defines (along with a documentation field) the conditions that will cause the waiter to continue waiting, be satisfied, or to immediately fail.

On client SDKs, the waiter is exposed as an instance method on a service client like S3 or EC2. Waiting behaves in a way that:

* If the operation is successfully completed, then the waiter transitions to success state and terminates.
* If the operation encounters an error, then the waiter transitions to retry state.
* In retry state, the operation is recreated and sent to service (step 1).

Because the `@waitable` trait is defined in the Smithy IDL and is not specific to AWS, the Swift implementation for waiters will be implemented entirely in the `smithy-swift` project.  The AWS Swift SDK will use `smithy-swift` to generate waiters for specific AWS services.

## Public Interface

A waiter method is added to the service client for each waiter defined on that service.  The method signature of the waiter is of the form `func waitUntil<WaiterName>(options:input:)` and the method takes two parameters: a waiter options value, and an input value (which is the same as the input for the non-waited operation.) When called, the `waitUntil...` method will immediately perform the operation, but if needed, will continue to retry the operation until the wait condition is satisfied.  Only then will the `waitUntil...` method return with a output value.  If a response to an operation meets a failure condition, or an error is returned which is not explicitly handled by the waiter, the waiter will terminate and a Swift error will be thrown back to the caller.

```
do {
    let client = try S3Client(region: "us-east-1")
    let input = HeadBucketInput(bucket: "newBucket")
    let options = WaiterOptions(maxWaitTime: 120.0, minDelay: 5.0, maxDelay: 20.0)
    try await client.waitUntilBucketExists(options: options, input: input)
    print("Bucket now exists.")
} catch {
    print("Error occurred while waiting: \(error.localizedDescription)")
}
```

#### Wait Options

The caller will supply wait options to configure certain parameters of the wait.  The only required value on waiter options is the maximum wait time `maxWaitTime`, which will be in the form of a Swift `TimeInterval`.  Wait options may optionally provide a `minDelay` and `maxDelay`, which, when supplied, will replace the ones specified in the waiter declaration.

```
public struct WaiterOptions {
    let maxWaitTime: TimeInterval
    let minDelay: TimeInterval?
    let maxDelay: TimeInterval?
}
```

#### Retry Strategy

Smithy specifies an algorithm which is to be used for scheduling retries during waiting.  The Smithy preferred algorithm is always used and not replaceable or customizable, other than through the `WaiterOptions` parameters.  Smithy’s retry strategy is best summarized as “exponential backoff with jitter” and is defined in detail in the [Smithy docs](https://awslabs.github.io/smithy/2.0/additional-specs/waiters.html#waiter-retries).

#### Return Type

On success, the `waitUntil...` method will return a `WaiterOutcome` value that includes summary data about the wait, and the result of the final wait operation, i.e. the one that caused the waiter to succeed. Because a waiter may succeed on either a successful or an error response, the last result may be either an error or output object; the outcome’s `result` property is an enumeration that may contain either, depending on the acceptor that was matched.

If the caller is not interested in the contents of a waiter’s outcome, the return value may be discarded.

```
public struct WaiterOutcome<Output> {    
    let attempts: Int
    let result: Result<Output, Error>
}
```

## Implementation

### 1.  Add waiter types to Smithy ClientRuntime (large, ~1 wk.)

Several additions will have to be made to the Smithy `ClientRuntime` to implement waiters.  For each subitem a-d:

1. Build the type, along with all needed functionality
2. Add unit tests to cover all waiter logic

Finally, as an operational test, manually construct & configure a waiter from the components that have been added to `ClientRuntime` using a live, existing AWS endpoint, and verify that it works on an actual AWS service.

#### a.  Add a Reusable Waiter Options Type

See the `WaiterOptions` defined in the interface above.

#### b.  Add a Generic, Reusable Waiter Outcome Type

Waiter outcome should be defined as shown in Interface above.  It will be generic so that it can be used with any output type.

#### c.  Add a WaiterConfig and Acceptor type

The `WaiterConfig` configures a waiter to follow the behaviors defined in a waiter’s Smithy definition (as opposed to the ones that are supplied at the time of waiting by the caller in `WaiterOptions`).  A static WaiterConfig value will be code-generated for each named waiter defined for a service.

A `WaiterConfig` has the form:

```
public struct WaiterConfig<Input, Output> {
    let name: String
    let minDelay: TimeInterval
    let maxDelay: TimeInterval
    let acceptors: [Acceptor<Input, Output>]
}
```

Each waiter contains an ordered list of `Acceptor`s.  An instance of this type can be code-generated from the Smithy specification for each acceptor defined in a waiter.  The Smithy spec defines four alternative forms for a `Matcher`, but all can be boiled down to a closure with the signature below.  (If desired, convenience initializers for `Matcher` can be defined that mirror the Smithy matcher forms more closely.)

```
public struct Acceptor<Input, Output> {

    typealias Matcher = (Input, Result<Output, Error>) -> Bool

    public enum State {
        case success
        case failure
        case retry
    }
    
    public let state: State
    public let matcher: Matcher
}
```

#### d.  Add a Generic Waiter Class to Coordinate Waiting

To perform waiting, one creates & configures a `Waiter` object, then calls a wait method on it.  The signature for the `Waiter` type:

```
public class Waiter<Input, Output> {

    public init(config: WaiterConfig<Input, Output>,
                operation: @escaping (Input) async throws -> Output)
    
    @discardableValue
    public waitUntil(options: WaiterOptions, input: Input) -> WaiterOutcome<Output>
}
```

The `Waiter` object is initialized with these params:

* A `WaiterConfig` that is code-generated from the Smithy definition.
* The input object, supplied by the caller.
* The closure to be used to access the resource (closure will take `Input` as a parameter, perform a call on the Client, asynchronously returns `Output` & may throw).  This signature is the same as an operation’s function pointer and will typically be code-generated.

Once the `Waiter` is created, the `waitUntil(options:input:)` method on the Waiter is called with:

* A set of `WaiterOptions` to configure this wait
* An `Input` structure that will be used for every operation during the wait

The wait will begin and continue asynchronously until:

* An acceptor with state `success` is matched and a `WaiterOutcome` is asynchronously returned, or 
* an acceptor with state `failure` is matched and an error is asynchronously thrown, or
* an operation returns an error that is not matched by any acceptor and the error is asynchronously thrown, or
* the maximum timeout for the wait is reached, and a `WaiterTimeoutError` is asynchronously thrown.

#### e.  Add a WaiterTypedError protocol

The `errorType` acceptor matches errors with a string that is specified in the acceptor, and matches to the “error code” on AWS errors.  Because the Swift SDK does not currently expose the error code on its errors, the `WaiterTypedError` protocol has been created to allow operation errors to provide their type for matching.

```
public protocol WaiterTypedError: Error {
    var waiterErrorType: String? { get }
}
```

To minimize the effect on binary size, `WaiterTypedError` conformance is only rendered for operation errors where the operation actually has a waiter with an `errorType` acceptor.

Any error thrown by a failed operation is conditionally cast to `WaiterTypedError` before attempting to match it, so any error that doesn't conform to `WaiterTypedError` will always fail to match an `errorType` acceptor.

Because operation errors are sometimes enclosed in `SdkError` before being thrown, that type is extended with `WaiterTypedError` conformance as well, to provide the error type for the operation error it encloses.  Swift error types for capturing “unknown” errors are also extended with `WaiterTypedError` conformance, returning the error code that could not be matched to a known type of error.

#### Summary

The advantage of this approach is that it keeps all code & logic needed to implement the waiter separate from the underlying operation, which remains totally unmodified, and waiters add no complexity to existing runtime or code-generated code.

### 2.  Code-generate WaiterConfig for each waiter (large, ~1 wk)

The `WaiterConfig` value will be code-generated to a static variable for use in each `waitUntil...` method defined below.  

The ordered list of acceptors in the Smithy specification for each waiter should be code-generated into an array of `Acceptor`s and stored in the waiter config.  The `Acceptor` array will provide logic used at runtime to decide whether the waiter will succeed, retry, or fail in response to an operation.

Acceptors may include a matching predicate defined per the [JMESPath specification](https://jmespath.org/).  The [main Smithy project](https://github.com/awslabs/smithy) includes a [parser](https://github.com/awslabs/smithy/tree/main/smithy-jmespath/src/main/java/software/amazon/smithy/jmespath) that breaks JMESPath expressions into a Smithy-native AST for use in code generation.  This AST, in turn, will be used to generate Swift-native code (i.e. Boolean expressions) that evaluate to the intended result of the JMESPath expression.

### 3.  Code-generate a `waitUntil...` method on the service client for each waiter (medium, ~3 days)

A `waitUntil...` method is code-generated to the service client for each waiter that is defined.  The name of the method will be set as follows: `waitUntil<WaiterName>` (waiter names are unique within a service, so waiter name is sufficient to prevent namespace collisions among service client instance methods.)  The method would take as parameters the wait options and an input object, and asynchronously return a `WaiterOutcome` which may be ignored by the caller.  The `waitUntil...` method will throw if the waiter fails, times out, or if any other unhandled error occurs while waiting.

The body of the `waitUntil...` method will create & configure a specialized instance of the generic `Waiter` described above and use it to perform the waited operation:

```
@discardableResult
public func waitUntilBucketExists(options: WaiterOptions,
                                input: HeadBucketInput) async throws
    -> WaiterOutcome<HeadBucketOutputResponse> {
    let waiter = Waiter<HeadBucketInput, HeadBucketOutputResponse>(
                     config: Self.waitUntilBucketExistsConfig,
                     operation: self.headBucket(input:)
                 )
    return try async waiter.wait(options: options, input: input)
}
```

### 4.  Integrate Smithy additions into AWS Swift SDK (medium, ~3-4 days)

Integrate the smithy-swift changes made above into the AWS Swift SDK.  Code-generate the SDK, ensuring that waiters code-generate, build, and operate as expected, using representative AWS API operations.  At the completion of this stage, waiters should be merged and ready to include in the next SDK release.

