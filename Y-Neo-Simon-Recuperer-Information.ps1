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

    Date  : - 03.02.2025
 	Auteur: - Simon et Néo
 	Raisons: - Version 1.0.0 du script (marche localement)

    Date  : -
 	Auteur: -
 	Raisons: -

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

.PARAMETER CreateNewFile
    Description du premier paramètre avec les limites et contraintes

.PARAMETER Param2
    Description du deuxième paramètre avec les limites et contraintes

.PARAMETER Param3
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
param($distantComputerName)

###################################################################################################################
# Zone de définition des variables et fonctions, avec exemples
$titre_date = Get-Date -Format "yyyy.MM.dd hh:mm:ss"                                                # Date utilisé dans l'en-tête
$titre_top = "╔═══════════════════════════════════════════════════════════════════════════════╗"    # En-tête du script (s'affiche dans powershell)
$titre_hea = "║                                 SYSINFO LOGGER                                ║"    # En-tête du script (s'affiche dans powershell)
$titre_mid = "╟═══════════════════════════════════════════════════════════════════════════════╣"    # En-tête du script (s'affiche dans powershell)
$titre_bod = "║ Collecte fait le $titre_date                                          ║"            # En-tête du script (s'affiche dans powershell)
$titre_end = "╚═══════════════════════════════════════════════════════════════════════════════╝"    # En-tête du script (s'affiche dans powershell)
$adress                                                                                             # Addresse IP de l'ordinateur
$computerInfo                                                                                       # 
$systemInfo
$date_log = Get-Date -Format "yyyy-MM-dd hh:mm"
$titre_log
$processor
$gpu
$disk
$diskSize
$diskRemainingSize
$ram
$ramUsed
$apps
$timezone = Get-TimeZone

# Fonction utilisé pour écrire les objets d'une table dans le fichier .log
function outputTableItems([Parameter(Mandatory = $True)] [table]$table)
{
    # Initialisation des variables
    $currentCount = 0:                  # Compteur pour la boucle for each
    $tableSize = $table.Length - 1      # Taille de la table (moins un pour avoir 0)

    # A MODIFIER                                                            

    # Boucle for each pour écrire toutes les applications, séparé d'une virgule
    foreach ($item in $table) {
        Add-Content .\log\sysloginfo.log -Value $item -NoNewline

        # Vérifie que $application n'est pas la dernière instance de $apps
        if (!($table[$tableSize] -eq $item)) {
            Add-Content .\log\sysloginfo.log -Value ", " -NoNewline
        }
    }
}

###################################################################################################################
# Zone de tests comme les paramètres renseignés ou les droits administrateurs

# Ajout du fichier log en UTF-8 s'il n'existe pas
if (!(Test-Path -Path ".\log\sysloginfo.log")) {
    New-Item -ItemType File -Path ".\log\sysloginfo.log"
    Set-Content -Path ".\log\sysloginfo.log" -Encoding utf8 -Value $null
}

###################################################################################################################
# Corps du script

# Initialisation de variables
$adress = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPAddress
$computerInfo = Get-ComputerInfo
$systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem
$titre_log = $date_log + " - " + $systemInfo.Name + "/" + $adresse.IPAddress + " - "

$processor = (Get-CimInstance -ClassName CIM_Processor).Name
$gpu = (Get-CimInstance -ClassName CIM_VideoController).Name
$ram = [Math]::Round($computerInfo.CsTotalPhysicalMemory/1GB, 2)
$ramUsed = [Math]::Round($computerInfo.CsTotalPhysicalMemory/1GB - $computerInfo.OsFreePhysicalMemory/1MB, 2)
$disk = Get-Volume -DriveLetter C
$diskSize = [Math]::Round($disk.Size/1GB, 2)
$diskRemainingSize = [Math]::Round(($disk.Size - $disk.SizeRemaining)/1GB, 2)

$apps = Get-CimInstance -ClassName Win32_InstalledStoreProgram |Format-Table -AutoSize

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
Write-Host "| Disque C:`t" $diskRemainingSize "/" $diskSize "GB"
Write-Host "└ RAM:`t`t" $ramUsed "/" $ram "GB"
Write-Host ""

# Affichage des informations dans le fichier sysloginfo.log
$titre_log + "OS: " + $computerInfo.OsName +
             " - Version: " + $computerInfo.OsVersion + " Build " + $computerInfo.OsBuildNumber +
             " - Utilisation de l'espace disque C: " + $diskRemainingSize + " / " + $diskSize + " GB"  +
             " - RAM: " + $ramUsed + " / " + $ram + " GB" | Add-Content .\log\sysloginfo.log

$titre_log + "Programmes installés : " | Add-Content .\log\sysloginfo.log -NoNewline

# Appel de la fonction outputTableItems
outputTableItems($apps)


$titre_log + "`nFuseau Horaire : " + $timezone + "`n" | Add-Content .\log\sysloginfo.log