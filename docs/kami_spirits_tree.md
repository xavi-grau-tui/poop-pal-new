# KamiTomo: the 120 spirits, slot by slot

Generated from `data/evolution_tree.json` (2026-11-04). Each row is one **slot** of the evolution tree.
The **id** stays forever (the game and saves use it). The current name and one-liner are only a hint
from the old poop-pal era: a concept may rename and redesign any slot freely, keeping its place in the
tree (its realm, its stage, what it grows from and the flavour that leads to it).

How the tree works, per realm (24 spirits):

- **1 baby**: where every spirit of the realm starts.
- **5 kids**: the baby fed one of the 5 flavours (one kid per flavour).
- **15 adults**: each kid grows into one of 3 adults, depending on what it's fed:
  - **Pure**: fed its realm's own flavour; the realm at its clearest.
  - **Peak**: fed the kid's own flavour again; the kid's idea at its best.
  - **Chaos**: fed any of the other three; a strange, surprising mix.
  - One kid per realm splits differently: **Ultra** (its realm's flavour; the only path to the
    legend), **Bloom** (a gentler mix) and **Clash** (a clashing mix).
- **2 mutants**: any adult fed Tech food (Tech) or Cosmic food (Cosmic).
- **1 legend**: the Ultra adult fed the realm's legendary food.

Flavours: Sprouty, Sweet, Savory, Spicy, Sour. Realms: Mountain, Moon, Fox, Fire, River.

## Mountain realm (fed mostly Sprouty)

| # | id | stage | grows from | fed | branch | old name: one-liner (hint only) |
|---|---|---|---|---|---|---|
| 1 | `bud` | baby | (start) | Sprouty |  | Bud: A seed that stood up. |
| 2 | `peapod` | kid | `bud` | Sprouty |  | Peapod: Three peas, one opinion. |
| 3 | `usagi` | kid | `bud` | Sweet |  | Usagi: Pounds mochi under the moon. |
| 4 | `kakiage` | kid | `bud` | Savory |  | Kakiage: A tempura fritter that walks. |
| 5 | `tengu` | kid | `bud` | Spicy |  | Tengu: A forest goblin with a red face. |
| 6 | `kiwi` | kid | `bud` | Sour |  | Kiwi: Fuzzy outside, sour inside. |
| 7 | `avocado` | adult | `peapod` | Sprouty | Ultra | Avocado: A pea that grew up: green, big, proud of its stone. |
| 8 | `melon_pan` | adult | `peapod` | Sour / Sweet | Bloom | Melon Pan: A sweet bun with a melon-skin crust. |
| 9 | `wasabi_pea` | adult | `peapod` | Savory / Spicy | Clash | Wasabi Pea: Crunchy, green, furious. |
| 10 | `yomogi` | adult | `usagi` | Sprouty | Pure | Yomogi: Mugwort dumplings on a stick. Earthy, chewy. |
| 11 | `usagi_manju` | adult | `usagi` | Sweet | Peak | Usagi Manju: A rabbit-shaped bun, blue bean paste inside. |
| 12 | `yamabiko` | adult | `usagi` | Savory / Spicy / Sour | Chaos | Yamabiko: Repeats everything you shout. |
| 13 | `kinoko` | adult | `kakiage` | Sprouty | Pure | Kinoko: A mushroom yokai. Do not eat. |
| 14 | `mujina` | adult | `kakiage` | Savory | Peak | Mujina: A badger that is mostly rumours. |
| 15 | `kodama` | adult | `kakiage` | Sweet / Spicy / Sour | Chaos | Kodama: A tree spirit. Nods slowly. |
| 16 | `karasu_tengu` | adult | `tengu` | Sprouty | Pure | Karasu Tengu: A crow tengu. Guards the mountain path. |
| 17 | `horseradish` | adult | `tengu` | Spicy | Peak | Horseradish: Clears your nose from a mile away. |
| 18 | `komainu` | adult | `tengu` | Sweet / Savory / Sour | Chaos | Komainu: A stone lion-dog that guards the gate. |
| 19 | `kappa` | adult | `kiwi` | Sprouty | Pure | Kappa: Keep its head plate wet. |
| 20 | `gherk` | adult | `kiwi` | Sour | Peak | Gherk: A gherkin that learned to crawl. |
| 21 | `kiwi_bird` | adult | `kiwi` | Sweet / Savory / Spicy | Chaos | Kiwi Bird: The fruit grew a beak. Finally friends. |
| 22 | `karakuri` | mutant | any adult | Tech | Tech | Karakuri: A clockwork doll that serves tea. |
| 23 | `zorb` | mutant | any adult | Cosmic | Cosmic | Zorb: Ate alien goo. Three eyes, no worries. |
| 24 | `world_tree` | legend | `avocado` | Golden Seed | Legend | World Tree: A forest spirit that keeps the gut green. |

