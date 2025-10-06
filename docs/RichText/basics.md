---
sidebar_position: 1
---

# Basics

**Typist** uses a custom implementation of rich text. Although the syntax is comparable to Roblox, there are still many differences.


# Creating a Tag
A tag can be created by wrapping text in angle brackets: **< ... >**.

```text
<tagName>
```
To close a tag, use a slash before the tag's name
```text
</tagName>
```
Putting it together, you get this:
```text
<tagName>This is some text affected by the tag!</tagName>
```

# Attributes
Attributes allow for extra customization. Wrap the content of an attribute in square brackets: **[ ... ]**
```text
<tagName Attribute=[...]>
```
Multiple attributes are fine aswell! Seperate them with a space.
```text
<tagName Attribute1=[...] Attribute2=[...]>
```

# Actions
Actions are tags that apply *once* to the next character. They don't need to be closed.
To create one, start a tag with a double-slash.
```text
<//action>
```
Actions can have attributes as well, take the flag action for example:
```text
<//flag Id=[2]>
```