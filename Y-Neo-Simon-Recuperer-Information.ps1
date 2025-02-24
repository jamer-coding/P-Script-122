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
 	Raisons: [VERSION 0.1.0] Création initiale du script

    Date  : 27.01.2025
 	Auteur: Simon et Néo
 	Raisons: [VERSION 0.4.0] Continuation du script

    Date  : 03.02.2025
 	Auteur: Simon et Néo
 	Raisons: [VERSION 0.9.0] du script (marche localement, manque les applications & multiples disques)

    Date  : 16.02.2025
 	Auteur: Simon et Néo
 	Raisons: [VERSION 1.0.0] Correction et optimisation des boucles, ajout des programmes installés dans le fichier log et l'option d'avoir un fichier log ou non

    Date  : 24.02.2025
 	Auteur: Simon et Néo
 	Raisons: [VERSION 1.9.0] Ajout des commentaires d'aide et implémentation du remoting (pas fonctionnel pour le moment)

    Date  : -
 	Auteur: -
 	Raisons: -

    Date  : -
 	Auteur: -
 	Raisons: -
 	*****************************************************************************

.SYNOPSIS
    Script de collection d'informations sur un ordinateur

.DESCRIPTION
    Ce script est utilisé pour la collecte d'information sur l'ordinateur local, ou un ordinateur distant.
    Il est possible de donner un chemin d'accès d'un fichier journal (.log) pour sauvegarder les informations.
    Il est aussi possible de donner une adresse IP distante pour prendre des informations d'une machine à distance au lieu de l'ordinateur local.

.PARAMETER LogFilePath
    Le paramètre LogFilePath spécifie le chemin où le fichier journal doit être sauvegardé.
    Il doit s'agir d'un chemin de fichier `.log` valide.

.PARAMETER DistantComputerIP
    L'adresse IP d'une machine à distance.
    La machine doit être dans le même réseau, avec son FireWall désactivé.

.PARAMETER DistantComputerName
    Le nom d'une machine à distance.
    La machine doit être dans le même réseau, avec son FireWall désactivé.

.PARAMETER ReturnLine
    Paramètre utilisé pour retourner la journalisation au lieu du

.PARAMETER h
    Un paramètre utilisé pour montrer l'aide du script

.PARAMETER help
    Un paramètre utilisé pour montrer l'aide du script

.EXAMPLE
	.\Y-Neo-Simon-Recuperer-Information.ps1
	Résultat : Affiche les informations récupérées par le script dans l'environnement actuel (ex. console)

.EXAMPLE
	.\Y-Neo-Simon-Recuperer-Information.ps1 -LogFilePath .\log\systemInfo.log
	Résultat : Affiche les informations récupérées par le script et l'ajoute dans un fichier .log situé dans le chemin indiqué en format ligne

.EXAMPLE
	.\Y-Neo-Simon-Recuperer-Information.ps1 -LogFilePath .\log\
	Résultat : Une erreur apparait, car le chemin du fichier .log n'est pas complet où n'existe pas

.EXAMPLE
	.\Y-Neo-Simon-Recuperer-Information.ps1 -DistantComputerIP 169.254.134.68
	Résultat : Affiche les informations récupérées par le script dans l'environnement de la  à distance

.INPUTS
    Les paramètres utiles à l'utilisateur
    LogFilePath         : Chemin d'accès d'un fichier log pour journaliser la collecte
    DistantComputerIP   : L'adresse IP d'un ordinateur à distance pour la collecte d'information
    h & help            : Paramètre pour afficher l'aide du script

.OUTPUTS
    Les informations système sous la forme d'une liste, et, optionnellement, sous format ligne dans un fichier journal (.log)

.LINK
    Aucun lien avec d'autres fichiers
#>

