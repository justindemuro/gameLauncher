
/*
 *** gameLauncher2.ahk ************************************
 *** version 2.2.1
 
 Functions: 
	1. Prompt user asking what they'd like to launch
	2. Options of Steam Big Picture or RetroArch
	3. If RetroArch, first kill Steam (there is interference with the Xbox button)
	4. With either selection, will first set audio to TV, then start selected game environment
 
 Dependencies: 
	- C:\Program Files (x86)\Steam\Steam.exe
	- C:\Applications\AutoHotKey\gameLauncher\
	- C:\Applications\AutoHotKey\! sharedAssets\
	- F:\Emulation\RetroArch\retroarch.exe

 Relevant links:
	- https://developer.valvesoftware.com/wiki/Steam_browser_protocol
 
 Upstream:
	- greetings can be divided into discrete arrays based on conditionality: time of day, nice, mean, etc., to make for a more custom and thoughtful interaction
	- extensibility: option (for possible future config file): turn on and off launch/exit sounds
	- extensibility: option (for possible future config file OR checkboxes in GUI): launching for TV or launch for PC play. Will toggle accordingly
	- make script portable
		- define dependencies location (but fall back to default)
		- combine into .ZIP with structured dependencies
 
 Changelog:
	02/12/18:
		- only cleaned up tabs and comments
	02/08/18:
		- graduated script to version 2.2.1
		- added in check to see if steam running, if it is, closes it
		- added in controller launch functionality
		- updated directory structure for future portability
		- broke out dialogue arrays to arraysDialogue file and included file from assets
		- cleaned up naming conventions for vars and soundfiles
		- exitRoutineScript() deprecated AND removed. Didn't see a need for it
		- bug fix: gui does not close when launching RA or SBPM
			- remediation: include nameGUI when running Gui, Destroy
		- bug fix: audio switches to PC prematurely when RA launches a core
			- remediation: RA will close briefly when launching a core. wait 5 seconds, when script detects closeout, add a timeout to check if it's back again, if it is, resume script as normal, if not, then continue on to exitRoutineScript
	02/03/18:
		- ported over new gameLauncher code
			- added sound effects for launching and closing GL
			- added "Samson" personality
			- included hotkeys R, S, and Q
		- changed version to 2.1
	02/02/18:
		- added launch sound and exit sound to RetroArch launcher
		- tested functionality of audio switching
	01/28/18:
		- major updates to code efficiency

 **********************************************************
*/


/**** VARIABLE DECLARATIONS ***
 Format: typeSubtypeElement
	- types:	path_, cli_, sound_, name_, gui_, rand_)
	- subtypes: description needed.
	- element:	the specific element the variable is working with
*/

pathDependencies	= %A_ScriptDir%\..				; not in use currently. for future portability?

cliSteamBPM			= C:\Program Files (x86)\Steam\Steam.exe -start steam://open/bigpicture
cliRetroArch		= F:\Emulation\RetroArch\retroarch.exe

soundLaunchRA		= %A_ScriptDir%\..\audio\soundCapcomIntro.mp3		; A_ScriptDir is where the script sits
soundCloseRA		= %A_ScriptDir%\..\audio\soundMegamanDeath.mp3
soundLaunchGUI		= %A_ScriptDir%\..\audio\soundChargeBuster.mp3
soundCloseGUI		= %A_ScriptDir%\..\audio\soundBowser.mp3

audioOutputTest		= %A_ScriptDir%\..\..\_sharedAssets\audio\soundOutputTest.mp3

nameGUI				= gameLauncher					; name of the GUI launcher to handle referencing it with 'Gui' command
													; 	note that exitRoutineGUI() uses guiName as a param to pass the name of the GUI
global cliSteamBPM
global cliRetroArch

global soundLaunchRA
global soundCloseRA
global soundLaunchGUI
global soundCloseGUI

global arrayGreeting
global arrayExitButtonText
global arraySamsonResponse

