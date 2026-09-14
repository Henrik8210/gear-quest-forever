# -*- coding: utf-8 -*-
"""Hand-written lore. Two tables, both deliberately conservative.

BOSS_LORE covers the 67 named bosses that account for every shipped epic drop. Written
once per boss rather than once per item, so all 275 items inherit it. A boss I could not
state something solid about gets no entry, and its items simply carry no lore -- that is
better than a sentence that sounds right and is not. The two Blackwing Lair trash
dragonkin are omitted for the same reason: they have no story.

ITEM_LORE overrides everything for the handful of items whose story IS the item.
"""

ITEM_LORE = {
 19019: "Forged for a Windseeker of the elemental lords and lost for an age. Waking it "
         "again takes the bindings of the left and right hand, the blessing of Thunderaan's "
         "own essence, and a smith willing to defy Ragnaros.",
 17182: "Ragnaros wielded this hammer as the Firelord. Reforging it means taking the Eye "
         "of Sulfuras from Ragnaros himself and setting it into the Sulfuron Hammer.",
 13262: "The blade the Silver Hand carried against the Scourge, and the one Tirion "
         "Fordring's order was built around. Corrupted when Renault Mograine used it on "
         "his own father, Alexandros, in the Scarlet Monastery.",
 22589: "The Guardian's staff, broken and scattered. Rebuilding it means gathering forty "
         "splinters from Naxxramas, the base from Kel'Thuzad, and carrying it to the ruin "
         "of Karazhan where Medivh once held it.",
 22630: "The Guardian's staff, broken and scattered. Rebuilding it means gathering forty "
         "splinters from Naxxramas, the base from Kel'Thuzad, and carrying it to the ruin "
         "of Karazhan where Medivh once held it.",
 22631: "The Guardian's staff, broken and scattered. Rebuilding it means gathering forty "
         "splinters from Naxxramas, the base from Kel'Thuzad, and carrying it to the ruin "
         "of Karazhan where Medivh once held it.",
 22632: "The Guardian's staff, broken and scattered. Rebuilding it means gathering forty "
         "splinters from Naxxramas, the base from Kel'Thuzad, and carrying it to the ruin "
         "of Karazhan where Medivh once held it.",
 18608: "Reforged from Anathema, its shadow half. A priest chooses one and gives up the "
         "other -- the same staff, turned toward healing instead of harm.",
 18348: "Quel'Serrar, the High Blade, reforged in the breath of Onyxia herself. The "
         "unfinished blade has to be held out to her to be tempered.",
}

