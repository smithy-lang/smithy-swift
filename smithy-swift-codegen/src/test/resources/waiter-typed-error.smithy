$version: "1.0"

namespace com.test

use aws.api#service
use aws.protocols#restJson1

@service(sdkId: "WaiterTypedErrorTest")
service WaiterTypedErrorTest {
    version: "2019-12-16",
    operations: [GetWidget]
}

@http(uri: "/GetWidget", method: "GET")
operation GetWidget {
    output: GetWidgetOutput
    errors: [WidgetNotFoundError, InvalidWidgetError]
}

structure GetWidgetOutput {
    name: String
}

@error("client")
structure WidgetNotFoundError {
    name: String
}

@error("client")
structure InvalidWidgetError {
    name: String
}
