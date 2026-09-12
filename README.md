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
 🎲 Group        finding one, or filling yours
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

There is also an older tabbed panel at `/silvertongue panel`, with every
category as a tab and an editable preview. The contextual menus have largely
replaced it.

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

### Finding a group

A speech bubble next to the refresh button in the **Looking For Group** window,
because that is the only place you ever want it.

It puts your advert on the **LookingForGroup** channel, in character:

> *"A troll rogue with time on his hands and nothing to kill. Invite me."*

Which is the point. `Rogue 36 LF Scarlet` is a classified ad, and one more of
those is worth nothing — somebody who reads a line with a character behind it
remembers who wrote it.

On your own it offers to say you are looking. In a group it switches to
recruiting, and talks in **roles** when it can:

> *"LFM Scarlet Monastery, need a tank and a healer — we have 2 dps."*

Where that comes from depends on what the game will tell it. On **your own
listing** it is exact: the game publishes which slots are filled and which are
open, the same numbers that draw the role squares, so it never asks for a healer
you already have. In a group without a listing it uses assigned roles if there
are any, and otherwise falls back to naming the classes — which are always
true. It never reads a role off a class: a warrior might be fury, and claiming
you have a tank when you do not is how a group wastes an evening.

If you have not joined the LookingForGroup channel, the line simply will not
send. It is never said aloud to whoever is standing next to you instead.

### In the group browser

Open the **Looking For Group** window and every row grows a small speech bubble
beside the name. It reads the listing — who posted it, their level and class,
what they are running, and what they are short of — and offers:

```
 Chudlightly
 Scarlet Monastery - needs a tank, 2 dps
 ─────────────────────────────
 Offer to join
 Offer damage          ← because that is the place they have open
 ─────────────────────────────
 Invite them
```

The offers whisper them in character, with their dungeon already named because
the listing said so. There is no "ask what they need": the game publishes it, so
asking would waste their time. Instead you are offered **the roles they are
actually short of, and that your class could fill** — a shaman is offered the
open healer and damage places, never the tank one.

`Invite them` only appears when the game would allow it — a lone player, and you
in a position to invite. On **your own** listing the whole menu flips: it
recruits for you rather than offering to join yourself.

Nothing here searches on your own behalf: it reads whatever your own refresh
brought back.

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

### Your own phrases

`/silvertongue` opens the library: everything this character can say, with where
each line came from. Bind it under **Esc → Key Bindings → Silvertongue**.

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
| `/silvertongue` | open Silvertongue |
| `/silvertongue panel` | the older tabbed panel |
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

**Around 1,400 handwritten lines.** No generator, no AI, no templates stitched together.
Somebody wrote all of them.

They adapt to who you are and who you are talking to. An orc shaman praising a
tauren warrior draws on different lines than a troll rogue doing the same, and
the same button gives a shaman *"Totems are down. I am set"* where it gives a
rogue *"Ready. I have been in position for some time."*

Every class has a tab of its own, every race has a voice, and a handful of
race-and-class pairings have a line that belongs to the pairing rather than to
either half: a blood elf paladin knows his order took the Light by force, and
says so where no other paladin does.

**An honest note on the voice.** The shared pool underneath it all is written in
an orcish register — blunt, proud, ancestor-minded. The race layer colours over
it, but on any intent a race does not touch, a draenei still borrows an orc's
cadence. Fixing that means giving a race its own lines outright, which the addon
supports and which is writing phrases rather than writing code.

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