## Moon realm (fed mostly Sweet)

| # | id | stage | grows from | fed | branch | old name: one-liner (hint only) |
|---|---|---|---|---|---|---|
| 25 | `nib` | baby | (start) | Sweet |  | Nib: A cocoa bean with something to say. |
| 26 | `leafwing` | kid | `nib` | Sprouty |  | Leafwing: Looks exactly like a leaf. On purpose. |
| 27 | `fudge` | kid | `nib` | Sweet |  | Fudge: Fudge. Dense. Dependable. |
| 28 | `glazy` | kid | `nib` | Savory |  | Glazy: A donut with a blue glaze. |
| 29 | `choco_taco` | kid | `nib` | Spicy |  | Choco Taco: Ice cream in a crunchy shell. |
| 30 | `bumble` | kid | `nib` | Sour |  | Bumble: A bumblebee in blue stripes. |
| 31 | `owlet` | adult | `leafwing` | Sweet | Pure | Owlet: Up all night, every night. |
| 32 | `pistachio` | adult | `leafwing` | Sprouty | Peak | Pistachio: A pistachio scoop on a waffle cone. |
| 33 | `scarab` | adult | `leafwing` | Savory / Spicy / Sour | Chaos | Scarab: Rolls cocoa beans home. |
| 34 | `bonbon` | adult | `fudge` | Sweet | Ultra | Bonbon: A blue chocolate bonbon, wrapped like a gift. |
| 35 | `kuri` | adult | `fudge` | Sprouty / Savory | Bloom | Kuri: A chestnut sweet. Shiny on top. |
| 36 | `gremlin` | adult | `fudge` | Spicy / Sour | Clash | Gremlin: Do not feed it after midnight. |
| 37 | `eclair` | adult | `glazy` | Sweet | Pure | Eclair: Long, glazed, full of blue cream. |
| 38 | `churro` | adult | `glazy` | Savory | Peak | Churro: Long, ridged, dusted in sugar. |
| 39 | `candy_corn` | adult | `glazy` | Sprouty / Spicy / Sour | Chaos | Candy Corn: Half of everyone hates it. It knows. |
| 40 | `hot_cocoa` | adult | `choco_taco` | Sweet | Pure | Hot Cocoa: Cocoa with a pinch of chilli. |
| 41 | `cocoa_fire` | adult | `choco_taco` | Spicy | Peak | Cocoa Fire: Hot chocolate with a fire inside. |
| 42 | `taiyaki` | adult | `choco_taco` | Sprouty / Savory / Sour | Chaos | Taiyaki: A fish-shaped cake, blue inside. |
| 43 | `honeybear` | adult | `bumble` | Sweet | Pure | Honeybear: Fell asleep in the honey pot. |
| 44 | `ramune` | adult | `bumble` | Sour | Peak | Ramune: A marble soda. Fizzy and blue. |
| 45 | `bruin` | adult | `bumble` | Sprouty / Savory / Spicy | Chaos | Bruin: A bear cub sticky with blue honey. |
| 46 | `cocoa_9` | mutant | any adult | Tech | Tech | Cocoa-9: A chocolate robot, model 9. |
| 47 | `kaguya` | mutant | any adult | Cosmic | Cosmic | Kaguya: A princess from the moon, inside a mochi. |
| 48 | `tsukuyomi` | legend | `bonbon` | Stardust Sugar | Legend | Tsukuyomi: The moon rabbit god. |

## Fox realm (fed mostly Savory)

