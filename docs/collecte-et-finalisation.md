# Collecte directe et finalisation du TP1

## 1. Obtenir les sorties brutes depuis Windows

Allumer les deux VM, décompresser le dossier et ouvrir PowerShell dans le répertoire qui contient README.md et scripts. Le dossier doit se trouver sur le poste Windows qui peut déjà se connecter aux VM par SSH.

Pour l’environnement A, avec les adresses relevées dans les captures :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\collecter-depuis-windows.ps1 -Environnement env-a -IpRhel 192.168.198.128 -IpUbuntu 192.168.198.129 -UtilisateurRhel vlad -UtilisateurUbuntu vlad
```

Pour l’environnement B, avec le compte alice visible dans les essais :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\collecter-depuis-windows.ps1 -Environnement env-b -IpRhel 192.168.43.129 -IpUbuntu 192.168.43.128 -UtilisateurRhel alice -UtilisateurUbuntu alice
```

Si un autre compte est employé, remplacer les paramètres Utilisateur. Pour vérifier les adresses actuelles, exécuter `ip -br a` dans chaque console VMware. Utiliser l’adresse NAT joignable depuis Windows. Si une clé porte un nom autre que celui reconnu automatiquement par SSH, ajouter :

```powershell
-ClePrivee "$env:USERPROFILE\.ssh\id_ed25519_tp01"
```

Si Windows bloque le collecteur téléchargé, exécuter d’abord `Unblock-File .\scripts\collecter-depuis-windows.ps1`, puis relancer la commande. Une stratégie imposée par l’établissement reste applicable.

Saisir les mots de passe demandés et, pour une clé protégée, sa passphrase. La saisie Linux des mots de passe ne montre aucun caractère. Une erreur lors du test par clé reste enregistrée et doit être corrigée.

Les fichiers sont produits par les commandes exécutées sur les VM :

| Fichier, dans tp01/preuves/env-a ou env-b | Contenu |
|---|---|
| rhel9-lab.txt et ubuntu24-lab.txt | Horodatage, identité, stockage, locale, horloge, services, sudo, SSH, réseau, historiques et pare-feu |
| lsblk-rhel9-lab.txt et lsblk-ubuntu24-lab.txt | Partitionnement et types de systèmes de fichiers |
| controle-rhel9-lab.txt et controle-ubuntu24-lab.txt | Contrôles locaux avec résultat OK ou A CORRIGER |
| acces-rhel9-lab.txt et acces-ubuntu24-lab.txt | Clé publique imposée, délégation et refus SSH root depuis Windows |

Les fichiers précédents sont sauvegardés dans historique/ avant remplacement. Après une collecte A, les quatre exports requis sont recopiés à l’identique au niveau tp01/preuves/. Les relevés B restent dans env-b/. Une collecte conserve aussi les erreurs et ne valide pas automatiquement la conformité.

## 2. Exécuter les corrections préparées

Le script corriger-tp01.sh règle Europe/Paris, active la synchronisation, prépare la locale française et le montage tmpfs Ubuntu, et retire l’ouverture Cockpit dans les zones RHEL concernées. Les options --reseau et --mises-a-jour ajoutent le réglage de la carte interne et l’application des mises à jour. Les noms d’interface sont ceux des relevés.

Depuis PowerShell, copier les fichiers vers une VM, par exemple Ubuntu A :

```powershell
scp .\scripts\corriger-tp01.sh .\scripts\configurer-tmpfs.py vlad@192.168.198.129:
ssh -t vlad@192.168.198.129 "bash corriger-tp01.sh env-a --appliquer --reseau --mises-a-jour"
```

Sur RHEL A, utiliser :

```powershell
scp .\scripts\corriger-tp01.sh .\scripts\configurer-tmpfs.py vlad@192.168.198.128:
ssh -t vlad@192.168.198.128 "bash corriger-tp01.sh env-a --appliquer --reseau --mises-a-jour"
```

Pour B, employer env-b, 192.168.43.129 ou 192.168.43.128 et le compte concerné. Sans --appliquer, le script affiche seulement les opérations prévues.

Garder la console VMware disponible. Sur Ubuntu, netplan try demande de confirmer que le réseau fonctionne. Le fichier ajouté concerne la carte interne ; la carte NAT conserve ses paramètres. Si un essai n’est pas confirmé, contrôler la console et les fichiers restaurés avant le redémarrage.

Les journaux corrections-*.txt sont enregistrés dans ~/tp01-preuves/env-a/ ou env-b/. La durée indiquée correspond à l’exécution automatique. Les sauvegardes des configurations se trouvent dans /var/backups/tp01-* selon le chemin affiché.

Le montage /tmp est préparé dans fstab et prend effet au redémarrage, sans masquer les fichiers temporaires en cours d’utilisation. Si les corrections et les mises à jour se sont terminées sans erreur :

```bash
sudo reboot
```

Quand les VM sont revenues, relancer la collecte de la section 1. Une correction préparée devient vérifiée lorsque les nouvelles sorties montrent le résultat attendu.

## 3. Dépôts RHEL et attente réseau

