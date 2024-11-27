# <img alt="Smithy" src="https://github.com/smithy-lang/smithy/blob/main/docs/_static/smithy-anvil.svg?raw=true" width="32"> Smithy Swift

[![License][apache-badge]][apache-url]

[apache-badge]: https://img.shields.io/badge/License-Apache%202.0-blue.svg
[apache-url]: LICENSE

[Smithy](https://smithy.io/2.0/index.html) code generators for [Swift](https://www.swift.org).

> **⚠️ WARNING**: All interfaces are subject to change.

## Getting Started

- Check out [high-level overview of Smithy](https://smithy.io/2.0/index.html)
- Try out Smithy by following [the quick start guide](https://smithy.io/2.0/quickstart.html)
- Apply the Smithy Swift codegen plugin to your Gradle project to generate Swift code

## Feedback

If you'd like to provide feedback, report a bug, request a feature, or would like to bring
attention to an issue in general, please do so by submitting a GitHub issue to the repo [here](https://github.com/smithy-lang/smithy-swift/issues/new/choose).

This is the preferred mechanism for user feedback as it allows anyone with similar issue or suggestion to engage in conversation as well.

## Contributing

If you are interested in contributing to Smithy Swift, see [CONTRIBUTING](CONTRIBUTING.md) for more information.

## Development

### Module Structure

#### Codegen Modules

* `smithy-swift-codegen` - the Kotlin module that generates Swift code from Smithy models.

#### Runtime Modules (under `Sources/`)

* API modules
  * `SmithyChecksumsAPI` - protocols & enums for checksum
  * `SmithyEventStreamsAPI` - protocols & enums for encoding / decoding a single event stream message
  * `SmithyEventStreamsAuthAPI` - protocols & enums for encoding / decoding event streams and signing event stream messages
  * `SmithyHTTPAPI` - protocols & enums for HTTP request and response
  * `SmithyHTTPAuthAPI` - protocols & enums related to signing HTTP requests
  * `SmithyIdentityAPI` - protocols & enums for identity and identity resolver, which are used to sign requests
  * `SmithyRetriesAPI` - protocols & enums related to automatic client-side retry behavior
  * `SmithyWaitersAPI` - protocols & enums related to waiters


* Implementation modules
  * `ClientRuntime` - various runtime functionality used by generated code; contains
    anything that doesn't squarely fit into other implementation modules below. Has most
    of the runtime modules as its dependency.
  * `Smithy` - core functionality used by all clients and other runtime modules, such
               as custom logger type and generic request and response types
  * `SmithyChecksums` - implementations for checksum algorithms
  * `SmithyEventStreams` - implementations for message encoder / decoder and event stream encoder / decoder
  * `SmithyHTTPAuth` - concrete types related to auth flow
  * `SmithyHTTPClient` - concrete request type and its builder
  * `SmithyIdentity` - concrete identity types and identity resolvers for those identity types
  * `SmithyRetries` -  concrete retry strategy types
  * `SmithyStreams` - concrete stream types
  * `SmithyTimestamps` - utility implementations for timestamp shapes in Smithy
  * `SmithyReadWrite` - generic implementations for runtime serde
  * `SmithyJSON` - serde implementations specific to JSON
  * `SmithyXML` - serde implementations specific to XML
  * `SmithyFormURL` - serde implementations specific to FormURL
  * `SmithyTestUtil` - helper methods for auto-generated Swift unit tests.

> 📖 For more information on runtime modules, see [the Smithy Runtime Module Documentation in API reference](https://sdk.amazonaws.com/swift/api/awssdkforswift/latest/documentation/awssdkforswift#Smithy-Runtime-Module-Documentation).

## License

This project is licensed under the Apache-2.0 License.

## Security

See [CONTRIBUTING](CONTRIBUTING.md) for more information.
