# RFC template

* Inspired from
  https://github.com/apple/swift-evolution/blob/main/proposal-templates/0000-swift-template.md
* Keep line length between 80-120 (80 recommended) ignoring URIs/links that
  can't be broken. Recommended to use
  https://marketplace.visualstudio.com/items?itemName=stkb.rewrap
* Include diagrams in your Markdown files with
  [Mermaid](https://github.blog/2022-02-14-include-diagrams-markdown-files-mermaid/)

* * *

# Feature name

* Proposal: [RFC-00001](design/rfc-00001-event-stream.md)
* Authors: [Author 1](https://github.com/awsdev),
  [Author2](https://github.com/awsdev)

* Status: **Awaiting implementation | Implemented  | Review | Rejected
    **

## Introduction

A short description of what the feature is. Try to keep it to a single-paragraph
"elevator pitch" so the reader understands what problem this proposal is
addressing

## Motivation

Describe the problems that this proposal seeks to address. If this is a new
feature, describe the problems that the feature will solve.

## Proposed solution

Describe your solution to the problem. Provide examples and describe how they
work. Show how your solution is better than current workarounds: is it cleaner,
safer, or more efficient?

## Detailed design

Describe the design of the solution in detail. If it's a new API, show the full
API and its documentation comments detailing what it does. The detail in this
section should be sufficient for someone who is *not* one of the authors to be
able to reasonably implement the feature.

## Source compatibility

Will existing SDK applications stop compiling due to this change? Will
applications still compile but produce different behavior than they used to?

We should only break source compatibility if absolutely necessary. It's better
to deprecate and provide a migration path.

## Alternatives considered

Describe alternative approaches to addressing the same problem, and why you
chose this approach instead.

## Acknowledgments

If significant changes or improvements suggested by members of the community
were incorporated into the proposal as it developed, take a moment here to thank
them for their contributions. AWS SDK for Swift RFC is a collaborative process,
and everyone's input should receive recognition!