Si DNF signale l’absence de réception des mises à jour, examiner les droits et les dépôts :

```bash
sudo subscription-manager status
sudo subscription-manager repos --list-enabled
sudo dnf repolist
sudo dnf -y update
sudo dnf history info last
```

Une inscription seule ne garantit pas l’accès aux dépôts. Utiliser l’abonnement de laboratoire prévu. L’activation d’EPEL reste conditionnée à sa disponibilité, conformément au sujet.

Pour l’unité NetworkManager-wait-online en échec :

```bash
nmcli device status
nmcli connection show
sudo journalctl -b -u NetworkManager-wait-online --no-pager
sudo journalctl -b -u NetworkManager --no-pager
```

Le script configure le profil de la carte interne lorsqu’il peut l’identifier. Si plusieurs profils ou une autre erreur apparaissent, corriger la cause indiquée dans le journal. Après redémarrage, `systemctl --failed` doit être vide ; supprimer seulement l’état failed ne corrige pas la cause.

## 4. Comptes et clés

Les membres sont TETA KENGNE Joy Adjovi, Vladimir MELTSOV et Mankchould LAWAL. Les comptes restent distincts. Les identifiants joy, vlad et mankchould peuvent être employés ; alice reste le compte présent dans les relevés historiques. Un membre disposant déjà de son propre compte peut le conserver.

Pour un compte absent sur RHEL, par exemple joy :

```bash
id joy || sudo useradd -m -s /bin/bash -c "TETA KENGNE Joy Adjovi" joy
sudo passwd joy
sudo usermod -aG wheel joy
```

Sur Ubuntu, utiliser `sudo adduser joy` uniquement pour un compte absent, puis `sudo usermod -aG sudo joy`. Répéter pour vlad et mankchould si nécessaire, avec le nom et le mot de passe individuel de chaque membre. Après reconnexion, contrôler id, sudo -l et sudo id depuis chaque compte.

Chaque membre déploie sa propre clé publique vers ses comptes. La procédure complète de génération et de copie figure dans INSTALL.md, section 6. Un test avec PubkeyAuthentication=no ne valide pas la clé. Le nouveau collecteur impose publickey et enregistre les résultats dans acces-*.txt.

Conserver une session nominative fonctionnelle avant toute modification SSH. Vérifier PermitRootLogin no avec `sudo /usr/sbin/sshd -T`, la syntaxe avec `sudo /usr/sbin/sshd -t`, puis recharger sshd sur RHEL ou ssh sur Ubuntu. Un refus SSH root doit être un refus d’authentification explicite, et non une panne réseau.

## 5. Pare-feu et réserve LVM

Après toute modification du pare-feu, refaire une connexion depuis Windows. Le script retire Cockpit sur les zones RHEL concernées. Examiner aussi les autres règles ; retirer DHCPv6 uniquement après vérification de l’usage d’IPv6.

La réserve RHEL B est nulle dans le dernier relevé. Pour créer une réserve sans réduire XFS, augmenter le disque système dans VMware, puis vérifier que sa dernière partition peut être étendue. Pour le schéma NVMe B, avec growpart installé, après sauvegarde et augmentation effective du disque :

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
sudo pvs
sudo vgs
# Simulation pour la derniere partition du disque NVMe du releve B
sudo growpart -N /dev/nvme0n1 3
# Si le disque et la partition sont corrects
sudo growpart /dev/nvme0n1 3
sudo pvresize /dev/nvme0n1p3
sudo vgs
```

Vérifier le périphérique réel avant ces commandes. L’espace ajouté au PV reste libre dans vg_sys : ne pas l’attribuer immédiatement à un LV si l’objectif est de conserver une réserve. Le script de correction n’effectue pas cette opération de stockage.

## 6. Temps, relecture et retour

Renseigner les durées réellement passées dans docs/journal.md. Les durées des scripts ne couvrent pas le travail antérieur.

Deux observations de relecture sont consignées dans docs/journal.md. Compléter ensuite ce même journal avec le nom du groupe relecteur et les deux remarques reçues lors de la revue croisée.

Après collecte, depuis la racine du dossier, la commande directe suivante permet de créer le ZIP des preuves A :

```powershell
Compress-Archive -Path .\tp01\preuves\env-a -DestinationPath ..\TP1_Preuves_env-a.zip -Force
```

TP1_Preuves_env-a.zip est créé dans le dossier parent de tp01-linux. Cette archive contient les fichiers réellement récupérés, y compris les tests et les contrôles. Pour envoyer tout le dossier, utiliser Compress-Archive -Path . -DestinationPath ..\TP1_Linux_Retour.zip -Force. Effectuer le commit et le push Git après validation du dossier.

## Références techniques

- Netplan, essai avec confirmation : https://manpages.ubuntu.com/manpages/noble/man8/netplan-try.8.html
- RHEL 9, configuration réseau : https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html-single/configuring_and_managing_networking/index
- Format de fstab : https://manpages.ubuntu.com/manpages/noble/man5/fstab.5.html
- Profils et identifiants NetworkManager : https://networkmanager.pages.freedesktop.org/NetworkManager/NetworkManager/nmcli.html
