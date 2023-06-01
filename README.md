# ZIPshark
ZIPshark is a is a ZIP archive password recovery tool. It has two recovery modes to choose between:
- bruteforce ('crunch' command required)
- dictionary


## Synopsis
> zipshark [-h / --help] [-v / --version]


## Functionalities
#### Mutual:
- choosing between verbal and non-verbal mode
- missing packages detection and installation
#### Bruteforce mode:
- specifying min/max length of generated passwords
- specifying charset - (un)toggling small and capital letters, digits, special characters
#### Dictionary mode:
- user can pick dictionary file on their own - it has to contain one word per line only
- if no file is selected, a default one can be fetched from [CrackStation](crackstation.net)