BOSS_LORE = {
 # ---- Naxxramas -----------------------------------------------------------
 "Kel'Thuzad": "Once an archmage of the Kirin Tor, he left Dalaran to found the Cult of "
   "the Damned and served Ner'zhul willingly. Killed at Andorhal and raised as a lich, "
   "he rules Naxxramas from a phylactery at its heart.",
 "Sapphiron": "A blue dragon slain in Northrend and raised as a frost wyrm. He guards the "
   "final approach to Kel'Thuzad's chamber.",
 "Patchwerk": "An abomination stitched together from the Scourge's leftovers, built for "
   "nothing but raw strength.",
 "Thaddius": "Two abominations sewn into one and animated with stolen lightning -- one of "
   "Kel'Thuzad's more ambitious experiments in the Construct Quarter.",
 "Grobbulus": "A walking vat. The Scourge used him to field-test new strains of the "
   "plague on whatever wandered into Naxxramas.",
 "Gluth": "A stitched hound kept half-starved on purpose, so it would eat anything the "
   "Construct Quarter sent its way.",
 "Instructor Razuvious": "A death knight who trains the Scourge's new officers. He is too "
   "strong for his own students to touch, which is exactly the point of the lesson.",
 "Gothik the Harvester": "Razuvious's colleague in the Military Quarter, who fights from "
   "behind his own dead and keeps sending them forward.",
 "Noth the Plaguebringer": "A necromancer of the Plague Quarter, promoted for his skill "
   "at raising what he had just finished killing.",
 "Heigan the Unclean": "Keeper of Naxxramas's plague works, and of the corridor of "
   "eruptions that has killed more raiders than he has.",
 "Loatheb": "A fungal horror grown in the Plague Quarter's spore vats -- less a creature "
   "than a crop that got out of hand.",
 "Anub'Rekhan": "A crypt lord of Azjol-Nerub who took Arthas's side. He holds the "
   "Arachnid Quarter's outermost hall.",
 "Grand Widow Faerlina": "A worshipper of Kel'Thuzad who brought her followers with her "
   "into undeath, and still commands them.",
 "Maexxna": "A giant spider webbed into the depths of the Arachnid Quarter, fed on "
   "whatever the Scourge no longer needs.",
 # ---- Blackwing Lair ------------------------------------------------------
 "Nefarian": "Deathwing's son, working under Blackrock Mountain to breed the chromatic "
   "flight -- dragons carrying the blood of all five. He spent years in Stormwind's court "
   "as Lord Victor Nefarius while the work went on.",
 "Chromaggus": "Nefarian's best result: a two-headed chromatic horror carrying the "
   "breath of every dragonflight at once.",
 "Razorgore the Untamed": "Set to guard the stolen dragon eggs. The raid takes control of "
   "the orb he is chained to and turns him on the clutch he was protecting.",
 "Vaelastrasz the Corrupt": "A red dragon of Alexstrasza's flight, broken by Nefarian's "
   "experiments. He asks to be killed before the corruption finishes taking him, and "
   "apologises while he fights.",
 "Broodlord Lashlayer": "Nefarian's lieutenant, posted to hold the only way deeper into "
   "the lair.",
 "Ebonroc": "One of three drakes guarding Nefarian's inner lair, and the one that heals "
   "itself off the wounds it deals.",
 "Firemaw": "One of Nefarian's three guardian drakes, holding the suspended walkways "
   "above the lair floor.",
 "Flamegor": "The last of Nefarian's three drakes, and the one that simply gets angrier "
   "as the fight goes on.",
 # ---- Molten Core ---------------------------------------------------------
 "Ragnaros": "The Firelord, one of the four Elemental Lords, bound to the Elemental Plane "
   "until the Dark Iron dwarves summoned him under Blackrock Mountain. The summoning "
   "cracked the mountain open and made the Molten Core.",
 "Magmadar": "A core hound of the deep fire, kept as a guard beast and fed by Ragnaros's "
   "lieutenants.",
 "Garr": "A lieutenant of Ragnaros who fights surrounded by his Firesworn, and grows "
   "stronger each time one of them falls.",
 "Baron Geddon": "One of Ragnaros's most destructive lieutenants -- he ends the fight by "
   "turning himself into the bomb.",
 "Shazzrah": "A flame imp given rank, and the reason the Core's casters cannot be left "
   "standing together.",
 "Gehennas": "A hound handler of Ragnaros's court, who curses healing shut before the "
   "fighting starts.",
 "Lucifron": "The first of Ragnaros's lieutenants a raid meets, and the one that turns "
   "your own spells against you.",
 "Golemagg the Incinerator": "A core rager grown past all the others, flanked by two "
   "hounds that cannot be killed while he stands.",
 "Sulfuron Harbinger": "High priest of Ragnaros's flame, who keeps four healers at his "
   "back and lets them work.",
 "Ambassador Flamelash": "Ragnaros's envoy to the Dark Iron in Blackrock Depths, sent to "
   "keep the dwarves loyal to the Firelord.",
 # ---- Ahn'Qiraj -----------------------------------------------------------
 "C'Thun": "An Old God, buried under Ahn'Qiraj by the titans rather than killed. It has "
   "been whispering to the qiraji ever since, and the whole war exists because it never "
   "stopped.",
 "The Prophet Skeram": "C'Thun's mouthpiece. Everything the qiraji believe, they believe "
   "because he told them the Old God said it.",
 "Battleguard Sartura": "The qiraji empire's finest soldier, who fights with her honour "
   "guard and refuses to be separated from them.",
 "Fankriss the Unyielding": "A vast qiraji burrower that spawns its young mid-fight and "
   "hurls intruders into the walls.",
 "Princess Huhuran": "A qiraji brood matron whose poison is potent enough that the fight "
   "is really a race against her venom.",
 "Viscidus": "A living mass of qiraji poison. It has to be frozen solid and then "
   "shattered, which is not how most things die.",
 "Ouro": "A sandworm grown enormous under the desert, surfacing only to feed.",
 "Emperor Vek'lor": "Twin emperor of the qiraji, and the one who inherited C'Thun's gift "
   "for magic instead of his brother's strength. Neither twin can be killed far from the "
   "other.",
 "Emperor Vek'nilash": "Twin emperor of the qiraji, and the stronger arm of the pair. "
   "Kill one and the other heals him, so both must fall together.",
 "Lord Kri": "One of the three qiraji councillors who fight as one -- kill any of them "
   "and the survivors grow stronger.",
 "Princess Yauj": "One of the qiraji triumvirate, who heals her fellow councillors and "
   "calls in broodlings when pressed.",
 "Vem": "The third of the qiraji council, who charges the moment the fight begins and "
   "does not stop.",
 "Ossirian the Unscarred": "A qiraji lieutenant holding the Ruins, whose name stopped "
   "being accurate the first time a raid used the crystals against him.",
 "Moam": "A stone giant pressed into qiraji service, who drains the mana of everyone "
   "fighting him and turns to rock when full.",
 "General Rajaxx": "Commander of the qiraji army, who threw wave after wave at the Scarab "
   "Wall in the War of the Shifting Sands and came back to do it again.",
 # ---- Zul'Gurub -----------------------------------------------------------
 "Hakkar": "The Soulflayer, a blood god the Atal'ai priests summoned into Zul'Gurub. He "
   "feeds on the blood of his own worshippers, which is the part they had not planned for.",
 "Jin'do the Hexxer": "Hakkar's chief hexxer, who fights by binding pieces of his "
   "enemies' spirits and setting them loose.",
 "High Priest Thekal": "One of Hakkar's high priests, who returns to his feet twice "
   "before he stays down.",
 "Gahz'ranka": "A gargantuan deep-sea creature in Zul'Gurub's pools, which has to be "
   "fished up before it can be fought.",
 # ---- dragons of the Emerald Nightmare -----------------------------------
 "Emeriss": "One of Ysera's four green consorts, corrupted by the Emerald Nightmare and "
   "now roaming Feralas, rotting the ground it stands on.",
 "Ysondre": "A green dragon of Ysera's flight, turned by the Nightmare and hunted across "
   "Feralas ever since.",
 "Lethon": "One of the corrupted green dragons, who tears the shades out of the living "
   "and drinks them back down.",
 "Taerar": "A Nightmare-corrupted green dragon who splits himself into shades rather than "
   "face a fight whole.",
 # ---- world and dungeon --------------------------------------------------
 "Onyxia": "Deathwing's daughter and Nefarian's sister. She spent years in Stormwind as "
   "Lady Katrana Prestor, advising the throne she was working to undermine.",
 "Azuregos": "A blue dragon set by Malygos to watch over arcane secrets in Azshara, and "
   "not remotely pleased about visitors.",
 "Lord Kazzak": "A pit lord left behind when the Legion's invasion collapsed, still "
   "holding the Tainted Scar where the Dark Portal's blast burned the land.",
 "Emperor Dagran Thaurissan": "Emperor of the Dark Iron, whose ancestor's summoning of "
   "Ragnaros doomed the clan. He took Moira Bronzebeard prisoner and she chose to stay.",
 "Ras Frostwhisper": "A human lord who traded his life for undeath and became a lich in "
   "Scholomance. Killing him takes a blade specifically made to sever the bargain.",
 "Princess Theradras": "A princess of the earth elementals and the reason Maraudon is "
   "poisoned -- she holds the body of Zaetar, her demigod consort, at its heart.",
 "Shade of Eranikus": "What is left of a green dragon who went into the Sunken Temple "
   "after the Nightmare and did not come out himself.",
 "Arcanist Doan": "The Scarlet Crusade's chief scholar, who guards the Monastery library "
   "and its collection rather more aggressively than a librarian should.",
 "Warchief Rend Blackhand": "Son of Blackhand and the last warchief of the Dark Horde, "
   "still holding Blackrock Spire long after the rest of the Horde moved on.",
 "Overlord Wyrmthalak": "The black dragonflight's overseer in Lower Blackrock Spire, "
   "keeping the orcs there in line on Nefarian's behalf.",
}

