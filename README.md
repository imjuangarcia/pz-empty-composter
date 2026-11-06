# Empty Composter

A small Project Zomboid Build 42 mod that adds **Empty Composter** to the Gardening menu of composters, the same way you can empty a rain barrel.

## Why

A sack takes compost 2.5 at a time. When less than that is left in a composter, there is no way to take it out, and a composter that still holds compost can't be picked up. This mod throws the leftover away so the composter can be moved again.

## How to use it

1. Right-click a composter that still has compost in it.
2. Open **Gardening** and pick **Empty Composter (X% left)**, right below Get Compost. Your character walks over and empties it.
3. Take out anything else inside, like worms, and pick the composter up as usual.

The option works for any amount, not just leftovers, so check the number before you click.

Since 42.20 the Gardening submenu is built by the game's Java code, which calls `ISWorldObjectContextMenu.handleCompost` to add Get Compost. The mod wraps that function to add its option to the same submenu. If a build makes the menu differently and the wrapper doesn't run, the option goes at the end of the main right-click menu instead.

### Debug fallback

If the option doesn't show up for some composter, enable debug mode, stand next to it and run this in the Lua console:

```lua
EmptyComposter.clearLeftovers()
```

It only touches composters next to you that hold less than 2.5, so it never throws away compost a sack could still take, and it prints how many composters it found.

## Install

- **Steam Workshop:** subscribe, then enable the mod for your save.
- **Manual:** copy this whole folder to `~/Zomboid/Workshop/EmptyComposter`, so the mod ends up at `~/Zomboid/Workshop/EmptyComposter/Contents/mods/EmptyComposter`.

To enable it on an existing save, use **Load** (not Continue) on the main menu, pick the save, open **Mods** and turn on **Empty Composter**.

## Compatibility

- Build 42 only. Tested on 42.22 in single player.
- Multiplayer: the timed action lives in `shared/` and the server applies the change in `complete()`, like vanilla actions. Not tested on a server yet.
- Lua only, no new items or save data. Safe to add to or remove from an existing save.

## Translations

The menu text comes from `Translate/<LANG>/ContextMenu.json` and falls back to English.

| Code | Language |
| --- | --- |
| EN | English |
| ES | Spanish |
| AR | Spanish (Argentina) |

To add a language, copy `Translate/EN/ContextMenu.json` into a new folder named after the game's language code, translate the text and keep `%1`, which is where the remaining amount goes, percent sign included (for example `0.8%`). Don't add a `%` of your own: since 42.20 translations are Java format strings, and a bare `%` breaks the text. Save the file as UTF-8.

## Layout

```
EmptyComposter/                      Workshop item folder (repo root)
├── preview.png                      Steam Workshop preview
├── workshop.txt                     Workshop title, description and tags
└── Contents/mods/EmptyComposter/
    ├── common/
    └── 42/
        ├── mod.info
        ├── icon.png                 icon in the in-game mod list
        ├── poster.png               image in the mod details
        └── media/lua/
            ├── client/EmptyComposterMenu.lua
            └── shared/
                ├── TimedActions/ISEmptyComposterAction.lua
                └── Translate/{EN,ES,AR}/ContextMenu.json
```

## Publishing

With this folder in `~/Zomboid/Workshop/`, open **Workshop** from the main menu, choose **Create and update items** and pick **EmptyComposter**. After the first upload the game writes the Workshop item id into `workshop.txt`; commit that change so later updates go to the same item.
