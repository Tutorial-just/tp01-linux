# TP1 - Installation Linux et premier durcissement

Programmation système et réseaux sous Linux - ESGI.

## Membres

- **TETA KENGNE Joy Adjovi**
- **Vladimir MELTSOV**
- **Mankchould LAWAL**

## Contenu

| Emplacement | Description |
|---|---|
| [Rapport PDF](TP1_Linux_Rapport.pdf) | Compte rendu, tableaux, réponses et captures |
| [tp01/INSTALL.md](tp01/INSTALL.md) | Procédure de reconstruction en dix rubriques |
| [tp01/preuves/](tp01/preuves/) | Sorties système et partitionnement aux noms exigés |
| [tp01/preuves/env-a/](tp01/preuves/env-a/) | Huit exports directs : système, lsblk, contrôles et accès |
| [tp01/preuves/env-b/](tp01/preuves/env-b/) | Relevés B extraits du compte rendu du 22 octobre |
| [tp01/captures/](tp01/captures/) | 47 captures sélectionnées, sans retouche |
| [docs/journal.md](docs/journal.md) | Actions, incidents, justifications B1 et relecture |
| [docs/collecte-et-finalisation.md](docs/collecte-et-finalisation.md) | Commandes de correction, collecte et contrôle |
| [docs/depot-git.md](docs/depot-git.md) | Dépôt GitHub personnel et remise officielle |
| [scripts/](scripts/) | Collecte et configuration sur les VM |

## Environnements

A et B sont deux laboratoires indépendants. Chacun comporte rhel9-lab et ubuntu24-lab. Les tailles, comptes et adresses sont conservés dans leurs relevés respectifs.

Les exports directs A datent du 25 octobre 2026. Les relevés B datent du 22 octobre et proviennent du compte rendu d’installation. Les résultats et les points encore à vérifier figurent dans INSTALL.md, section 9.

Les durées réelles de séance et la revue croisée par un autre groupe restent à consigner dans le journal. Après correction sur les VM, relancer la collecte pour actualiser les preuves.

## Dépôt

Nom proposé : **tp01-linux**. Copie de travail personnelle prévue : `https://github.com/Tutorial-just/tp01-linux` (dépôt à créer).

La première page du sujet demande le rendu sur le **dépôt Myges du groupe** avant la séance suivante. Utiliser l’adresse communiquée par l’enseignant pour cette remise. Le projet Terraform existant conserve son propre dépôt.

Ouvrir PowerShell dans le dossier qui contient ce README et suivre [les commandes Git](docs/depot-git.md). Le dépôt reçoit le contenu décompressé du ZIP.
