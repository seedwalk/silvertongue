# Silvertongue

Roleplay phrases for World of Warcraft, on the frames you are already watching.

You know what is happening. Silvertongue knows how to say it.

Click a target, pick *Praise*, read the line, click *Say*. Three seconds, and
your character said something in character instead of `nice heals bro`.

**Burning Crusade Classic** (Interface 20506).

**[silvertongue on the web](https://seedwalk.github.io/silvertongue/)** — what it
looks like, and the current download.

---

## Install

1. Download the latest zip from **[Releases](../../releases)**.
2. Unzip it. You should have a folder called `Silvertongue`.
3. Put that folder into your AddOns directory:

```
World of Warcraft/_anniversary_/Interface/AddOns/Silvertongue/
```

4. Restart the game — not `/reload`. New addons are only found at launch.

You should end up with `Interface/AddOns/Silvertongue/Silvertongue.toc`. If you
have an extra folder in between, the game will not see it.

There is nothing to configure. It works on any character the moment it loads.

**Which build to take.** A tag like `v0.2.0` is a finished release; `rc-0.2.0`
is a candidate that passes the tests but has had less time in a real game. Both
install identically, and the download button on the site always points at
whichever is newest.

**Updating.** Replace the folder. Your own phrases, your menu order and where
you dragged things live in the game's saved variables, not in the addon folder,
so they survive.

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
| The other faction | Challenge, Taunt, Mock, Respect, Victory, Warning |
| Anything hostile | the same six |

An enemy gets **Respect** on purpose. A worthy opponent deserves a word.

**The other faction is not a friend just because you cannot hit him.** An
Alliance player standing peacefully in a neutral zone cannot be attacked, and
an earlier version therefore offered him a group invite. Whose side they are on
is a different question from whether a fight is possible, and it is the one that
decides what is worth saying.

Speaking to them is still worth doing, though not for them: cross-faction speech
arrives as gibberish, so the only channels offered are Say and Yell and the
tooltips say plainly that your own side nearby is the audience. What does cross
is the **gesture** — an emote is an animation and a sentence in the reader's own
language, so a bow or a rude one lands when nothing typed does.

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

Open the **Looking For Group** window and list yourself. Your own row grows a
speech bubble, and that is where advertising lives — there was a second bubble
on the window itself and it was removed, because everything it offered was on
that row already, with worse information: it guessed the dungeon from your level
while the row reads it off your listing.

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

**Roles.** On your own the advert can say what you would be doing — *"LFG
Scarlet Monastery, healing. Troll shaman, 36"* — and only for the roles your
class could actually take. That is the first thing a group leader reads for.
Specs are not readable, so this stays something you choose to say rather than
something inferred about you.

**Which dungeon.** The one your listing names. The game publishes it, so there
is nothing to guess and nothing to pick: if you are listed for Scarlet Library,
an advert for Razorfen Kraul because it suits your level is simply wrong. With
no listing you get a short picker of the dungeons nearest your level.

**The channel.** If you are not in **LookingForGroup** it joins you, because
pressing "looking for a group" is a clear statement that you want to be where
groups are found — and it makes sure a chat window is actually carrying the
channel, since being in one and seeing it are different things. Advertising
somewhere you cannot read is not advertising: the replies come back there.

Joining and speaking cannot happen in the same press. A public channel will not
take a line without a real click behind it, and once the join has come back the
click is over — so the first press joins and says that the next one will send.
In practice it rarely comes up, because opening the row is itself a click and
the channel is ready by the time you have picked a line.

The line is never said aloud to whoever is standing next to you instead.

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
in a position to invite.

On **your own** listing you get both halves, because both are true: the listing
is the group you are forming, so asking for what it is short of belongs there —
and while you are still the only one in it, you are also somebody offering
himself. Alone, the advert about you leads; once somebody has joined, recruiting
does.

Nothing here searches on your own behalf: it reads whatever your own refresh
brought back.

### Whispers

A whisper is the one conversation the addon could not reach. The person is not
your target, not in your group, not in a listing — they are a line of text that
scrolls away, and once it has scrolled there is nothing left to click.

So whispers, guild lines and the lines the game writes itself grow the bubble
beside the name:

```
[Baddiebolts] 💬 has invited you to join a group.
[Diego Viñas] 💬 (Olfer) has come online.
```

Press it and that person gets **a window of their own**:

```
┌──────────────────────────────────────┐
│ 💬 Rhottyn                      − ✕ │
│    Troll Shaman, 44 - seen 3 days ago│
│                                      │
│ 13:36 Rhottyn: can you make me one?  │
│ 13:36 Gromkar: I can do that. Where? │
│                                      │
│ 💬 👥 🪙                             │
│ [                                  ] │
└──────────────────────────────────────┘
```

- **One per person, several at once**, draggable, and they stay put while you do
  other things. This is the only window in the addon with an ✕, because
  everything else behaves like a context menu and closes when you click away.
- **The conversation is kept**, both sides, across sessions. Open somebody six
  weeks later and it is still there. Five hundred lines per person, a hundred
  and twenty people, nothing older than six months — generous enough for months
  of conversation and bounded enough that the saved variables file does not grow
  forever.
- **There is a line to type in**, because it is a whisper window. It never takes
  the keyboard on its own: you click in to type, and Escape or Enter hands the
  keys back. Autofocus here would mean pressing W to walk and writing a *w* into
  somebody's whisper.
- **Speak** opens the phrases — answering things people *ask*, which the party
  lines never covered: *on my way*, *in a moment*, *cannot right now*, *where are
  you*, and *yes, I can do that*, which is layered by your class because what
  people pester you for depends on what you can do. Mages get portals, warlocks
  summons, rogues locks.
- **No gesture goes out with a whisper.** A bow aimed at someone who is not on
  your screen plays to an empty room.
- **Invite** works by name. **Trade** is off unless they are standing next to
  you and selected, which in a whisper is the exception.

**Who they are** is pieced together from whatever the game will say, and every
gap is stated rather than hidden. Every chat message carries the sender's GUID,
which is race and class for nothing and works across realms; the guild roster
adds level; a Battle.net friend the client simply knows outright. A line that is
remembered rather than current is dated — *seen 3 days ago* — because stating a
level from three months ago as though it were true today is worse than saying
nothing. If nothing is known, it says **Unknown**.

**Battle.net friends** get a window too, keyed by account rather than by
character, since the same friend is somebody else tomorrow and the conversation
is the same one. Those go out through the Battle.net route, so they reach
someone on the other faction or another realm, where an ordinary whisper would
simply fail.

The chat bubble can be switched off per kind — whispers, guild, system lines,
friends — and the target board has an **Open a window** row, which is how a
conversation starts before they have spoken.

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
| `/silvertongue probe` | what the addon found on your frames, and what it has stored |
| `/silvertongue chatdebug` | print the next chat lines raw, for reporting a bug |
| `/silver` | short form of all of the above |

---

## What you actually get

**Around 1,600 handwritten lines.** No generator, no AI, no templates stitched together.
Somebody wrote all of them.

They adapt to who you are and who you are talking to. An orc shaman praising a
tauren warrior draws on different lines than a troll rogue doing the same, and
the same button gives a shaman *"Totems are down. I am set"* where it gives a
rogue *"Ready. I have been in position for some time."*

Every class has a tab of its own, every race has a voice, and a handful of
race-and-class pairings have a line that belongs to the pairing rather than to
either half: a blood elf paladin knows his order took the Light by force, and
says so where no other paladin does.

**On the shared voice.** The pool underneath everything was once written in an
orcish register, and every other race borrowed it. An audit found 18% of it
carried words belonging to one people — ancestors, spirits, the Horde, brothers
— so those 63 lines were moved into the orc layer where they belong and the
other nine races were written up to match on the same intents. The shared pool
is 369 neutral lines now, and a test fails if a racial word appears in one of
them. A line that needs a people behind it goes in a race layer.

---

## Contributing

The phrases live in `Silvertongue/RP/` as plain Lua tables. Adding lines, a race,
a class or a faction is data — no other file needs to change.

`LUA=/path/to/lua5.1 tests/run.sh` runs three checks against the source with the
game API stubbed: that the TOC and the file tree agree, that the phrase library
holds together, and that the interface behaves — including that nothing reaches
chat except through an explicit send. They run on every push.

Releases are cut by tagging. `rc-0.2.0` publishes a pre-release, `v0.2.0` a
finished one, and the zip contains only the addon folder. The version in the TOC
is stamped from the tag, so it is never out of step.

---

## Credits

Bundles [Ace3](https://www.wowace.com/projects/ace3), LibDataBroker-1.1 and
LibDBIcon-1.0.
