<#
.NOTES
    *****************************************************************************
    ETML
    Nom du script: Y-P_Script-Neo-Simon.ps1
    Auteur:	Simon Boschetti & Néo Darbellay
    Date:	03.02.2025
 	*****************************************************************************
    Modifications
 	Date  : 20.01.2025
 	Auteur: Simon et Néo
 	Raisons: Création initiale du script

    Date  : 27.01.2025
 	Auteur: Simon et Néo
 	Raisons: Continuation du script

    Date  : 03.02.2025
 	Auteur: Simon et Néo
 	Raisons: [VERSION 0.9.0] du script (marche localement, manque les applications & multiples disques)

    Date  : 16.02.2025
 	Auteur: Simon et Néo
 	Raisons: [VERSION 1.0.0] Correction et optimisation des boucles, ajout des programmes installés dans le fichier log et l'option d'avoir un fichier log ou non

    Date  : -
 	Auteur: -
 	Raisons: -

    Date  : -
 	Auteur: -
 	Raisons: -

    Date  : -
 	Auteur: -
 	Raisons: -
 	*****************************************************************************
.SYNOPSIS
    Description courte
	Automatiser un script pour récupérer des informations concernant une machine

.DESCRIPTION
    Description plus détaillée du script, avec les actions et les tests effectuées ainsi que les résultats possibles

.PARAMETER LogFilePath
    Le paramètre LogFilePath spécifie le chemin où le fichier journal doit être sauvegardé.
    Il doit s'agir d'un chemin de fichier `.log` valide.
.PARAMETER DistantComputerName
    Description du deuxième paramètre avec les limites et contraintes

.PARAMETER DistantComputerIP
    Description du troisième paramètre avec les limites et contraintes

.OUTPUTS
    Un fichier sysloginfo.log, modifié à chaque fois que le script se lance.

.EXAMPLE
	.\CanevasV3.ps1 -Param1 Toto -Param2 Titi -Param3 Tutu
	La ligne que l'on tape pour l'exécution du script avec un choix de paramètres
	Résultat : par exemple un fichier, une modification, un message d'erreur

.EXAMPLE
	.\CanevasV3.ps1
	Résultat : Sans paramètre, affichage de l'aide

.LINK
    D'autres scripts utilisés dans ce script
#>

