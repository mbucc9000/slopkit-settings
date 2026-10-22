<img src="icon.png" width="80" align="right" alt="">

# slopkit Settings

One slopkit row in iOS 6 Settings for every slopkit tweak. Each tweak's settings open from there, and their separate rows leave the main list.

## Features

- One slopkit row in Settings, no matter how many slopkit tweaks you install.
- Tweaks with settings open their own pane from there.
- Tweaks without settings get a page with their version and a View in Cydia button.
- It also lists slopkit tweaks you don't have yet.
- Want the old separate rows back too? Turn on Also Show in Settings.

## How to use

1. Open Settings › slopkit: every slopkit tweak you have is listed there.
2. Turn on Also Show in Settings to keep the tweaks' own rows on the main page too.

## Requirements

- Jailbroken iOS 6 (tested on an iPhone 5 with iOS 6.1.2)
- Cydia Substrate and PreferenceLoader (Cydia installs them for you)

## Install

In Cydia, add `https://mbucc9000.github.io/slopkit/` and install **slopkit Settings**. Or download the `.deb` from [Releases](../../releases) and install it with `dpkg -i`.

## Building

[Theos](https://theos.dev) with the iOS 6.1 SDK: `make package FINALPACKAGE=1`.

## License

MIT.

Inspired by Lululab Settings from [lululab](http://lululab.net/).
