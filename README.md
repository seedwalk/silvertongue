# Silvertongue

Roleplay phrases for World of Warcraft, on the frames you are already watching.

You know what is happening. Silvertongue knows how to say it.

Click a target, pick *Praise*, read the line, click *Say*. Three seconds, and
your character said something in character instead of `nice heals bro`.

**Burning Crusade Classic** (Interface 20506).

---

## Install

Drop the `Silvertongue` folder into:

```
World of Warcraft/_anniversary_/Interface/AddOns/
```

Restart the game. That is all — there is nothing to configure before it works.

---

## The one rule

**Nothing reaches chat until you click to send it.** Every button, key and menu
in this addon fills a box and stops. You read the line first, every time.

---

## Using it

### On your own portrait

A small speech bubble sits under your level. Press it and four rows fan out:

```
 💬
 👥 General      everyday talk
 ⚔  Horde        your faction
 🗡 Rogue        your class
 😱 Attitude     when you have an opinion
```

Press it again and they fold away. Pick one and its menu opens beside it. They
start folded every session: at rest this is meant to be one small icon.

### On your target

A speech bubble sits under your target's level. Press it and it fans out the
same way your own does:

```
 💬
 👥 Invite
 🪙 Trade
 ⚔  Duel
 🗡 Speak      ← their class icon, and the phrases
```

The first three act the moment you press them — all three are requests the
other player still has to accept. `Speak` opens the phrases.

Rows that make no sense are not there: no invite for someone already in your
group, and nothing to accept from a creature or an enemy. The fan stays open or
folded as you change targets, and an open phrase menu refills itself for
whoever you have selected now.

What the phrases offer depends on who they are:

| Your target | What you get |
| --- | --- |
| Another player | greetings, thanks, praise, warnings, and asking to group, trade or duel |
| Someone in your group | the same, minus asking to group — they already are |
| A warlock | all of the above plus Distrust, Demon and Fel Magic |
| An NPC | greetings and courtesies. No innkeeper is going to accept your duel |
| Anything hostile | Challenge, Taunt, Mock, Respect, Victory, Warning |

An enemy gets **Respect** on purpose. A worthy opponent deserves a word.

### In a group

Every party member gets a bubble on their frame, and the group as a whole gets
one above the party block — that is where Ready, Boss, Wipe and OOM live. When
the group wipes you are looking at the party frames, not at your own portrait.

### Saying it

Picking anything opens the confirmation:

```
 Praise  ┌──────────────────────────────────────┐
 Respect │ "Well fought, Gromkar."              │
 Joke    │ [x] applauds before Gromkar          │
         │              [Say] [Yell] [Reword]   │
         └──────────────────────────────────────┘
```

It sits against the row you clicked, and is cut to fit the phrase.

- **The channel buttons send.** One click picks how it goes out and says it.
- **You never choose a channel.** Opening from the party means it goes to party
  chat; from a target, it is said aloud. The button's tooltip says where.
- **`Reword` says it differently.** Same meaning, new words. So does clicking
  the same menu row again.
- **The line is editable.** Click the text and change it before sending.
- **Nothing you click moves.** A longer phrase grows the strip to the right;
  the buttons chain from the left edge, so rerolling never walks a button out
  from under your cursor.
- **Click anywhere else to dismiss it**, menu and all — the way a right-click
  menu behaves. Speaking closes it too.

### Gestures

Lines come with the matching emote, so your character actually bows, salutes or
roars. The checkbox shows you before it happens — untick it for this one line.

---

## Making it yours

Everything below is optional. The addon works out of the box.

### Moving things

Any control **drags with the right mouse button** and stays where you put it.
If you use replacement unit frames, this is how you move the bubbles somewhere
they make sense. `/silvertongue anchors` hides them entirely.

### The panel

`/silvertongue` opens the full panel, with every category as a tab and a preview
you can edit. Bind it under **Esc → Key Bindings → Silvertongue**.

### Your own phrases

`/silvertongue config` opens the library: everything this character can say,
with where each line came from.

- **Write your own.** Type it, pick who gets it, `Add line`.
- **Drop what you dislike.** `Drop` takes a line out for good. Dropped lines
  stay listed in grey, so you can put them back.
- **Rewrite a line.** Click it, edit it, add it, drop the original.
- **Change a gesture.** Every row has a gesture picker.

**Who gets a change** is the only thing worth understanding here. You choose
between *all my characters*, *my race*, *my class* and *my faction* — and when
you drop a line it uses whichever of those the line already belongs to. So
dropping something tagged `shared` drops it everywhere, and dropping something
tagged `your class` drops it only for that class.

That split matters: *"Totems are down"* belongs to shamans of any race, while
*"Strength and honor, brother"* belongs to orcs of any class.

Your edits are stored as changes, not as a copy, so new phrases in later
versions still reach you.

### Menu order

**Menu order**, at the top of the library's left pane, lets you rearrange any
menu — move rows, add dividing lines, or reset one to how it shipped. Your
arrangement survives updates: new entries land at the end rather than being
locked out.

---

## Commands

| | |
| --- | --- |
| `/silvertongue` | open the panel |
| `/silvertongue config` | the phrase library |
| `/silvertongue target` | the panel, on the Target tab |
| `/silvertongue party` | on the Party tab |
| `/silvertongue class` | on your class tab |
| `/silvertongue faction` | on your faction tab |
| `/silvertongue attitude` | on the Attitude tab |
| `/silvertongue anchors` | show or hide the controls on the unit frames |
| `/silvertongue minimap` | show or hide the minimap button |
| `/silver` | short form of all of the above |

---

## What you actually get

**748 handwritten lines.** No generator, no AI, no templates stitched together.
Somebody wrote all of them.

They adapt to who you are and who you are talking to. An orc shaman praising a
tauren warrior draws on different lines than a troll rogue doing the same, and
the same button gives a shaman *"Totems are down. I am set"* where it gives a
rogue *"Ready. I have been in position for some time."*

**An honest note on the voice.** The shared phrases are written in an orcish
register — blunt, proud, ancestor-minded. They fit an orc perfectly and every
other race borrows them, so a troll sounds faintly orcish until someone writes
troll lines. The Alliance set is a seed rather than a finished voice. Both are
easy to extend, and the addon is built so that adding them is writing phrases,
not writing code.

---

## Contributing

The phrases live in `Silvertongue/RP/` as plain Lua tables. Adding lines, a race,
a class or a faction is data — no other file needs to change.

`tests/run.sh` runs two suites against the source with the game API stubbed. They
check the phrase library, the layering, and that nothing reaches chat except
through an explicit send. `LUA=/path/to/lua5.1 tests/run.sh`.

---

## Credits

Bundles [Ace3](https://www.wowace.com/projects/ace3), LibDataBroker-1.1 and
LibDBIcon-1.0.