<# Le nombre de paramètres doit correspondre à ceux définis dans l'en-tête
   Il est possible aussi qu'il n'y ait pas de paramètres mais des arguments
   Un paramètre peut être typé : [string]$Param1
   Un paramètre peut être initialisé : $Param2="Toto"
   Un paramètre peut être obligatoire : [Parameter(Mandatory=$True][string]$Param3
#>
# La définition des paramètres se trouve juste après l'en-tête et un commentaire sur le.s paramètre.s est obligatoire
param($LogFilePath, $DistantComputerName, $DistantComputerIP)

###################################################################################################################

$titre_date = Get-Date -Format "yyyy.MM.dd hh:mm:ss"                                                # Date utilisé dans l'en-tête
$titre_top = "╔═══════════════════════════════════════════════════════════════════════════════╗"    # En-tête du script (s'affiche dans powershell)
$titre_hea = "║                                 SYSINFO LOGGER                                ║"    # En-tête du script (s'affiche dans powershell)
$titre_mid = "╟═══════════════════════════════════════════════════════════════════════════════╣"    # En-tête du script (s'affiche dans powershell)
$titre_bod = "║ Collecte fait le $titre_date                                          ║"            # En-tête du script (s'affiche dans powershell)
$titre_end = "╚═══════════════════════════════════════════════════════════════════════════════╝"    # En-tête du script (s'affiche dans powershell)

$date_log = Get-Date -Format "yyyy-MM-dd hh:mm"                                                     # Date de journalisation
$titre_log                                                                                          # Titre du fichier log

$Path                                                                                               # Chemin du fichier log

$adress                                                                                             # Addresse IP de l'ordinateur

$computerInfo                                                                                       # Infos sur l'ordinateur
$systemInfo                                                                                         # Système d'exploitation

$processor                                                                                          # Infos processeur
$gpu                                                                                                # Infos carte graphique

$disks                                                                                              # Infos disques de stockage

$ram                                                                                                # Infos RAM totale
$ramUsed                                                                                            # Infos RAM utilisée                                                                                            #

$packages                                                                                           #Paquets installés sur le système Les packets logiciels installés sur l'ordinateur

$timezone = Get-TimeZone                                                                            # Fuseau Horaire

# Fonction utilisé pour écrire les applications dans le fichier .log
function Write-Apps([Parameter(Mandatory = $True)] $packetTable) {
    $appsTable = @()                                # Créer une nouvelle table pour storer les applications plus tard

    # Boucle for each pour mettre toutes les applications dans une table séparée
    foreach ($packet in $packetTable) {

        # Vérifie que le packet est bel et bien un programme
        if ($packet.ProviderName -eq "Programs") {
            $appsTable += $packet
        }
    }

    # Boucle for each pour écrire toute les applications dans le fichier log
    foreach ($app in $appsTable) {
        # Créer la ligne qui va s'affiche pour l'application actuelle
        $appLine = $app.Name + " Version " + $app.Version

        # Afficher la ligne
        Add-Content $Path -Value $appLine -NoNewline

        # Vérifie que $app n'est pas la dernière instance de $apps
        if (!($appsTable[-1] -eq $app)) {
            Add-Content $Path -Value ", " -NoNewline
        }
        # Si c'est la dernière application
        else {
            Add-Content $Path -Value "`n" -NoNewline
        }

    }
}

###################################################################################################################

# Verifier que $LogPath n'est pas vide
if (!($null -eq $LogFilePath)) {
    # Verifier que $LogPath est un chemin valide et qui mène à un fichier log
    if ($LogFilePath -match '\.log$' -and (Test-Path -Path (Split-Path -Parent $LogFilePath))) {
        # Ajouter le chemin à la variable $Path
        $Path = $LogFilePath
    }
    # Le chemin n'existe pas
    else {
        # Efface la console
        Clear-Host

        # Montre l'aide du paramètre LogFilePath
        (Get-Help $MyInvocation.MyCommand.Path).parameters.parameter |
        Where-Object { $_.name -eq "LogFilePath" } |
        Select-Object -ExpandProperty description | ForEach-Object { $_.Text } |
        Write-Host -ForegroundColor Yellow

        # Ajoute un retour à la ligne
        Write-Host $null

        # Lance une erreur
        throw [System.ArgumentException]::new("La valeur donnée au paramètre LogPath n'est pas valide. Veuillez réessayer avec l'aide montrée en dessus.")

        # Ferme le programme
        exit
    }
}
# $LogPath est vide
else {
    $Path = $null
}

###################################################################################################################

# Initialisation de variables
$titre_log = $date_log + " - " + $systemInfo.Name + "/" + $adresse.IPAddress + " - "

$adress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress

$computerInfo = Get-ComputerInfo
$systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem

$processor = (Get-CimInstance -ClassName CIM_Processor).Name
$gpu = (Get-CimInstance -ClassName CIM_VideoController).Name

$ram = [Math]::Round($computerInfo.CsTotalPhysicalMemory / 1GB, 2)
$ramUsed = [Math]::Round($computerInfo.CsTotalPhysicalMemory / 1GB - $computerInfo.OsFreePhysicalMemory / 1MB, 2)

$disks = Get-Volume

$packages = Get-Package

# Effacer les entrées
Clear-Host
# Affichage de l'en-tête dans le terminal
Write-Host $titre_top
Write-Host $titre_hea
Write-Host $titre_mid
Write-Host $titre_bod
Write-Host $titre_end
Write-Host ""

# Affichage des information sur l'OS dans le terminal
Write-Host "┌ OPERATING SYSTEM"
Write-Host "| Hostname:`t" $systemInfo.Name
Write-Host "| IP:`t`t" $adress
Write-Host "| OS:`t`t" $computerInfo.OsName
Write-Host "└ Version:`t" $computerInfo.OsVersion "Build" $computerInfo.OsBuildNumber
Write-Host ""

# Affichage des information sur le hardware dans le terminal
Write-Host "┌ HARDWARE"
Write-Host "| CPU:`t`t" $processor
Write-Host "| GPU 0:`t" $gpu

# Afficher les disques

#boucle foreach pour tout les disques
foreach ($disk in $disks) {
    # Prendre la lettre du volume
    $diskLetter = $disk.DriveLetter

    # Prendre le type du volume
    $diskType = $disk.DriveType

    # Si la lettre n'est pas null et que le type de volume n'est pas CD-ROM
    if (!($null -eq $diskLetter -or "CD-ROM" -eq $diskType)) {
        # Prendre toute les informations utiles
        $diskSize = [Math]::Round($disk.Size / 1GB, 2)
        $diskRemainingSize = [Math]::Round(($disk.Size - $disk.SizeRemaining) / 1GB, 2)

        # Afficher le disque
        Write-Host "| Disque"$diskLetter":`t" $diskRemainingSize "/" $diskSize "GB"
    }
}

# Afficher la ram
Write-Host "└ RAM:`t`t" $ramUsed "/" $ram "GB"
Write-Host ""

# Verifier que $Path n'est pas null
if (!($null -eq $Path)) {
    # Affichage des informations dans le fichier sysloginfo.log
    $titre_log + "OS: " + $computerInfo.OsName +
    " - Version: " + $computerInfo.OsVersion + " Build " + $computerInfo.OsBuildNumber | Add-Content .\log\sysloginfo.log -NoNewline

    # Afficher les disques

    #boucle foreach pour tout les disques
    #boucle foreach pour tout les disques
    foreach ($disk in $disks) {
        # Prendre la lettre du volume
        $diskLetter = $disk.DriveLetter

        # Prendre le type du volume
        $diskType = $disk.DriveType

        # Si la lettre n'est pas null et que le type de volume n'est pas CD-ROM
        if (!($null -eq $diskLetter -or "CD-ROM" -eq $diskType)) {
            # Prendre toute les informations utiles
            $diskSize = [Math]::Round($disk.Size / 1GB, 2)
            $diskRemainingSize = [Math]::Round(($disk.Size - $disk.SizeRemaining) / 1GB, 2)

            # Afficher le disque dans le fichier log
            " - Utilisation de l'espace disque " + $diskLetter + ": " +
            $diskRemainingSize + " / " + $diskSize + " GB" | Add-Content $Path -NoNewline
        }
    }

    # Afficher le reste
    " - RAM: " + $ramUsed + " / " + $ram + " GB" | Add-Content $Path

    # Afficher les programmes installés
    $titre_log + "Programmes installés : " | Add-Content $Path -NoNewline

    # Appel de la fonction Write-Apps
    Write-Apps($packages)

    # Afficher le fuseau horraire
    $titre_log + "Fuseau Horaire : " + $timezone + "`n" | Add-Content $Path
}