| # | id | stage | grows from | fed | branch | old name: one-liner (hint only) |
|---|---|---|---|---|---|---|
| 49 | `inari` | baby | (start) | Savory |  | Inari: A fried tofu pouch that foxes adore. |
| 50 | `kitsune` | kid | `inari` | Sprouty |  | Kitsune: A fox who loves fried tofu. |
| 51 | `waffle` | kid | `inari` | Sweet |  | Waffle: A waffle with blue syrup. |
| 52 | `fried_egg` | kid | `inari` | Savory |  | Fried Egg: Sunny side up, every day. |
| 53 | `drumstick` | kid | `inari` | Spicy |  | Drumstick: All drumstick, no fear. |
| 54 | `oden` | kid | `inari` | Sour |  | Oden: Everything simmered, on one stick. |
| 55 | `kyubi` | adult | `kitsune` | Savory | Pure | Kyubi: A fox with nine tails. Only shows one. |
| 56 | `konoha` | adult | `kitsune` | Sprouty | Peak | Konoha: A fox with a leaf disguise. |
| 57 | `okonomi` | adult | `kitsune` | Sweet / Spicy / Sour | Chaos | Okonomi: Everything in the fridge, fried flat. |
| 58 | `popcorn` | adult | `waffle` | Savory | Pure | Popcorn: Pops when it is surprised. |
| 59 | `daigaku_imo` | adult | `waffle` | Sweet | Peak | Daigaku Imo: Candied sweet potato. A student favourite. |
| 60 | `stroopwafel` | adult | `waffle` | Sprouty / Spicy / Sour | Chaos | Stroopwafel: Two waffles holding a secret. |
| 61 | `burger` | adult | `fried_egg` | Savory | Ultra | Burger: Bun, lettuce, patty, bun. Classic. |
| 62 | `hot_dog` | adult | `fried_egg` | Sweet / Spicy | Bloom | Hot Dog: A sausage in a bun. Mustard optional. |
| 63 | `fish_taco` | adult | `fried_egg` | Sprouty / Sour | Clash | Fish Taco: A taco that swims. |
| 64 | `kushikatsu` | adult | `drumstick` | Savory | Pure | Kushikatsu: Dip it in the sauce only once. |
| 65 | `kitsu` | adult | `drumstick` | Spicy | Peak | Kitsu: A fire fox with a white chest. |
| 66 | `hothog` | adult | `drumstick` | Sprouty / Sweet / Sour | Chaos | Hothog: A hedgehog with hot quills. |
| 67 | `ebi_fry` | adult | `oden` | Savory | Pure | Ebi Fry: A fried prawn, tail and all. |
| 68 | `shiso_tempura` | adult | `oden` | Sour | Peak | Shiso Tempura: A shiso leaf in a light batter. |
| 69 | `walrusk` | adult | `oden` | Sprouty / Sweet / Spicy | Chaos | Walrusk: A walrus with a fine moustache. |
| 70 | `robobear` | mutant | any adult | Tech | Tech | Robobear: Hugs at exactly 12 newtons. |
| 71 | `nebula_nug` | mutant | any adult | Cosmic | Cosmic | Nebula Nug: A nugget from the Milky Way. |
| 72 | `sunbear` | legend | `burger` | Dragon Oil | Legend | Sunbear: The king of fried things. |

## Fire realm (fed mostly Spicy)

| # | id | stage | grows from | fed | branch | old name: one-liner (hint only) |
|---|---|---|---|---|---|---|
| 73 | `ember` | baby | (start) | Spicy |  | Ember: Hatched from something spicy. Always slightly warm to the touch. |
| 74 | `paprika` | kid | `ember` | Sprouty |  | Paprika: A sweet pepper that is secretly hot. |
| 75 | `daruma` | kid | `ember` | Sweet |  | Daruma: Falls down seven times, stands up eight. |
| 76 | `nacho` | kid | `ember` | Savory |  | Nacho: A nacho with a cheese cape. |
| 77 | `dotty` | kid | `ember` | Spicy |  | Dotty: A ladybird with blue spots. |
| 78 | `kimchi` | kid | `ember` | Sour |  | Kimchi: Fermented with patience. |
| 79 | `hoozuki` | adult | `paprika` | Spicy | Pure | Hoozuki: A lantern plant. Lights the way for spirits. |
| 80 | `pepper_plant` | adult | `paprika` | Sprouty | Peak | Pepper Plant: Grows its own snacks. |
| 81 | `chameleon` | adult | `paprika` | Sweet / Savory / Sour | Chaos | Chameleon: Cannot decide on a colour. |
| 82 | `oo_daruma` | adult | `daruma` | Spicy | Pure | Oo Daruma: A big daruma. Wishes granted: one. |
| 83 | `maneki` | adult | `daruma` | Sweet | Peak | Maneki: Waves you in. Business is good. |
| 84 | `spicecake` | adult | `daruma` | Sprouty / Savory / Sour | Chaos | Spicecake: A chocolate cupcake with a chilli on top. |
| 85 | `popper` | adult | `nacho` | Spicy | Pure | Popper: Hot inside, crunchy outside. |
| 86 | `quesadilla` | adult | `nacho` | Savory | Peak | Quesadilla: Folded, toasted, oozing. |
| 87 | `burrito` | adult | `nacho` | Sprouty / Sweet / Sour | Chaos | Burrito: Wrapped up tight like a sleeping bag. |
| 88 | `firebug` | adult | `dotty` | Spicy | Ultra | Firebug: Warm to the touch, like a radiator. |
| 89 | `salamander` | adult | `dotty` | Savory / Sour | Bloom | Salamander: Lives in the fire, naps in the fire. |
| 90 | `ladyluck` | adult | `dotty` | Sprouty / Sweet | Clash | Ladyluck: A lucky ladybird. Blue for luck. |
| 91 | `gochujang` | adult | `kimchi` | Spicy | Pure | Gochujang: Thick red paste. Sweet, then hot. |
| 92 | `ceviche` | adult | `kimchi` | Sour | Peak | Ceviche: Cooked in lime, not fire. |
| 93 | `takoyaki` | adult | `kimchi` | Sprouty / Sweet / Savory | Chaos | Takoyaki: Ball outside, octopus inside. |
| 94 | `mecha_oni` | mutant | any adult | Tech | Tech | Mecha Oni: An ogre robot. Still loud. |
| 95 | `comet_chili` | mutant | any adult | Cosmic | Cosmic | Comet Chili: Hot, from very far away. |
| 96 | `hou_ou` | legend | `firebug` | Phoenix Pepper | Legend | Hou-ou: The phoenix. Rises from hot sauce. |