# ---------------------------------------------------------------------------
# Item-first lore. Henrik: "for gear I mean you had to explain some facts/story of
# the gear ... Might of Menethil must have a story or at least King Menethil has, give
# some of that background maybe rather than explain who Kel'Thuzad is - we have in
# descriptions who the boss is in those cases."
#
# Right, and that reordered the whole thing: the instructions line already says "Drops
# from Kel'Thuzad in Naxxramas", so repeating who Kel'Thuzad is spends the one interesting
# line on something already on screen. An item's own story -- where its NAME comes from,
# or why players remember it -- is the thing worth the space. Boss lore is now the last
# fallback, not the first choice.
ITEM_LORE_EXTRA = {
 # --- named for someone -----------------------------------------------------
 22798: "Menethil was the royal line of Lordaeron -- King Terenas, and his son Arthas, "
        "who became the Lich King. A warhammer carrying that name, guarded by the lich "
        "who served Arthas, is not an accident.",
 6324:  "Archmage Arugal called the worgen to Silverpine to defend against the Scourge, "
        "lost control of them immediately, and went mad in Shadowfang Keep among the "
        "things he had summoned.",
 6392:  "Arugal's own belt. He summoned the worgen to save Silverpine, then lost his mind "
        "in Shadowfang Keep surrounded by what he had called.",
 9419:  "Galgann Firehammer led the Dark Iron dig into Uldaman, chasing titan secrets he "
        "had no way of understanding. He is still down there.",
 9389:  "Revelosh was a Shadowforge explorer who went into Uldaman looking for the origin "
        "of the dwarves, and became part of the ruin instead.",
 6908:  "Ghamoo-ra is the ancient turtle the naga keep in Blackfathom Deeps -- old enough "
        "that the Twilight cultists there treat it as part of the temple.",
 6902:  "Serra'kis is the great water beast the naga breed in the flooded halls of "
        "Blackfathom Deeps, and the reason the lower temple is under water at all.",
 10413: "The Druids of the Fang broke from Cenarius and let the Emerald Nightmare into "
        "the Wailing Caverns. These were theirs.",
 12940: "Rend Blackhand's own blades, named for the Dal'Rend line. He kept them while "
        "holding Blackrock Spire as the last warchief of the Dark Horde.",
 12939: "The shield half of Rend Blackhand's pair. A warrior who takes only one of the two "
        "gives up the set bonus they were made to share.",
 15806: "Mirah Chandler's song, given for finishing a chain of favours in the Barrens -- "
        "the reward players remember long after they forget the errands.",
 2243:  "Edward the Odd was a mage remembered mostly for being odd. The sword he left "
        "behind casts spells at random, which fits.",
 # --- remembered for what they DID -----------------------------------------
 14551: "Famous long before anyone worked out why. In Classic these carried +7 to axes, "
        "daggers and swords, and weapon skill quietly cut miss, dodge and parry AND the "
        "glancing-blow penalty -- worth around 10% more damage to a dual-wielding warrior, "
        "and more still to anyone without a racial weapon bonus. Players dismissed them as "
        "junk mail until the maths got out, and the auction price went from a few gold to "
        "well past a hundred. In Burning Crusade the weapon skills are gone, replaced by "
        "+19 hit and +17 expertise -- still excellent, no longer legendary.",
 11815: "Prints five Strength and eight Stamina and is worth vastly more than that: the "
        "extra attack it grants is the reason a Blackrock Depths trinket stayed in raid "
        "sets for years.",
 9449:  "A Gnomeregan oddity whose Use effect grants a huge burst of attack speed. Feral "
        "druids kept it for that alone, because it works in cat form -- and it has limited "
        "charges, so every use is a decision.",
 871:   "Two extra attacks on a proc, on a fast axe. Warriors farmed Dire Maul for this "
        "one item and nothing else.",
 9640:  "A plain plate glove that became famous for its random enchants -- the of Strength "
        "roll is a 7.9% chance and was worth chasing over guaranteed epics for years.",
 12640: "A crafted helm that outlived several tiers of raid gear. Its plans were the thing "
        "guilds actually fought over.",
 12592: "Shahram is summoned by the sword itself, at random, and may bless you or curse "
        "you with no say in the matter.",
 1728:  "Teebu's blade sets things on fire for reasons no one has ever explained. It is "
        "famous for being almost useless and deeply desirable at the same time.",
 6975:  "The Whirlwind Axe comes from an elemental trial a warrior has to complete alone. "
        "Three weapons come from the same chain and you keep only one.",
 6977:  "One of three weapons from the same solitary warrior trial. Choosing it means "
        "giving up the axe and the staff for good.",
 # --- legendaries and the great named blades --------------------------------
 22691: "The Ashbringer after Renault Mograine used it on his own father. It weeps in the "
        "Scarlet Monastery, and the undead of Naxxramas recoil from anyone carrying it.",
 18609: "Anathema, the shadow half. A priest reforges one staff or the other from the same "
        "Eye of Shadow, and the choice cannot be taken back cheaply.",
 17068: "Named for what it does. The Deathbringer was carried out of Scholomance, which is "
        "not a place that gives things up willingly.",
 19364: "Ashkandi belonged to the Brotherhood of the Light -- the order that kept fighting "
        "the Scourge after the Silver Hand broke apart.",
 19334: "The Untamed Blade remembers being wielded by something that was not a person, and "
        "hands a little of that back to whoever swings it.",
 17076: "Bonereaver's Edge strips the armour off whatever it hits. Ragnaros's court had "
        "little use for subtlety.",
 18816: "Perdition's Blade came out of the Molten Core and is still the shape a warrior "
        "pictures when they think of a Classic raid weapon.",
 19352: "Nefarian's chromatic experiment, made into a sword. It carries the blood of every "
        "dragonflight and none of their loyalty.",
 19351: "Maladath is a black dragonflight blade taken from Blackwing Lair -- the runes on "
        "it are Nefarian's work, not the smith's.",
 23206: "Struck for the war against the Scourge and the Old Gods. It does nothing at all "
        "against anything else, which is the point of the mark.",
 18404: "One of Onyxia's own teeth, taken after she was finally dragged out of Stormwind's "
        "court and killed in her lair.",
 19406: "Cut from the fang of one of Nefarian's drakes. Tanks wore it for the stun it "
        "shrugs off, not the numbers on it.",
 19950: "The Zandalari gave these charms to those who fought Hakkar in Zul'Gurub. It costs "
        "the wearer health to hit harder, which is very much a troll bargain.",
 18842: "Broken off the Dark Iron's own hierarchy of command. A staff that says who is in "
        "charge is worth more than one that only casts.",
}

ITEM_LORE.update(ITEM_LORE_EXTRA)
