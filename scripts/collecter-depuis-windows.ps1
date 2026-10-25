param(
    [Parameter(Mandatory=$true)][ValidateSet('env-a','env-b')][string]$Environnement,
    [Parameter(Mandatory=$true)][string]$IpRhel,
    [Parameter(Mandatory=$true)][string]$IpUbuntu,
    [string]$UtilisateurRhel = 'vlad',
    [string]$UtilisateurUbuntu = 'vlad',
    [string]$ClePrivee = ''
)
$ErrorActionPreference = 'Stop'
foreach ($nomCommande in @('ssh','scp')) {
    if (-not (Get-Command $nomCommande -ErrorAction SilentlyContinue)) { throw "Commande introuvable : $nomCommande" }
}
$optionsCle = @()
if ($ClePrivee) {
    if (-not (Test-Path -LiteralPath $ClePrivee -PathType Leaf)) { throw 'Cle privee introuvable.' }
    $optionsCle = @('-i', $ClePrivee)
}
$racine = Split-Path $PSScriptRoot -Parent
$destination = Join-Path $racine "tp01/preuves/$Environnement"
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$horodatage = Get-Date -Format 'yyyyMMddTHHmmssfff'
$sauvegarde = Join-Path $destination "historique/$horodatage"
$anciens = @(Get-ChildItem -LiteralPath $destination -File -Filter '*.txt')
if ($anciens.Count -gt 0) {
    New-Item -ItemType Directory -Force -Path $sauvegarde | Out-Null
    foreach ($ancien in $anciens) { Copy-Item -LiteralPath $ancien.FullName -Destination $sauvegarde }
}
$scriptLinux = Join-Path $PSScriptRoot 'collecter-preuves.sh'
$scriptControle = Join-Path $PSScriptRoot 'verifier-tp01.sh'
$machines = @(
    @{ Nom='rhel9-lab'; Ip=$IpRhel; Compte=$UtilisateurRhel },
    @{ Nom='ubuntu24-lab'; Ip=$IpUbuntu; Compte=$UtilisateurUbuntu }
)
foreach ($machine in $machines) {
    $cible = "$($machine.Compte)@$($machine.Ip)"
    & scp @optionsCle $scriptLinux "${cible}:collecter-preuves-tp01.sh"
    if ($LASTEXITCODE -ne 0) { throw "Copie du script impossible : $cible" }
    & scp @optionsCle $scriptControle "${cible}:verifier-tp01.sh"
    if ($LASTEXITCODE -ne 0) { throw "Copie du controle impossible : $cible" }
    & ssh @optionsCle -t $cible "bash collecter-preuves-tp01.sh $Environnement"
    if ($LASTEXITCODE -ne 0) { throw "Collecte interrompue : $cible" }
    & ssh @optionsCle -t $cible "bash verifier-tp01.sh $Environnement"
    if ($LASTEXITCODE -ne 0) { Write-Host "Controles a corriger sur $cible ; leurs resultats restent enregistres." }
    & scp @optionsCle "${cible}:tp01-preuves/$Environnement/$($machine.Nom).txt" $destination
    if ($LASTEXITCODE -ne 0) { throw "Recuperation impossible : $cible" }
    & scp @optionsCle "${cible}:tp01-preuves/$Environnement/lsblk-$($machine.Nom).txt" $destination
    if ($LASTEXITCODE -ne 0) { throw "Recuperation lsblk impossible : $cible" }
    & scp @optionsCle "${cible}:tp01-preuves/$Environnement/controle-$($machine.Nom).txt" $destination
    if ($LASTEXITCODE -ne 0) { throw "Recuperation des controles impossible : $cible" }
    $acces = Join-Path $destination "acces-$($machine.Nom).txt"
    "TEST DE CONNEXION DEPUIS WINDOWS`n$(Get-Date -Format o)`nCompte : $cible" | Set-Content $acces -Encoding utf8
    # La cle peut avoir une passphrase. sudo peut demander le mot de passe du compte.
    $ancienEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & ssh @optionsCle -t -o PreferredAuthentications=publickey -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no $cible 'date -Is; hostname; id; sudo -l; sudo id' 2>&1 | ForEach-Object {
        $ligne = $_.ToString()
        Write-Host $ligne
        Add-Content -Path $acces -Value $ligne -Encoding utf8
    }
    $codeCle = $LASTEXITCODE
    "Code retour connexion par cle : $codeCle" | Add-Content $acces -Encoding utf8
    "`nTEST DU REFUS ROOT" | Add-Content $acces -Encoding utf8
    & ssh @optionsCle -o BatchMode=yes -o ConnectTimeout=10 "root@$($machine.Ip)" true 2>&1 | ForEach-Object {
        $ligne = $_.ToString()
        Write-Host $ligne
        Add-Content -Path $acces -Value $ligne -Encoding utf8
    }
    "Code retour test root : $LASTEXITCODE" | Add-Content $acces -Encoding utf8
    $ErrorActionPreference = $ancienEap
    # Un refus attendu doit etre un refus d'authentification, et non une panne reseau.
}
if ($Environnement -eq 'env-a') {
    foreach ($nom in @('rhel9-lab','ubuntu24-lab')) {
        foreach ($prefixe in @('', 'lsblk-')) {
            $nomFichier = "$prefixe$nom.txt"
            Copy-Item -LiteralPath (Join-Path $destination $nomFichier) -Destination (Join-Path $racine "tp01/preuves/$nomFichier") -Force
        }
    }
}
Write-Host "Preuves disponibles dans $destination"
Write-Host 'Relire les codes retour et les resultats avant de valider les controles.'