## River realm (fed mostly Sour)

| # | id | stage | grows from | fed | branch | old name: one-liner (hint only) |
|---|---|---|---|---|---|---|
| 97 | `picklet` | baby | (start) | Sour |  | Picklet: Hatched from something sour. Permanently unimpressed. |
| 98 | `kappa_maki` | kid | `picklet` | Sprouty |  | Kappa Maki: A cucumber roll with a calm mind. |
| 99 | `sourpatch` | kid | `picklet` | Sweet |  | Sourpatch: Sour, then sweet, then gone. |
| 100 | `hermit` | kid | `picklet` | Savory |  | Hermit: A hermit crab living in half a lemon. |
| 101 | `buzz` | kid | `picklet` | Spicy |  | Buzz: A sour wasp that never stings. |
| 102 | `teru_teru` | kid | `picklet` | Sour |  | Teru Teru: Hang it up to stop the rain. |
| 103 | `ume_onigiri` | adult | `kappa_maki` | Sour | Pure | Ume Onigiri: A rice ball with a sour plum on top. |
| 104 | `granny` | adult | `kappa_maki` | Sprouty | Peak | Granny: A green apple. Crunchy and sour. |
| 105 | `hoot` | adult | `kappa_maki` | Sweet / Savory / Spicy | Chaos | Hoot: Turns its head all the way round. |
| 106 | `lemon_sweet` | adult | `sourpatch` | Sour | Pure | Lemon Sweet: A sour candy, still in its wrapper. |
| 107 | `cream_soda` | adult | `sourpatch` | Sweet | Peak | Cream Soda: Melon soda with a scoop on top. |
| 108 | `lime` | adult | `sourpatch` | Sprouty / Savory / Spicy | Chaos | Lime: Juicy, friendly, a bit sharp. |
| 109 | `anemone` | adult | `hermit` | Sour | Pure | Anemone: Waves at fish all day. |
| 110 | `calamari` | adult | `hermit` | Savory | Peak | Calamari: A squid ring. Crunchy, a bit chewy. |
| 111 | `octopepper` | adult | `hermit` | Sprouty / Sweet / Spicy | Chaos | Octopepper: Eight spicy legs, one calm mind. |
| 112 | `lemon_ant` | adult | `buzz` | Sour | Pure | Lemon Ant: A lemon ant. It really tastes of citrus. |
| 113 | `shichimi` | adult | `buzz` | Spicy | Peak | Shichimi: Seven spices in one little bottle. |
| 114 | `axel` | adult | `buzz` | Sprouty / Sweet / Savory | Chaos | Axel: Smiles on the inside. |
| 115 | `omamori` | adult | `teru_teru` | Sour | Ultra | Omamori: A lucky charm pouch. Keeps the gut safe. |
| 116 | `kokeshi` | adult | `teru_teru` | Spicy / Sprouty | Bloom | Kokeshi: A wooden doll. Watches over the room. |
| 117 | `karakasa` | adult | `teru_teru` | Sweet / Savory | Clash | Karakasa: An old umbrella that came alive. |
| 118 | `robofrog` | mutant | any adult | Tech | Tech | Robofrog: Croaks in binary. |
| 119 | `ningyo` | mutant | any adult | Cosmic | Cosmic | Ningyo: A mermaid from outer space. |
| 120 | `frog_king` | legend | `omamori` | Kraken Brine | Legend | Frog King: The sour king of every pond. |
