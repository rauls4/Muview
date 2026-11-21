---
title: Muview sample
tags: [demo, markdown]
---
# Muview sample

A quick tour of what the **rendered** view handles. Jump to [the table](#a-table) or open the [source](Muview/Renderer.swift).

## Text

Plain, *emphasis*, **strong**, ~~struck~~, `inline code`, and an autolink: https://example.com.

> A blockquote with a second line
> that continues.

## Lists

1. First
2. Second
   - Nested bullet
   - Another

- [x] Task done
- [ ] Task open

## Code

```swift
struct Greeting {
    let name: String
    var text: String { "Hello, \(name)!" }
}
```

## A table

| Kind     | Rendered | Source |
|----------|:--------:|-------:|
| Markdown | yes      | yes    |
| HTML     | yes      | yes    |
| XML      | —        | yes    |

### Inline HTML

Press <kbd>⌘U</kbd> to toggle source.[^1]

[^1]: Footnotes work too.
