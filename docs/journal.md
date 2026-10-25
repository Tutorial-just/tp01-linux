# Journal de bord - TP1

Membres : TETA KENGNE Joy Adjovi ; Vladimir MELTSOV ; Mankchould LAWAL.

## Séance d’installation et de configuration

| Partie | Travail consigné | Résultat |
|---|---|---|
| A1-A4 | Virtualisation, création des VM, ressources, cartes NAT et laboratoire, instantanés | Les deux environnements sont décrits dans INSTALL ; instantanés A visibles |
| B1-B3 | Justification du stockage, partitionnement manuel, lsblk, df, swap et vgs | Cinq LV par VM ; réserve nulle sur RHEL B |
| C1-C5 | Installation serveur, identité, locale, horloge, dépôts et paquets | Versions et historiques relevés ; tableau comparatif complété |
| D1-D5 | Root verrouillé, comptes, sudo, clés, configuration SSH et pare-feu | Accès A par clé et sudo vérifiés ; état détaillé dans INSTALL §6-9 |
| E | Collecte des preuves, rédaction de la procédure et du rapport | Huit exports A du 25 octobre ; textes B du 22 octobre |

La durée totale du travail n’a pas été consignée. Elle reste à renseigner d’après le temps réellement passé. Les durées de contrôle automatisé mesurées le 25 octobre sont de 12 secondes sur RHEL A et 4 secondes sur Ubuntu A ; elles ne représentent pas le temps de réalisation du TP.

## Incidents et corrections

- La première commande de copie de clé depuis PowerShell est mal formée. Sa syntaxe est reprise ; les connexions par clé A réussissent ensuite.
- Sur Ubuntu B, la confirmation du mot de passe d’alice diffère de la première saisie. La saisie est recommencée et la création du compte se poursuit.
- Le script Windows est initialement bloqué comme non signé. Le fichier est débloqué avec Unblock-File puis relancé.
- La première collecte SSH expire car les VM sont arrêtées. Après leur mise sous tension, la collecte fonctionne avec les mêmes adresses.
- Les exports du 25 octobre confirment les accès A. Ils signalent encore l’adressage interne absent, le fuseau et /tmp Ubuntu, les mises à jour et un échec de NetworkManager-wait-online sur RHEL. Les procédures correspondantes figurent dans INSTALL ; leur exécution complète reste à vérifier.

## A4 - Instantané avant installation

L’instantané avant-installation restitue la VM avant l’écriture du système tout en conservant les ressources et les cartes réseau préparées. Il permet de reprendre l’installation sans recréer la machine.

## B1 - Justifications du partitionnement

**1 Séparer /var et /var/log.** /var reçoit des données variables : caches, files d'attente et données de services. /var/log contient les journaux. Un service en boucle peut écrire des gigaoctets de messages. Si ces journaux partagent le volume racine, ils peuvent empêcher la création de fichiers système et perturber plusieurs services. Un volume séparé limite cette saturation à l'usage concerné ; il faut ensuite surveiller l'espace et organiser la rotation des journaux.

**2 Conserver /boot hors LVM.** /boot contient les noyaux et les images nécessaires au démarrage. Une partition classique simplifie l'amorçage et le dépannage, en limitant les dépendances à la configuration LVM. Cela ne signifie pas que tout chargeur d'amorçage est incapable de lire LVM. Sur les VM RHEL en UEFI, une partition EFI en vfat complète /boot.

**3 Choisir 2 Gio de swap pour 2 Gio de RAM.** La swap constitue une marge pour les pages mémoire peu utilisées et les pointes temporaires de consommation. Sans swap, une pression mémoire peut provoquer plus vite l'arrêt de processus par le noyau. Réserver 8 Gio n'apporte pas davantage de RAM et utilise plus de disque ; des échanges intensifs ralentissent la VM. Les 2 Gio retenus correspondent à l'usage léger du laboratoire, sans objectif d'hibernation.

**4 Garder de l'espace dans le groupe.** L'espace non affecté à un LV pourra être attribué au volume qui manque de place, sans réinstaller le serveur. Il peut aussi servir à certains instantanés LVM. Il faut distinguer cette réserve, affichée par vgs, de l'espace encore libre à l'intérieur de / ou /var.

**5 Volume susceptible de croître et opération à maîtriser.** /var/log est un candidat probable, car les journaux s'accumulent. /var peut aussi croître selon les applications. L'agrandissement repose sur l'extension du LV puis celle du système de fichiers, en ligne lorsque celui-ci le permet. Pour XFS on utilise xfs_growfs ; pour ext4, resize2fs. `lvextend -r` peut réaliser les deux étapes. Le nom du LV doit correspondre à la machine concernée et la réserve du groupe doit être vérifiée avant l'opération.

## Relecture du document

Deux observations ont conduit à améliorer la procédure :

1. Un test SSH qui accepte le mot de passe ne démontre pas l’utilisation de la clé. La commande de vérification impose désormais publickey et désactive le repli sur le mot de passe.
2. Une mise à jour du noyau ne change pas immédiatement le noyau en cours d’exécution. La reconstruction inclut donc un redémarrage suivi de uname -r et systemctl --failed.

Ces observations concernent la relecture du dossier. La revue croisée demandée auprès d’un autre groupe n’est pas encore consignée : nom du groupe relecteur et deux remarques reçues restent à ajouter après cette revue.

## Versionnement et dépôt

Le dossier est préparé pour Git. Le commit et le push n’ont pas été exécutés dans le cadre de cette préparation. Consigner la date, l’identifiant du commit et l’adresse de remise après le push. Le rendu officiel est demandé sur le dépôt Myges du groupe.
