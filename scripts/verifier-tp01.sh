#!/usr/bin/env bash
# Controles locaux en lecture seule, depuis le compte nominatif.
set -u
export LC_ALL=C SYSTEMD_PAGER=cat PAGER=cat
environnement="${1:-}"
racine="${2:-$HOME/tp01-preuves}"
case "$environnement" in env-a|env-b) ;; *) printf 'Usage: bash %s {env-a|env-b} [dossier]\n' "$0"; exit 2;; esac
if [[ $EUID -eq 0 ]]; then
  printf 'Lancer ce script depuis le compte nominatif, sans sudo devant bash.\n'; exit 2
fi
. /etc/os-release
case "$ID" in
  ubuntu) machine=ubuntu24-lab; service_ssh=ssh; attendu=10.42.0.12/24
    if [[ "$environnement" == env-a ]]; then interface_lab=ens34; else interface_lab=ens37; fi ;;
  rhel|rocky|almalinux) machine=rhel9-lab; service_ssh=sshd; attendu=10.42.0.11/24
    if [[ "$environnement" == env-a ]]; then interface_lab=ens192; else interface_lab=ens224; fi ;;
  *) printf 'Distribution non prise en charge: %s\n' "$ID"; exit 2 ;;
esac
sudo -v || exit 1
destination="$racine/$environnement"
mkdir -p "$destination/historique"
fichier="$destination/controle-$machine.txt"
stamp="$(date +%Y%m%dT%H%M%S)-$$"
[[ ! -f "$fichier" ]] || cp -p -- "$fichier" "$destination/historique/$stamp-controle-$machine.txt"
exec > >(tee "$fichier") 2>&1
echecs=0
secondes_debut=$SECONDS
controle() {
  local titre="$1" code
  shift
  printf '\nCONTROLE: %s\n$ ' "$titre"; printf '%q ' "$@"; printf '\n'
  "$@"; code=$?
  if [[ $code -eq 0 ]]; then printf 'RESULTAT: OK\n'; else printf 'RESULTAT: A CORRIGER (code %s)\n' "$code"; echecs=$((echecs+1)); fi
}
printf 'CONTROLES EXECUTES SUR LA VM\nEnvironnement: %s\n' "$environnement"
date -Is
hostnamectl
controle 'Nom de la machine' bash -c 'test "$(hostname -s)" = "$1"' _ "$machine"
controle 'Groupe LVM present et reserve libre non nulle' bash -o pipefail -c \
  'sudo -n vgs --noheadings --units b --nosuffix -o vg_free vg_sys | awk "NF {n++; if ((\$1+0)>0) ok=1} END {exit !(n==1 && ok)}"'
controle 'Memoire echange active' bash -o pipefail -c 'swapon --noheadings --show=NAME | grep -q .'
controle 'Montage distinct pour /var/log' findmnt --mountpoint /var/log
controle 'Locale francaise disponible' bash -o pipefail -c 'locale -a | grep -Eiq "^fr_FR[.](utf8|UTF-8)$"'
controle 'Fuseau Europe/Paris' bash -c 'test "$(timedatectl show -p Timezone --value)" = Europe/Paris'
controle 'Heure synchronisee' bash -c 'test "$(timedatectl show -p NTPSynchronized --value)" = yes'
controle 'Aucune unite systemd en echec' bash -c \
  'sortie=$(systemctl --failed --no-legend --plain --no-pager) || exit; printf "%s\n" "$sortie"; test -z "$sortie"'
controle 'Adresse IPv4 de laboratoire' bash -o pipefail -c \
  'ip -o -4 addr show dev "$1" | awk "{print \$4}" | grep -Fx "$2"' _ "$interface_lab" "$attendu"
controle 'Delegation sudo du compte courant' bash -c 'test "$(sudo -n id -u)" = 0'
controle 'Mot de passe root verrouille' bash -o pipefail -c \
  'sudo -n passwd -S root | awk "{print; if (\$2 ~ /^L/) ok=1} END {exit !ok}"'
controle 'Syntaxe SSH valide' sudo -n /usr/sbin/sshd -t
controle 'Connexion directe root interdite' bash -o pipefail -c \
  'sudo -n /usr/sbin/sshd -T | grep -Ex "permitrootlogin no"'
controle 'Service SSH actif' systemctl is-active "$service_ssh"
if [[ "$ID" == ubuntu ]]; then
  controle '/tmp est un montage tmpfs distinct' bash -c 'test "$(findmnt -nr -M /tmp -o FSTYPE)" = tmpfs'
  controle 'Limite /tmp de 512 Mio' bash -o pipefail -c \
    'df --block-size=1 --output=size /tmp | tail -n 1 | awk "{exit !(\$1==536870912)}"'
  controle 'Permissions /tmp' bash -c 'test "$(stat -c %a /tmp)" = 1777'
  controle 'UFW actif' bash -o pipefail -c 'sudo -n ufw status | grep -Fx "Status: active"'
  sudo -n ufw status verbose
  printf '\nINVENTAIRE APT: verifier la liste apres full-upgrade.\n'
  apt list --upgradable
else
  controle 'firewalld actif' systemctl is-active firewalld
  sudo -n firewall-cmd --list-all
  printf '\nINVENTAIRE DNF: code 100 = mises a jour disponibles; code 1 = erreur.\n'
  sudo -n dnf check-update
  printf 'Code retour DNF: %s\n' "$?"
fi
printf '\nTEST ENTRE VM: un pare-feu peut bloquer ICMP; le resultat doit etre interprete.\n'
if [[ "$machine" == rhel9-lab ]]; then cible_lab=10.42.0.12; else cible_lab=10.42.0.11; fi
ping -c 3 -W 2 "$cible_lab"
printf 'Code retour ping: %s\n' "$?"
printf '\nVERIFICATIONS EXTERNES: connexion par cle, refus SSH root et acces apres pare-feu dans acces-%s.txt.\n' "$machine"
printf 'Les comptes de chaque membre et les regles completes du pare-feu restent a examiner.\n'
printf 'Controles locaux non valides: %s\nDuree de ces controles: %s secondes\n' "$echecs" "$((SECONDS-secondes_debut))"
date -Is
if [[ $echecs -gt 0 ]]; then exit 1; fi
