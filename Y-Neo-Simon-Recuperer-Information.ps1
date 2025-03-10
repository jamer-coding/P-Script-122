<#
.NOTES
    *****************************************************************************
    ETML
    Nom du script	:	Y-P_Script-Neo-Simon.ps1
    Auteur			:	Simon Boschetti & Néo Darbellay
    Date			:	03.02.2025
 	*****************************************************************************
    Modifications
 	Date	:	20.01.2025
 	Auteur	:	Simon et Néo
 	Raisons	:	[VERSION 0.0.1] Création initiale du script

    Date	:	27.01.2025
 	Auteur	:	Simon et Néo
 	Raisons	:	[VERSION 0.0.2] Continuation du script

    Date	:	03.02.2025
 	Auteur	:	Simon et Néo
 	Raisons	:	[VERSION 0.9.0] du script (marche localement, manque les applications & multiples disques)

    Date	:	16.02.2025
 	Auteur	:	Simon et Néo
 	Raisons	:	[VERSION 1.0.0] Correction et optimisation des boucles, ajout des programmes installés dans le fichier log et l'option d'avoir un fichier log ou non

    Date	:	24.02.2025
 	Auteur	:	Simon et Néo
 	Raisons	:	[VERSION 1.9.0] Ajout des commentaires d'aide et implémentation du remoting (pas fonctionnel pour le moment)

    Date	:	03.03.2025
 	Auteur	:	Simon et Néo
 	Raisons	:	[VERSION 1.9.5] Simplification du code et implémentation du remoting semi-fonctionnel

    Date	:	04.03.2025
 	Auteur	:	Néo
 	Raisons	:	[Version 2.0.0] Modification du code pour simplifier le remoting, qui fonctionne parfaitement

    Date	:	10.03.2025
 	Auteur	:	Simon et Néo
 	Raisons	:	[Version 2.1.0] Optimisation du code et gestion des erreurs

    Date	:	10.03.2025
 	Auteur	:	Simon et Néo
    Raison	:	[Version 2.1.1] Rectification des commentaires
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
    Paramètre utilisé pour retourner la collecte sous forme de ligne

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
    Les paramètres utiles à l'utilisateur :
    	LogFilePath         :	Chemin d'accès d'un fichier log pour journaliser la collecte
    	DistantComputerIP   :	L'adresse IP d'un ordinateur à distance pour la collecte d'information

.OUTPUTS
    Les informations système sous la forme d'une liste, et, optionnellement, sous format ligne dans un fichier journal (.log)

.LINK
    Aucun lien avec d'autres fichiers
#>

param([string] $LogFilePath, [ipaddress] $DistantComputerIP, [string] $DistantComputerName, [switch] $ReturnLine)

###################################################################################################################

$titre_date = Get-Date -Format "yyyy.MM.dd HH:mm:ss"                                                # Date utilisée dans l'en-tête
$titre_top = "╔═══════════════════════════════════════════════════════════════════════════════╗"    # En-tête du script (s'affiche dans PowerShell)
$titre_hea = "║                                 SYSINFO LOGGER                                ║"    # En-tête du script (s'affiche dans PowerShell)
$titre_mid = "╟═══════════════════════════════════════════════════════════════════════════════╣"    # En-tête du script (s'affiche dans PowerShell)
$titre_bod = "║ Collecte fait le $titre_date                                          ║"            # En-tête du script (s'affiche dans PowerShell)
$titre_end = "╚═══════════════════════════════════════════════════════════════════════════════╝"    # En-tête du script (s'affiche dans PowerShell)

$date_log = Get-Date -Format "yyyy-MM-dd HH:mm"                                                     # Date de journalisation
$titre_log = $null                                                                                  # Titre du fichier .log

$path = $null                                                                                       # Chemin du fichier .log

$session = $null                                                                                    # Session PowerShell sur une machine distante

$addresses = $null                                                                                  # Adresses IP de l'ordinateur local

$versionOS = $null                                                                                  # Version de l'OS
$systemInfo = $null                                                                                 # Système d'exploitation

$processor = $null                                                                                  # Infos processeur
$gpu = $null                                                                                        # Infos carte graphique

$disks = $null                                                                                      # Infos disques de stockage

$ram = $null                                                                                        # Infos RAM (tableau)
$ramTotal = $null                                                                                   # Info RAM total
$ramUsed = $null                                                                                    # Info RAM utilisée

$packages = $null                                                                                   # Paquets installés sur le système