<# Le nombre de paramètres doit correspondre à ceux définis dans l'en-tête
   Il est possible aussi qu'il n'y ait pas de paramètres mais des arguments
   Un paramètre peut être typé : [string]$Param1
   Un paramètre peut être initialisé : $Param2="Toto"
   Un paramètre peut être obligatoire : [Parameter(Mandatory=$True][string]$Param3
#>
# La définition des paramètres se trouve juste après l'en-tête et un commentaire sur le.s paramètre.s est obligatoire
param([string] $LogFilePath, [ipaddress] $DistantComputerIP, [string] $DistantComputerName, [switch] $ReturnLine, [switch] $h, [switch] $help)

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

$session                                                                                            # Session powershell sur une machine distante

$adress                                                                                             # Addresse IP de l'ordinateur local

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
function Write-Apps([Parameter(Mandatory = $True)] $packetTable, [switch] $isLog) {
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

        # Vérifier qu'isLog a été appelé
        if ($isLog) {
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
        # Pas de fichier log
        else {
            # Afficher la ligne
            Write-Host $appLine -NoNewline

            # Vérifie que $app n'est pas la dernière instance de $apps
            if (!($appsTable[-1] -eq $app)) {
                Write-Host ", " -NoNewline
            }
            # Si c'est la dernière application
            else {
                Write-Host "`n" -NoNewline
            }
        }
    }
}

###################################################################################################################

# Vérifier que soit $h soit $help a été appelé
if ($h -or $help) {
    # Effacer la console
    Clear-Host

    # Afficher l'aide
    Get-Help $MyInvocation.MyCommand.Path -Full | Out-Default

    # Quitter le script
    exit
}

# Vérifier que $LogFilePath a été appelé
if ($LogFilePath) {
    # Vérifier que $LogFilePath est un chemin valide et qui mène à un fichier log
    if ($LogFilePath -match '\.log$' -and (Test-Path -Path (Split-Path -Parent $LogFilePath))) {
        # Ajouter le chemin à la variable $Path
        $Path = $LogFilePath
    }
    # Le chemin n'existe pas
    else {
        # Efface la console
        Clear-Host

        # Lance une erreur
        throw [System.ArgumentException]::new("Le chemin d'accès donné au paramètre LogFilePath n'est pas valide. Veuillez réessayer.")

        # Ferme le programme
        exit
    }
}
# $LogFilePath est vide
else {
    $Path = $null
}

# Vérifier que DistantComputerName a été appelé
if ($DistantComputerName) {
    # Vérifie qu'une connection peut être faite
    if (Test-Connection -ComputerName $DistantComputerName -Count 1 -Quiet) {
        # Trouver l'adresse IP de la machine distante grâce à son adresse IP
        $DistantComputerIP = [System.Net.Dns]::GetHostByName($DistantComputerName).AddressList.IPAddressToString
    }
    # L'adresse ip n'est pas valide
    else {
        # Efface la console
        Clear-Host

        # Lance une erreur
        throw [System.ArgumentException]::new("Le nom d'ordinateur donné au paramètre DistantComputerName n'est pas valide. Veuillez réessayer.")

        # Ferme le programme
        exit
    }

}
# Vérifier que DistantComputerIP a été appelé
elseif ($DistantComputerIP) {
    # Vérifie qu'une connection peut être faite
    if (Test-Connection -IPAddress $DistantComputerIP -Count 1 -Quiet) {
        # Trouver le nom de la machine distante grâce à son adresse IP
        $DistantComputerName = [System.Net.Dns]::GetHostByAddress($DistantComputerIP).Hostname
    }
    # L'adresse ip n'est pas valide
    else {
        # Efface la console
        Clear-Host

        # Lance une erreur
        throw [System.ArgumentException]::new("L'adresse IP donnée au paramètre DistantComputerIP n'est pas valide. Veuillez réessayer.")

        # Ferme le programme
        exit
    }

}

###################################################################################################################

# Vérifie qu'on a un nom de machine distante
if ($DistantComputerName) {
    # Ouvrir une session PowerShell
    $session = New-PSSession -ComputerName $DistantComputerName -Credential Get-Credential # ERREUR??? DEMANDER AU PROFESSEUR

    # Invoquer le script dans la session de l'autre machine
    Invoke-Command -Session $session -FilePath $MyInvocation.MyCommand.Path | Write-Host

    # Vérifier que $Path n'est pas null
    if (!($null -eq $Path)) {
        # Invoquer le script dans la session de l'autre machine et donne seulement le résultat sous format ligne pour le mettre dans le fichier log
        Invoke-Command -Session $session -FilePath $MyInvocation.MyCommand.Path -ReturnLine | Add-Content $Path
    }
}
# Pas de machine distante à vérifier
else {
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

    # Vérifier que ReturnLine n'a pas été appelé
    if (!$ReturnLine) {
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

        # Vérifier que $Path n'est pas null
        if (!($null -eq $Path)) {
            # Affichage des informations dans le fichier sysloginfo.log
            $titre_log + "OS: " + $computerInfo.OsName +
            " - Version: " + $computerInfo.OsVersion + " Build " + $computerInfo.OsBuildNumber | Add-Content $Path -NoNewline

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
            Write-Apps -packetTable $packages -isLog

            # Afficher le fuseau horraire
            $titre_log + "Fuseau Horaire : " + $timezone + "`n" | Add-Content $Path
        }
    }
    # ReturnLine a été appelé
    else {
        # Affichage des informations dans le fichier log
        $titre_log + "OS: " + $computerInfo.OsName +
        " - Version: " + $computerInfo.OsVersion + " Build " + $computerInfo.OsBuildNumber | Write-Host -NoNewline

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
                $diskRemainingSize + " / " + $diskSize + " GB" | Write-Host -NoNewline
            }
        }

        # Afficher le reste
        " - RAM: " + $ramUsed + " / " + $ram + " GB" | Write-Host

        # Afficher les programmes installés
        $titre_log + "Programmes installés : " | Write-Host -NoNewline

        # Appel de la fonction Write-Apps
        Write-Apps -packetTable $packages

        # Afficher le fuseau horraire
        $titre_log + "Fuseau Horaire : " + $timezone + "`n" | Write-Host
    }
}