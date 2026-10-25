# Dépôt Git du TP1

## Destination

Le sujet indique « Rapport complet poussé sur le dépôt Myges du groupe » en première page. Le dépôt ou le lien de remise communiqué sur Myges constitue donc la destination officielle.

Pour conserver une copie personnelle, créer un nouveau dépôt GitHub **Tutorial-just/tp01-linux**. Le dépôt aws-terraform-secure-infra contient déjà un projet AWS/Terraform distinct.

## Premier push vers GitHub personnel

1. Sur GitHub, créer `tp01-linux` sous le compte Tutorial-just. Choisir un dépôt privé pour le travail du groupe et donner l’accès aux personnes concernées.
2. Laisser le dépôt vide : ne pas ajouter automatiquement README, licence ou .gitignore. Ces fichiers de préparation sont déjà dans le dossier.
3. Décompresser l’archive. Ouvrir PowerShell dans `tp01-linux`, au niveau de README.md.
4. Exécuter les commandes suivantes une par une. En cas d’erreur, la résoudre avant la commande suivante.

```powershell
git init -b main
git add .
git status
git commit -m "TP1 - Installation Linux et premier durcissement"
git remote add origin https://github.com/Tutorial-just/tp01-linux.git
git push -u origin main
```

Si Git demande une identité, définir localement `git config user.name` et `git config user.email` avec le nom et l’adresse du compte GitHub, puis relancer le commit. Si origin existe déjà, consulter `git remote -v` avant de modifier son adresse. Ces instructions concernent un nouveau dossier, pas un clone du projet Terraform.

## Dépôt officiel du groupe

Si le dépôt attribué est déjà initialisé, le cloner, puis y copier les dossiers tp01, docs, scripts, le README et le rapport sans écraser le travail des autres TP. Ajouter et committer ces fichiers dans ce clone, puis pousser sa branche habituelle.

Si le dépôt officiel est vide et doit recevoir exactement ce projet, ajouter son adresse réelle comme second distant :

```powershell
git remote add myges URL_GIT_COMMUNIQUEE_PAR_ENSEIGNANT
git push -u myges main
```

Le texte URL_GIT_COMMUNIQUEE_PAR_ENSEIGNANT est à remplacer par l’adresse réelle ; Myges n’est pas une adresse Git à déduire. Si l’enseignant demande uniquement un lien GitHub sur Myges, remettre le lien du dépôt personnel et lui donner accès.

## Vérification après push

```powershell
git status
git log -1 --oneline
git rev-parse HEAD
git ls-remote origin refs/heads/main
```

Comparer l’identifiant local avec celui de la branche distante. Consigner la date, le commit et le lien dans docs/journal.md. Ne pas déposer les images de disque des VM, les ISO, les clés privées ou les historiques temporaires de collecte ; .gitignore couvre ces fichiers.

Référence : https://docs.github.com/en/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github