$timezone = Get-TimeZone                                                                            # Fuseau Horaire

# Fonction utilisée pour écrire les applications (dans un fichier .log ou non)
function Write-Apps([Parameter(Mandatory = $True)] $packetTable, [switch] $isLog) {
    $appsTable = @()                                # Créer une nouvelle table pour storer les applications plus tard

    # Boucle foreach pour mettre toutes les applications dans une table séparée
    foreach ($packet in $packetTable) {

        # Vérifie que le packet est bel et bien un programme
        if ($packet.ProviderName -eq "Programs") {
            $appsTable += $packet
        }
    }

    # Boucle foreach pour écrire toute les applications dans le fichier .log
    foreach ($app in $appsTable) {
        # Crée la ligne qui va s'afficher pour l'application actuelle
        $appLine = $app.Name + " Version " + $app.Version

        # Vérifie qu'isLog a été appelé
        if ($isLog) {
            # Affiche la ligne
            Add-Content $path -Value $appLine -NoNewline

            # Vérifie que $app n'est pas la dernière instance de $apps
            if (!($appsTable[-1] -eq $app)) {
                Add-Content $path -Value ", " -NoNewline
            }
        }
        # Pas de fichier .log
        else {
            # Affiche la ligne
            Write-Host $appLine -NoNewline

            # Vérifie que $app n'est pas la dernière instance de $apps
            if (!($appsTable[-1] -eq $app)) {
                Write-Host ", " -NoNewline
            }
        }
    }
}

###################################################################################################################

