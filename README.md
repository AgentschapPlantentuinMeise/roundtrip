# roundtrip
Scripts to roundtrip agent attributions. Run `bionomia_roundtrip.R` to convert frictionless data exports from [Bionomia](https://bionomia.net) into a format following the [Agents Attribution extension](https://github.com/tdwg/attribution) to Darwin Core. The script requires `occurrences.csv`, `attributions.csv` and `users.csv` from a Bionomia dataset page to be present in the `data folder`. 

Alternatively, CLI execution is possible with the Bionomia (i.e. GBIF) dataset GUID as an argument. To do this, set the `bin` directory of your R installation as an environment variable and run

`Rscript bionomia_roundtrip.R b740eaa0-0679-41dc-acb7-990d562dfa37`

The produced extension will be saved in the `output` folder.
