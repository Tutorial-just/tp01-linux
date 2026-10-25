#!/usr/bin/env bash
# Execution sur les VM du TP uniquement, depuis un compte ayant sudo.
# Sans --appliquer: affiche le perimetre et les commandes de controle.
set -Eeuo pipefail
export LC_ALL=C SYSTEMD_PAGER=cat PAGER=cat
environnement="${1:-}"
[[ $# -eq 0 ]] || shift
appliquer=0; reseau=0; mises_a_jour=0
for option in "$@"; do
  case "$option" in
    --appliquer) appliquer=1;; --reseau) reseau=1;; --mises-a-jour) mises_a_jour=1;;
    *) printf 'Option inconnue: %s\n' "$option"; exit 2;;
  esac
done
case "$environnement" in env-a|env-b) ;; *) printf 'Usage: bash %s {env-a|env-b} [--appliquer] [--reseau] [--mises-a-jour]\n' "$0"; exit 2;; esac
if [[ $EUID -eq 0 ]]; then printf 'Lancer depuis le compte nominatif, sans sudo devant bash.\n'; exit 2; fi
. /etc/os-release
case "$ID" in
  ubuntu) machine=ubuntu24-lab; ip_lab=10.42.0.12/24
    if [[ "$environnement" == env-a ]]; then interface_lab=ens34; else interface_lab=ens37; fi ;;
  rhel|rocky|almalinux) machine=rhel9-lab; ip_lab=10.42.0.11/24
    if [[ "$environnement" == env-a ]]; then interface_lab=ens192; else interface_lab=ens224; fi ;;
  *) printf 'Distribution non prise en charge: %s\n' "$ID"; exit 2;;
esac
if [[ "$(hostname -s)" != "$machine" ]]; then printf 'Nom de VM inattendu: %s (attendu %s).\n' "$(hostname -s)" "$machine"; exit 2; fi
printf 'Cible: %s / %s / %s\n' "$environnement" "$machine" "$ID"
printf 'Operations: Europe/Paris, NTP, locale fr_FR, /tmp Ubuntu et retrait de Cockpit RHEL.\n'
printf 'Reseau demande: %s (%s, %s); mises a jour demandees: %s.\n' "$reseau" "$interface_lab" "$ip_lab" "$mises_a_jour"
if [[ $appliquer -eq 0 ]]; then
  printf 'Aucun changement applique. Ajouter --appliquer pour executer.\n'; exit 0
fi
sudo -v
stamp="$(date +%Y%m%dT%H%M%S)-$$"
traces="$HOME/tp01-preuves/$environnement"
mkdir -p "$traces"
exec > >(tee "$traces/corrections-$machine-$stamp.txt") 2>&1
secondes_debut=$SECONDS
sauvegarde="/var/backups/tp01-$stamp"
sudo mkdir -m 700 "$sauvegarde"
fin() {
  local code=$?
  printf '\nFin: '; date -Is
  printf 'Code retour: %s\nDuree de cette execution: %s secondes\nSauvegardes: %s\n' "$code" "$((SECONDS-secondes_debut))" "$sauvegarde"
}
trap fin EXIT
run() { printf '\n$ '; printf '%q ' "$@"; printf '\n'; "$@"; }
date -Is
run sudo timedatectl set-timezone Europe/Paris
run sudo timedatectl set-ntp true
if [[ "$ID" == ubuntu ]]; then
  run sudo locale-gen fr_FR.UTF-8
  run sudo update-locale LANG=fr_FR.UTF-8
  outil="$(cd -- "$(dirname -- "$0")" && pwd)/configurer-tmpfs.py"
  [[ -r "$outil" ]] || { printf 'Fichier manquant: %s\n' "$outil"; exit 2; }
  preparation="$(mktemp)"
  python3 "$outil" /etc/fstab "$preparation"
  run sudo cp -a /etc/fstab "$sauvegarde/fstab"
  run sudo install -m 644 "$preparation" /etc/fstab
  if ! sudo findmnt --verify --verbose; then
    sudo cp -a "$sauvegarde/fstab" /etc/fstab
    printf 'Verification fstab en erreur: version precedente restauree.\n'; exit 1
  fi
  run sudo systemctl daemon-reload
  printf '/tmp sera applique au prochain redemarrage; aucun montage par-dessus les fichiers en cours.\n'
  run sudo ufw allow OpenSSH
  run sudo ufw --force enable
