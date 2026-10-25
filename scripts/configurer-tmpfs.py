#!/usr/bin/env python3
"""Prepare une entree /tmp sans modifier les autres montages de fstab."""
import argparse
from pathlib import Path

ENTRY = 'tmpfs /tmp tmpfs defaults,nosuid,nodev,mode=1777,size=512M 0 0'


def transformer(texte):
    lignes = texte.splitlines()
    trouve = []
    for i, ligne in enumerate(lignes):
        champs = ligne.split('#', 1)[0].split()
        if len(champs) >= 2 and champs[1] == '/tmp':
            if len(champs) < 3 or champs[2] != 'tmpfs':
                raise ValueError('/tmp possede deja un montage autre que tmpfs : examen manuel requis.')
            trouve.append(i)
    if len(trouve) > 1:
        raise ValueError('Plusieurs entrees /tmp existent : examen manuel requis.')
    if trouve:
        lignes[trouve[0]] = ENTRY
    else:
        lignes.extend(['', '# TP1 - repertoire temporaire', ENTRY])
    return '\n'.join(lignes) + '\n'


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('source', type=Path)
    p.add_argument('destination', type=Path)
    args = p.parse_args()
    if args.source.resolve() == args.destination.resolve():
        p.error('Utiliser un fichier de preparation distinct du fichier source.')
    try:
        resultat = transformer(args.source.read_text(encoding='utf-8'))
    except ValueError as exc:
        p.error(str(exc))
    args.destination.write_text(resultat, encoding='utf-8')


if __name__ == '__main__':
    main()
