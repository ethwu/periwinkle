# DNDFS
Hierarchical file system for organising information about DND characters

## TODO

1. Write instructions
1. Write exmaples
1. Add search tool

   ```sh
   # https://www.reddit.com/r/commandline/comments/8zqt4s/comment/e2lfm5h
   grep -rin "$@" . ; find . | grep "$@" | xargs -I % sh -c 'echo %; cat %' 2> /dev/null
   ```


```
├── attacks
│   └── unarmed
├── feats
│   ├── languages
│   └── proficiencies
├── info
│   ├── alignment
│   ├── backstory
│   │   ├── allies
│   │   ├── backstory
│   │   ├── enemies
│   │   └── notes
│   ├── characteristics
│   │   ├── bonds
│   │   ├── faith
│   │   ├── flaws
│   │   ├── ideals
│   │   └── personality
│   ├── class
│   ├── level
│   ├── name
│   ├── physical
│   │   ├── age
│   │   ├── eyes
│   │   ├── gender
│   │   ├── hair
│   │   ├── height
│   │   ├── skin
│   │   └── weight
│   └── race
├── kit
│   ├── bronze
│   ├── electrum
│   ├── gold
│   ├── platinum
│   └── silver
├── limited_use
├── spells
│   ├── cantrips
│   ├── level_1
│   └── spell_slots
│       └── level_1
└── stats
    ├── abilities
    │   ├── charisma
    │   ├── constitution
    │   ├── dexterity
    │   ├── intelligence
    │   ├── strength
    │   └── wisdom
    ├── ac
    ├── hp
    │   ├── current
    │   └── max
    ├── initiative
    ├── passive
    ├── proficiency
    ├── skills
    │   ├── acrobatics
    │   ├── animal_handling
    │   ├── arcana
    │   ├── athletics
    │   ├── deception
    │   ├── history
    │   ├── insight
    │   ├── intimidation
    │   ├── investigation
    │   ├── medicine
    │   ├── nature
    │   ├── perception
    │   ├── performance
    │   ├── persuasion
    │   ├── religion
    │   ├── sleight_of_hand
    │   ├── stealth
    │   └── survival
    └── speed
```