else
  if ! locale -a | grep -Eiq '^fr_FR[.](utf8|UTF-8)$'; then run sudo dnf install -y glibc-langpack-fr; fi
  run sudo localectl set-locale LANG=fr_FR.UTF-8
  run sudo firewall-cmd --get-active-zones
  # Seulement les zones affectees a une interface du TP.
  for interface in $(ip -4 route show default | awk '{for(i=1;i<=NF;i++)if($i=="dev")print $(i+1)}') "$interface_lab"; do
    zone="$(sudo firewall-cmd --get-zone-of-interface "$interface" 2>/dev/null || true)"
    [[ -n "$zone" && "$zone" != 'no zone' ]] || continue
    run sudo firewall-cmd --permanent --zone="$zone" --add-service=ssh
    if sudo firewall-cmd --permanent --zone="$zone" --query-service=cockpit; then
      run sudo firewall-cmd --permanent --zone="$zone" --remove-service=cockpit
    fi
  done
  run sudo firewall-cmd --reload
fi
if [[ $reseau -eq 1 ]]; then
  ip link show "$interface_lab" >/dev/null
  if ip -4 route show default | grep -Eq "dev $interface_lab( |$)"; then
    printf 'La carte de laboratoire porte une route par defaut: examen manuel requis.\n'; exit 2
  fi
  if [[ "$ID" == ubuntu ]]; then
    fichier_netplan=/etc/netplan/99-tp01-lab.yaml
    existait=0
    if sudo test -e "$fichier_netplan"; then
      existait=1; sudo cp -a "$fichier_netplan" "$sauvegarde/netplan.yaml"
    fi
    printf 'network:\n  version: 2\n  ethernets:\n    %s:\n      dhcp4: false\n      addresses: [%s]\n      optional: true\n' "$interface_lab" "$ip_lab" | sudo tee "$fichier_netplan" >/dev/null
    sudo chmod 600 "$fichier_netplan"
    restauration_netplan() {
      if [[ $existait -eq 1 ]]; then sudo cp -a "$sauvegarde/netplan.yaml" "$fichier_netplan";
      else sudo rm -- "$fichier_netplan"; fi
    }
    if ! sudo netplan generate; then restauration_netplan; exit 1; fi
    printf 'Netplan va tester le reglage. Confirmer si la connexion fonctionne.\n'
    if ! sudo netplan try --timeout 60; then
      restauration_netplan
      printf 'Configuration non confirmee: fichier precedent restaure. Verifier la console et ip -br a.\n'; exit 1
    fi
  else
    run sudo cp -a /etc/NetworkManager/system-connections "$sauvegarde/NetworkManager"
    profil="$(nmcli -t -f UUID,DEVICE connection show --active | awk -F: -v carte="$interface_lab" '$2 == carte {print $1}')"
    if [[ "$profil" == *$'\n'* ]]; then
      printf 'Plusieurs profils actifs sur la carte de laboratoire: examen manuel requis.\n'; exit 2
    fi
    if [[ -z "$profil" || "$profil" == -- ]]; then
      # Retrouver aussi un profil deconnecte deja associe a cette interface.
      while IFS= read -r candidat; do
        [[ -n "$candidat" ]] || continue
        if [[ "$(nmcli -g connection.interface-name connection show "$candidat")" == "$interface_lab" ]]; then
          [[ -z "$profil" || "$profil" == -- ]] || { printf 'Plusieurs profils reseau: examen manuel requis.\n'; exit 2; }
          profil="$candidat"
        fi
      done < <(nmcli -g UUID connection show)
    fi
    if [[ -z "$profil" || "$profil" == -- ]]; then
      run sudo nmcli connection add type ethernet ifname "$interface_lab" con-name tp01-lab \
        ipv4.method manual ipv4.addresses "$ip_lab" ipv4.never-default yes ipv6.method disabled
      profil=tp01-lab
    else
      run sudo nmcli connection modify "$profil" ipv4.method manual ipv4.addresses "$ip_lab" \
        ipv4.never-default yes ipv6.method disabled connection.autoconnect yes
    fi
    run sudo nmcli connection up "$profil"
  fi
  run ip -br a
  run ip route
fi
if [[ $mises_a_jour -eq 1 ]]; then
  if [[ "$ID" == ubuntu ]]; then run sudo apt update; run sudo apt -y full-upgrade;
  else run sudo dnf -y update; run sudo dnf history info last; fi
fi
run timedatectl status
run sudo vgs
printf '\nRedemarrer ensuite avec sudo reboot, puis refaire la collecte.\n'
printf 'Les comptes nominatifs, cles SSH, refus root et la reserve LVM sont a verifier selon le guide.\n'
