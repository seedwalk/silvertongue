-- Shaman.lua -- the spiritual half of a shaman. Elements, ancestors, totems.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.SHAMAN = {
    ELEMENTS = {
        "The elements answer me. They do not obey me. There is a difference.",
        "Earth, fire, water, air. Ask politely and they listen.",
        "The elements are not tools. They are neighbors.",
        "I do not command the storm. I ask it to look this way.",
        "Everything here is alive. Most people never notice.",
        "The elements are restless today. Something is coming.",
    },

    ANCESTORS = {
        "The ancestors are watching. Fight like it.",
        "Every orc who ever fell is standing behind us right now.",
        "I ask the ancestors for strength. They usually give advice instead.",
        "We do not pray to the ancestors. We answer to them.",
        "My grandfather died in chains. I do not intend to.",
        "The dead are not gone. They are simply quiet.",
    },

    SPIRITS = {
        "The spirits are restless.",
        "Listen. The spirits speak even when no one wishes to hear them.",
        "The spirits have brought us this far.",
        "Something troubles the spirits here. Tread carefully.",
        "The spirits are calm. Enjoy it. It will not last.",
        "I hear them. You would too, if you stopped talking.",
        "The spirits gave me no warning. That is its own kind of warning.",
        "They are speaking. I am not certain I like what they are saying.",
        "The spirits do not lie. They simply do not explain.",
        "Peace to the spirits of this place. We are only passing through.",
    },

    TOTEMS = {
        "Mind the totems.",
        "Stay near the totems. They are here for a reason.",
        "Someone touched my totem.",
        "The totems are fine. I checked.",
        "Totems down. Use them or do not, but they are there.",
        "A totem is not decoration. Stand in it.",
        "I carve them myself. Do not step on them.",
        "The totems will hold. I am less certain about the rest of us.",
        "Four totems. Four elements. One very tired shaman.",
        "If you move out of the totem, that is between you and the ancestors.",
    },

    EARTH = {
        "The earth remembers everything. Every step, every grave.",
        "Stone is patient. I try to learn from it. I fail often.",
        "Earth beneath us. Let it hold.",
        "The ground here is old and it is angry.",
        "Strength of earth. Nothing moves me.",
    },

    FIRE = {
        "Fire is honest. It takes what it is given and gives back light.",
        "Flame does not negotiate.",
        "Let it burn. Some things deserve it.",
        "Fire is the quickest of them and the least patient.",
        "The flames are hungry today.",
    },

    WATER = {
        "Water mends what fire takes.",
        "The tide does not hurry and it is never late.",
        "Water finds a way through stone. Be like that.",
        "Let the water close your wounds. Then stand.",
        "Still water, steady hand.",
    },

    AIR = {
        "The wind carries news if you know how to listen.",
        "Air is the whisperer. It tells me things it should not.",
        "The storm is mine to ask, not to own.",
        "Lightning is simply the sky losing its patience.",
        "Wind at our backs. Move.",
    },

    BLESSING = {
        "May the elements walk with you.",
        "The spirits guard your road, friend.",
        "Earth hold you, fire warm you, water mend you, wind guide you.",
        "Ancestors watch over you. You will need it.",
        "Go with the blessing of the elements. It is all I have to give.",
        "May you die old, loud, and surrounded by enemies.",
    },

    WARNING = {
        "The elements are screaming here. Something is deeply wrong.",
        "Stop. This place is sick.",
        "The spirits here do not rest. Someone made sure of that.",
        "I feel fel in this ground. Step carefully.",
        "The earth is wounded here. Do not make it worse.",
        "Whatever happened in this place, the elements have not forgiven it.",
    },
}