# Vérifie que $LogFilePath a été appelé
if ($LogFilePath) {
    # Vérifie que $LogFilePath est un chemin valide et qui mène à un fichier .log
    if ($LogFilePath -match '\.log$' -and (Test-Path -Path (Split-Path -Parent $LogFilePath))) {
        # Ajoute le chemin à la variable $path
        $path = $LogFilePath
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
    $path = $null
}

# Vérifie que DistantComputerName a été appelé
if ($DistantComputerName) {
    # Vérifie qu'une connection peut être faite
    if (Test-Connection -ComputerName $DistantComputerName -Count 1 -Quiet) {
        # Trouve l'adresse IP de la machine distante grâce à son adresse IP
        $DistantComputerIP = [System.Net.Dns]::GetHostByName($DistantComputerName).AddressList.IPAddressToString
    }
    # L'adresse IP n'est pas valide
    else {
        # Efface la console
        Clear-Host

        # Lance une erreur
        throw [System.ArgumentException]::new("Le nom d'ordinateur donné au paramètre DistantComputerName n'est pas valide. Veuillez réessayer.")

        # Ferme le programme
        exit
    }

}
# Vérifie que DistantComputerIP a été appelé
elseif ($DistantComputerIP) {
    # Vérifie qu'une connection peut être faite
    if (Test-Connection -IPAddress $DistantComputerIP -Count 1 -Quiet) {
        # Trouve le nom de la machine distante grâce à son adresse IP
        $DistantComputerName = [System.Net.Dns]::GetHostByAddress($DistantComputerIP).Hostname
    }
    # L'adresse IP n'est pas valide
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
    # Ouvre une session PowerShell
    $session = New-PSSession -ComputerName $DistantComputerName -Credential Get-Credential

    # Vérifie que la session a été créée
    if ($session) {
        # Initialisation de variables de l'autre machine
        $addresses = Invoke-Command -Session $session -ScriptBlock { Get-NetIPAddress -AddressFamily IPv4 }

        $versionOS = Invoke-Command -Session $session -ScriptBlock { [System.Environment]::OSVersion.Version }
        $systemInfo = Invoke-Command -Session $session -ScriptBlock { Get-CimInstance -ClassName Win32_ComputerSystem }

        $processor = Invoke-Command -Session $session -ScriptBlock { (Get-CimInstance -ClassName CIM_Processor).Name }
        $gpu = Invoke-Command -Session $session -ScriptBlock { (Get-CimInstance -ClassName CIM_VideoController).Name }

        $ram = Invoke-Command -Session $session -ScriptBlock { Get-CimInstance -ClassName CIM_OperatingSystem }

        $disks = Invoke-Command -Session $session -ScriptBlock { Get-Volume }

        $packages = Invoke-Command -Session $session -ScriptBlock { Get-Package }
    }
    # La session n'a pas été créée
    else {
        # Efface les entrées
        Clear-Host

        throw [System.ArgumentException]::new("Erreur d'ouverture de session vers la machine '$DistantComputerName'. Veuillez réessayer.")
    }
}
# Pas de machine distante à vérifier
else {
    # Initialisation des variables sur la machine locale
    $addresses = Get-NetIPAddress -AddressFamily IPv4

    $versionOS = [System.Environment]::OSVersion.Version
    $systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem

    $processor = (Get-CimInstance -ClassName CIM_Processor).Name
    $gpu = (Get-CimInstance -ClassName CIM_VideoController).Name

    $ram = Get-CimInstance -ClassName CIM_OperatingSystem

    $disks = Get-Volume

    $packages = Get-Package

}

# Efface les entrées
Clear-Host

# Calcule de la ram
$ramTotal = [Math]::Round($systemInfo.TotalPhysicalMemory / 1GB, 2)
$ramUsed = [Math]::Round($systemInfo.TotalPhysicalMemory / 1GB - $ram.FreePhysicalMemory * 1KB / 1GB, 2)

# Vérification pour voir si $addresses est un tableau
if ($addresses.Length -gt 0) {
    $titre_log = $date_log + " - " + $systemInfo.Name + "/" + $addresses[0].IPAddress + " - "
}
# Ce n'est pas un tableau
else {
    $titre_log = $date_log + " - " + $systemInfo.Name + "/" + $addresses.IPAddress + " - "
}

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
    Write-Host "|"
    Write-Host "├ ADRESSES IP"

    # Afficher les adresses IP
    foreach ($IP in $addresses) {
        Write-Host "|  Interface :`t", $($IP.InterfaceAlias)
        Write-Host "|  Adresse IP :`t", $($IP.IPAddress)
        Write-Host "|"
    }

    Write-Host "| OS:`t`t" $systemInfo.Caption
    Write-Host "└ Version:`t" $versionOS.Major "." $versionOS.Minor "." $versionOS.Build "Build" $versionOS.Build
    Write-Host ""

    # Affichage des information sur le hardware dans le terminal
    Write-Host "┌ HARDWARE"
    Write-Host "| CPU:`t`t" $processor
    Write-Host "| GPU:`t`t" $gpu

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
    Write-Host "└ RAM:`t`t" $ramUsed "/" $ramTotal "GB"
    Write-Host ""

    # Vérifier que $path n'est pas null
    if (!($null -eq $path)) {
        # Affichage des informations dans le fichier sysloginfo.log
        $titre_log + "OS: " + $systemInfo.Caption +
        " - Version: " + $versionOS.Major + "." + $versionOS.Minor + "." + $versionOS.Build + " Build " + $versionOS.Build | Add-Content $path -NoNewline

        # Afficher les disques

        # Boucle foreach pour tout les disques
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
                $diskRemainingSize + " / " + $diskSize + " GB" | Add-Content $path -NoNewline
            }
        }

        # Afficher le reste
        " - RAM: " + $ramUsed + " / " + $ramTotal + " GB" | Add-Content $path

        # Afficher les programmes installés
        $titre_log + "Programmes installés : " | Add-Content $path -NoNewline

        # Appel de la fonction Write-Apps
        Write-Apps -packetTable $packages -isLog

        # Ajout d'une nouvelle ligne
        Add-Content $path -Value "`n" -NoNewline

        # Afficher le fuseau horraire
        $titre_log + "Fuseau Horaire : " + $timezone + "`n" | Add-Content $path
    }
}
# ReturnLine a été appelé
else {
    # Affichage des informations dans le fichier log
    $titre_log + "OS: " + $systemInfo.Caption +
    " - Version: " + $versionOS.Major + "." + $versionOS.Minor + "." + $versionOS.Build + " Build " + $versionOS.Build | Write-Host -NoNewline

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

            # Afficher le disque dans le fichier log
            " - Utilisation de l'espace disque " + $diskLetter + ": " +
            $diskRemainingSize + " / " + $diskSize + " GB" | Write-Host -NoNewline
        }
    }

    # Afficher le reste
    " - RAM: " + $ramUsed + " / " + $ramTotal + " GB" | Write-Host

    # Afficher les programmes installés
    $titre_log + "Programmes installés : " | Write-Host -NoNewline

    # Appel de la fonction Write-Apps
    Write-Apps -packetTable $packages

    # Ajout d'une nouvelle ligne
    Write-Host "`n" -NoNewline

    # Affiche le fuseau horraire
    $titre_log + "Fuseau Horaire : " + $timezone + "`n" | Write-Host
}