global dialogueGreeting
global dialogueExitButton
global dialogueSamsonResponse

global randGreeting
global randSamsonResponse

global audioOutputTest

global nameGUI


audioToggleTV()
{
	Run, mmsys.cpl
	WinWait, Sound
	ControlSend
		, SysListView321
		, {Down 3}
	;Send, ^{F12}									; uncomment this ONLY if audio does not successfully toggle
	ControlClick, &Set Default						; 	DEPENDENT on audioControls.ahk
	ControlClick, OK
}


audioTogglePC()
{
    Run, mmsys.cpl
    WinWait, Sound
    ControlSend
		, SysListView321
		, {Down 1}
	;Send, ^{F11}									; uncomment this ONLY if audio does not successfully toggle
    ControlClick, &Set Default						; 	DEPENDENT on audioControls.ahk
    ControlClick, OK
	
	SoundPlay, %audioOutputTest%					; plays sound to confirm audio successfully switched back to PC
}


isSteamRunning()
{
	DetectHiddenWindows, On
	
	IfWinExist, ahk_exe Steam.exe
	{
		Process, Close, Steam.exe
		return
	}
}


launchRetroArch()									; Launch RetroArch, kill Steam, call audio functions
{
	; Window class: ahk_class RetroArch
	; Process name: ahk_exe retroarch.exe

	Gui, %nameGUI%:Destroy							; remember to close out the GUI before continuing with launching RA
	
	isSteamRunning()
	
	audioToggleTV()

	Run, %cliRetroArch%
	WinWait, ahk_class RetroArch
	SoundPlay, %soundLaunchRA%
	
	WaitForRAClose:									; "Label" for "Goto" to jump to when it sees that RA is still loaded
	WinWaitClose, ahk_class RetroArch				; As soon as you see RA close, then wait 5 seconds
	{	
		; add some way to NOT sleep if a game has already been launched, or if a game has NEVER been launched
		; in both cases it's probably safe to assume that you don't need to wait at all.

		Sleep, 5000									; Wait 5 seconds before checking if RA is still there
		
		IfWinNotExist, ahk_class RetroArch			; checks to see that RA intentionally closed or if it was just loading a core
		{											; "if RA doesn't exist after 5 seconds then it's probably safe to run close routine"
			SoundPlay								; play the exit sound before toggling audio
				, %soundCloseRA%
				, wait
			audioTogglePC()							; audio back to PC
			return
		}
		else
		{
			Goto, WaitForRAClose					; nope, RA was just loading a core. Go back to waiting.
		}
	}
}


launchBPM()											; Launch Big Picture Mode and call audio functions
{
	Gui, %nameGUI%:Destroy							; remember to close out the GUI before continuing with launching SBPM
	
	audioToggleTV()
	Run, %cliSteamBPM%
	WinWait, ahk_class CUIEngineWin32				; Waits until BPM window is gone before changing 
	WinWaitClose									; audio back to PC
		audioTogglePC()
}


sillyDialogue()
{
	#Include %A_ScriptDir%\..\include\arraysDialogue
	
	Random											; generates a random number based on the array's max and min values
		, randGreeting
		, % arrayGreeting.MinIndex()
		, % arrayGreeting.MaxIndex()
		, NewSeed
	Random
		, randExitButton							; random number is generated for each dialogue type
		, % arrayExitButtonText.MinIndex()
		, % arrayExitButtonText.MaxIndex()
		, NewSeed
	Random
		, randSamsonResponse
		, % arraySamsonResponse.MinIndex()
		, % arraySamsonResponse.MaxIndex()
		, NewSeed

	dialogueGreeting 		:= arrayGreeting[randGreeting]				; pull the dialogue from array and assign to a var
	dialogueExitButton 		:= arrayExitButtonText[randExitButton]
	dialogueSamsonResponse	:= arraySamsonResponse[randSamsonResponse]
}


