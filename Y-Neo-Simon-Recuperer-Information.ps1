<#
.NOTES
    *****************************************************************************
    ETML
    Nom du script: Y-P_Script-Neo-Simon.ps1
    Auteur:	Simon Boschetti & Néo Darbellay
    Date:	20.01.2025
 	*****************************************************************************
    Modifications
 	Date  : 20.01.2025
 	Auteur: Simon et Néo
 	Raisons: Création initiale du script
    
    Date  : 27.01.2025
 	Auteur: Simon et Néo
 	Raisons: Continuation du script

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
param($Param1, 
    $Param2, 
    $Param3)

###################################################################################################################
# Zone de définition des variables et fonctions, avec exemples
# Commentaires pour les variables
$date= Get-Date -Format "yyyy.mm.dd hh:mm:ss"
$titre_top = "╔═══════════════════════════════════════════════════════════════════════════════╗"
$titre_hea = "║                                 SYSINFO LOGGER                                ║"
$titre_mid = "╟═══════════════════════════════════════════════════════════════════════════════╣"
$titre_bod = "║ Collecte fait le $date                                          ║"
$titre_end = "╚═══════════════════════════════════════════════════════════════════════════════╝"
$adresse
$computerInfo
$systemInfo
$disque

###################################################################################################################
# Zone de tests comme les paramètres renseignés ou les droits administrateurs

# Affiche l'aide si un ou plusieurs paramètres ne sont par renseignés, "safe guard clauses" permet d'optimiser l'exécution et la lecture des scripts
<# if(!$Param1 -or !$Param2 -or !$Param3)
{
    Get-Help $MyInvocation.Mycommand.Path
	exit
} #>
###################################################################################################################
# Corps du script

# Initialisation de variables
$adresse = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet
$computerInfo = Get-ComputerInfo
$systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem
$disque = Get-Volume | Format-List Driveletter, FriendlyName, SizeRemaining, Size


# Affichage de l'en-tête dans le fichier log & le terminal

# Dans le fichier
$titre_top | Out-File -Force -FilePath .\log\sysloginfo.log -Encoding utf8 -Append
$titre_hea | Out-File -Force -FilePath .\log\sysloginfo.log -Encoding utf8 -Append
$titre_mid | Out-File -Force -FilePath .\log\sysloginfo.log -Encoding utf8 -Append
$titre_bod | Out-File -Force -FilePath .\log\sysloginfo.log -Encoding utf8 -Append
$titre_end | Out-File -Force -FilePath .\log\sysloginfo.log -Encoding utf8 -Append
""         | Out-File -Force -FilePath .\log\sysloginfo.log -Encoding utf8 -Append

# Dans le terminal
Write-Host $titre_top
Write-Host $titre_hea
Write-Host $titre_mid
Write-Host $titre_bod
Write-Host $titre_end
Write-Host ""


# Affichage des information sur l'OS dans le fichier log & le terminal

# Dans le fichier
#...

# Dans le terminal
Write-Host "┌ OPERATING SYSTEM"
Write-Host "| Hostname:`t" $systemInfo.Name
Write-Host "| IP:`t`t" $adresse.IPAddress
Write-Host "| OS:`t`t" $computerInfo.OsName
Write-Host "└ Version:`t" $computerInfo.OsVersion
Write-Host ""

<#
# Afficher l'utilisation de l'espace disque
Write-Output $disque

#>
