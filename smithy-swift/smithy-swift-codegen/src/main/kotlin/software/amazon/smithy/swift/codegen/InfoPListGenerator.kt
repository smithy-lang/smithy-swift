/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.utils.CodeWriter

/**
 * Create the info plist file for the generated code
 */
fun writeInfoPlist(settings: SwiftSettings, manifest: FileManifest) {
    val writer = CodeWriter().apply {
        trimBlankLines()
        trimTrailingSpaces()
        setIndentText("    ")
    }
    writer.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
    writer.write("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">")

    writer.openBlock("<plist version=\"1.0\">")
    writer.write("<dict>")
    writer.openBlock("<dict>", "</dict>") {
       writer.write( "<key>CFBundleDevelopmentRegion</key>")
        writer.write("<string>en</string>")
        writer.write("<key>CFBundleExecutable</key>")
        writer.write("<string>\$$(EXECUTABLE_NAME)</string>")
        writer.write("<key>CFBundleIdentifier</key>")
        writer.write("<string>\$$(PRODUCT_BUNDLE_IDENTIFIER)</string>")
        writer.write("<key>CFBundleInfoDictionaryVersion</key>")
        writer.write("<string>6.0</string>")
        writer.write("<key>CFBundleName</key>")
        writer.write("<string>\$$(PRODUCT_NAME)</string>")
        writer.write("<key>CFBundlePackageType</key>")
        writer.write("<string>FMWK</string>")
        writer.write("<key>CFBundleShortVersionString</key>")
        writer.write("<string>${settings.moduleVersion}</string>")
        writer.write("<key>CFBundleSignature</key>")
        writer.write("<string>????</string>")
        writer.write("<key>CFBundleVersion</key>")
        writer.write("<string>\$$(CURRENT_PROJECT_VERSION)</string>")
        writer.write("<key>NSPrincipalClass</key>")
        writer.write("<string></string>")
    }

    val contents = writer.toString()
    manifest.writeFile("info.plist", contents)
}