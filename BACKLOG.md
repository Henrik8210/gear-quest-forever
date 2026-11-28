# Backlog

Ideas that are worth doing later. This file is the list to pull up when choosing the next piece of work.

## Shopping cart

Reported by Phoenix (phoenix4231) on 25 Nov 2026 in #feature-ideas. CookiesShorts seconded it and compared it to the wishlist in Forever Leveling BiS.

A tab for the pieces the player actually wants. About one or two from each slot, in an order the player sets, so the list is their own priority from most important to least. Quest tracking and the craft order stay as they are. This one is the overview of what they are going after, and it can stay up while the rest of the window is closed.

Status: later. Not in the current build.

## Import and export stat weights

The custom spec editor has Import stat weights from Pawn. The button stays hidden until Pawn is loaded and a shipped spec is selected. The click matches that class and spec to a Pawn scale and fills the weight boxes. Saving is still the player's step. The button is 190 wide.

Still later: copy the current spec's weights back out, and a Forever Leveling BiS string in either direction.

## Hit cap

Reported in the shaman channel. Every class should be able to stop valuing hit once that spec's hit cap is reached. Not in this pass.

## Tooltip specs the player chooses

breeezx wants the item tooltip to list only the specs they care about (tank and retribution, for example) instead of every spec of the class. The current lines stay. A picker for which specs appear is later.

## Bag upgrade arrows

Reported by bart.2137 on 27 Nov 2026 in #feature-ideas. An arrow on the bag icon for a piece that beats what is worn. The loot window already draws that arrow. Walking the bags on every refresh hitched, so the bag icons stay plain.

Status: later.

## Stevestock's three greens

Reported by stevestock on 27 Nov 2026 in #missing-or-wrong-items. Horde discipline priest at 22. Dervish Cape of Healing (6604), Clay Ring of Concentration (11993), and Zircon Band of Concentration (11967). The stored rows have no suffix stats, so they are not ranked. Do not invent the rolls.

Status: later.

## Quest pickup ahead of the item level

Reported by tropik2908 on 28 Nov 2026 in #bug-report. Bottle of Powderfuse Port shows as an off-hand hunt for a level 37 holy priest. The Monster Surfaces cannot be picked up until 38. The parchment already prints the pickup level in red. The hunt row itself still shows. A later pass can hold the row until that pickup level without turning Manageable Quests on.

Status: later.

## One filter for Play style

Reported by cowboybenalman and cookiesshorts on 27 Nov 2026 in #feature-ideas. Filter and Play style both hide hunts, and the combinations are hard to predict. v1.4.3 moves Play style beside Filter. It does not merge them. A later pass can make each play style a view of the same boxes a player can set by hand. CookiesShorts also asked for Current zone only as its own heading, with Quests, Crafts, and Bosses under it. Focus Zone already does the zone part.

Status: later.

## Other Sunken Temple class quests

A Better Ingredient gives Forest's Embrace, Grizzled Pelt, and Moonshadow Stave together, and finishing it marks all three obtained. The other class quests in Sunken Temple still print a choice on Wowhead. Do not mark those obtained together until each quest is checked.

Status: later.

## Unsourced recipe hunts that are in the game

27 Nov 2026. 363 recipe hunts now name the vendor on the Wowhead Forever pattern page, and 123 of those carry that pattern's reputation. The camps pin the Barrens stall and the Redridge stall. Lokhtos pins the Blackrock Depths entrances. The Shen'dralar Provisioner pins the Dire Maul doors.

The rest of the pass is only gear a player can get today. Leave out Ahn'Qiraj, Zandalar Tribe, Brood of Nozdormu, and any raid or raid trash. That is Molten Core, Blackwing Lair, Onyxia's Lair, Zul'Gurub, both Ahn'Qiraj raids, Naxxramas, Hyjal Summit, Barrow Deeps, Zul'Aman, and the Scarlet Enclave. A pattern that drops there, or a recipe that needs one of those reputations, stays off the hunt list.

These sixteen were given a vendor in that same pass and are marked unobtainable again, because they are not in the game yet. Zandalar Tribe, sold by Rin'wosho the Trader: Bloodvine Vest, Leggings, and Boots (19682, 19683, 19684), Primal Batskin Jerkin, Gloves, and Bracers (19685, 19686, 19687), Bloodsoul Breastplate, Shoulders, and Gauntlets (19690, 19691, 19692), Darksoul Breastplate, Leggings, and Shoulders (19693, 19694, 19695), Bloodvine Lens and Goggles (19998, 19999). Ahn'Qiraj, sold by Lieutenant General Andorov: Obsidian Mail Tunic (22191) and Jagged Obsidian Shield (22198). The reason key is Zandalar Tribe or Temple of Ahn'Qiraj, the same mark apply_forever_absent.py writes. Do not add any more from those two.

Still to read, one Forever page at a time, and only fill a hunt when that page names a seller, a drop, or a quest that is in the game:

- The stored seller was not opened before Wowhead returned 405. Lovingly Crafted Boomstick (Fradd Swiftgear, Jinky Twizzlefixxit), Turtle Scale Gloves (Pratt McGrubben, Jangdor Swiftstrider), Nightscape Shoulders (Jangdor Swiftstrider, Nioma), Stormcloth Gloves (Molkar, Gorhak), Runecloth Gloves (Qia), Felcloth Pants (Lorelae Wintersong), Green Dragonscale Breastplate (Masat T'andr), Blue Dragonscale Breastplate (Blimo Gadgetspring), Black Dragonscale Breastplate (Plugger Spazzring, Blackrock Depths), Ironfeather Shoulders (Gigget Zipcoil), Wicked Leather Gauntlets (Leonard Porter, Werg Thickblade), Runic Leather Headband (Jase Farlane), Shadowskin Gloves (Rikqiz), Barbaric Bracers (Saenorion, Joseph Moore), Black Whelp Tunic (Amy Davenport), Phoenix Bindings (Elaine Compton, Jornah, Dokimi, Gishah, Tamelyn Aldridge, Marcy Baker), Iron Morningstar (Gorhak, Molkar), Mithril Warhammer (Martha Wellsworth, Hamur).
- Satchel of Iron Bombs is the same Fizzlefuse and Fritz Fizzle camp already on the other engineering patterns.
- About 400 crafted hunts still have a recipe and no seller on the stored scrape. Read the pattern page. Fill the vendor, the drop, or the quest, including the reputation when the tooltip has one. Stormshroud Pants (pattern 15741) came back with an empty sold-by list, so Leonard Porter and Werg Thickblade stay off that one until a page names them. Black Dragonscale Helm (252605) is done: pattern 252939 drops from Blackhand Assassin in Blackrock Spire.
- About 128 outdoor vendors already named on a hunt still have no map pin. The coordinate cache does not have them, and the page pass stopped on 405.
- Fifteen crafted pieces name a vendor and have no profession skill number yet: Storm Gauntlets, Primal Batskin Gloves, Bloodsoul Breastplate, Bloodvine Lens, Bloodvine Goggles, Dark Iron Boots, Turtle Scale Gloves (217270), Shining Gown, Radiant Waistcord, Radiant Sandals, Whimsical Waistwrap, Gizmo Girdle, Clanking Cord, Bent Goggles, Stuckbutton Goggles. The Zandalar and Bloodvine names in that list come off with the sixteen above. Do not invent a skill of 1. Look the spell up.
- Camp recipes are bought with Soft Patches of Fur. The count is different on each pattern, so no single price was written.

Status: later. The in-game vendor hunts are in the current catalogs. The sixteen Zandalar and Ahn'Qiraj pieces are marked unobtainable and are off the lists. This pass is not.
