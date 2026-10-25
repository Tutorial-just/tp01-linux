#!/usr/bin/env bash
# Collecte en lecture seule. Utiliser un compte nominatif ayant sudo.
# Usage : bash collecter-preuves.sh env-a ./tp01/preuves
set -u
export SYSTEMD_PAGER=cat PAGER=cat
environnement="${1:-}"
racine="${2:-$HOME/tp01-preuves}"
if [[ ! "$environnement" =~ ^[a-z][a-z0-9_-]*$ ]]; then
  printf 'Usage : bash %s {env-a|env-b} [dossier-preuves]\n' "$0" >&2
  exit 2
fi
if [[ ! -r /etc/os-release ]]; then
  printf '/etc/os-release est introuvable.\n' >&2
  exit 2
fi
. /etc/os-release
case "$ID" in
  ubuntu) machine=ubuntu24-lab ;;
  rhel|rocky|almalinux|centos) machine=rhel9-lab ;;
  *) printf 'Distribution non prise en charge : %s\n' "$ID" >&2; exit 2 ;;
esac
sudo -v || exit 1
dossier="$racine/$environnement"
mkdir -p "$dossier/historique"
horodatage="$(date +%Y%m%dT%H%M%S)"
for nom in "$machine.txt" "lsblk-$machine.txt"; do
  if [[ -f "$dossier/$nom" ]]; then
    cp -p -- "$dossier/$nom" "$dossier/historique/${horodatage}-$nom"
  fi
done
temporaire="$(mktemp "$dossier/.collecte.XXXXXXXX")"
trap 'rm -f -- "$temporaire"' EXIT
run() {
  printf '\n$ '
  printf '%q ' "$@"
  printf '\n'
  "$@" 2>&1
  code=$?
  printf '[code_retour=%s]\n' "$code"
}
{
  printf 'EXPORT DIRECT DE LA VM\nEnvironnement : %s\nMachine attendue : %s\n' "$environnement" "$machine"
  printf 'Debut : '; date -Is
  run hostnamectl
  run cat /etc/os-release
  run uname -r
  run lsblk -f
  run lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
  run df -hT
  run sudo pvs
  run sudo vgs
  run sudo lvs -o lv_name,vg_name,lv_size,lv_path
  run swapon --show
  run findmnt --target /var/log
  run findmnt --target /tmp
  run cat /etc/fstab
  run localectl status
  run locale -a
  run timedatectl status
  run systemctl --failed --no-pager
  run systemctl list-units --type=service --state=running --no-pager
  run id
  if [[ "$machine" == rhel9-lab ]]; then run getent group wheel; else run getent group sudo; fi
  for compte in vlad joy mankchould; do
    run getent passwd "$compte"
    run id "$compte"
  done
  run sudo -l
  run sudo id
  run sudo passwd -S root
  run sudo /usr/sbin/sshd -t
  run sudo /usr/sbin/sshd -T
  run ip -br a
  run ip route
  if [[ "$machine" == rhel9-lab ]]; then
    run sudo dnf history
    run sudo dnf history info last
    run sudo dnf repolist
    run rpm -q --last kernel-core
    run sudo firewall-cmd --get-active-zones
    run sudo firewall-cmd --list-all
  else
    run apt list --upgradable
    run sudo tail -n 80 /var/log/apt/history.log
    run sudo ufw status verbose
  fi
  printf '\nFin : '; date -Is
} > "$temporaire" 2>&1
mv -- "$temporaire" "$dossier/$machine.txt"
{
  printf 'EXPORT DIRECT DE LA VM\nEnvironnement : %s\n' "$environnement"
  date -Is
  hostname
  run lsblk -f
  run lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
} > "$dossier/lsblk-$machine.txt" 2>&1
printf 'Fichiers crees :\n%s\n%s\n' "$dossier/$machine.txt" "$dossier/lsblk-$machine.txt"
printf 'Les erreurs eventuelles sont conservees ; la collecte ne signifie pas que tous les controles sont conformes.\n'