exitRoutineGUI()
{
	Random
		, randExitSound
		, % arrayExitSound.MinIndex()
		, % arrayExitSound.MaxIndex()
		, NewSeed

	; MsgBox, randGreeting is %randGreeting%

	if (randGreeting = arrayGreeting.MinIndex())	; if Samson is being nice (the first item in the array)
	{												; then change the dialogueSamsonResponse
		dialogueSamsonResponse = That's on you!
	}
	
	; MsgBox, randSamsonResponse is %randSamsonResponse%
	MsgBox, , Samson says..., %dialogueSamsonResponse%, 5
	
	SoundPlay, %soundCloseGUI%
	
	Gui, %nameGUI%:Destroy							; use guiName var passed from keypress to exitRoutineGUI so it can close GUI
	return
}


createGUI()
{
	txtTitle	= Game Launcher 2.2.1
	txtHello	= Samson here...
	txtBtnRA	= Launch &RetroArch
	txtBtnBPM	= Launch &Steam Big Picture Mode
	
	
	Gui, Destroy									; destroys old GUI if there is one
	Gui, %nameGUI%:New								; initialize a new GUI window where name is defined in var nameGUI
	Gui -MinimizeBox								; +AlwaysOnTop +ToolWindow --> these are basic options for the GUI
	
	Gui, font, s17 bold italic, Calibri
	Gui, Color, D6E5F2
	Gui, Add, Text, , %txtHello%
	
	Gui, Font, s12 norm, ,
	Gui, Add, Text, x20 y45, %dialogueGreeting%

	Gui, Font, s11 bold, ,							; create buttons for RA, BPM, and Exit
	Gui
		, Add
		, Button
		, gButtonLaunchRA  w100 h100 x15 y80
		, %txtBtnRA%
	
	Gui
		, Add
		, Button
		, gButtonLaunchBPM w100 h100 x130 y80
		, %txtBtnBPM%
	
	Gui, Font, norm s9								; "close" text above exit button
	Gui, Add, Text, x250 y110, Close (Q):
	
	Gui, Font, italic s11							; exit button
	Gui, Color, , ControlColor, FF0000
	Gui
		, Add
		, Button
		, gButtonExit w100 h50 x250 y130 Default
		, %dialogueExitButton%
	
	SoundPlay, %soundLaunchGUI%
	Gui, Show, , %txtTitle%
	return
}


launcherDialog()
{
	sillyDialogue()
	
	createGUI()
	return

	ButtonExit:
		exitRoutineGUI()
	return
	
	ButtonLaunchRA:
		launchRetroArch()
	return
	
	ButtonLaunchBPM:
		launchBPM()
	return
}


F4::
	launcherDialog()
return

#IfWinActive ahk_class AutoHotkeyGUI				; enable hotkeys S and R to launch respective items
	r::launchRetroArch()
	s::launchBPM()
	q::exitRoutineGUI()
#IfWinActive

/* REMOVED FOR DEBUGGING
#If !WinExist("ahk_class RetroArch") && !WinExist("ahk_class CUIEngineWin32")
	joy5 & joy7::									; hold down LB and Back
		launchRetroArch()
	return
#If

#If !WinExist("ahk_class RetroArch") && !WinExist("ahk_class CUIEngineWin32")
	joy5 & joy8::									; hold down LB and Start
		launchBPM()
	return
#If
*/





/* *** Reference ***
	
	- RetroArch
		Window class: ahk_class RetroArch
		Process name: ahk_exe retroarch.exe
	- Regular steam:
		Window Title: Steam
		Class: ahk_class USurface_439389424
		Process: ahk_exe Steam.exe
	- Big Picture Mode:
		Window Title: Steam
		Class: ahk_class CUIEngineWin32
		Process: Steam.exe
		active window position:
		x: 0
		y: 0
		w: 1920   h: 1080
- if display output is changed
	- Main display: 2. SyncMaster 2343(BWPlus/BWXPlus) (Digital)
	- Secondary Display: 1. LG TV
*/