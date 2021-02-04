
/*
 *** gameLauncher2.ahk ************************************
 *** version 2.1
 
 Functions: 
	1. Prompt user asking what they'd like to launch
	2. Options of Steam Big Picture or RetroArch
	3. If RetroArch, first kill Steam (there is interference with the Xbox button)
	4. With either selection, will first set audio to TV, then start selected game environment
 
 Dependencies: 
	- C:\Program Files (x86)\Steam\Steam.exe
	- F:\Emulation\RetroArch\retroarch.exe
	- F:\Emulation\RetroArch\launchSound.mp3
	- F:\Emulation\RetroArch\exitSound.mp3
	- F:\Emulation\RetroArch\promptSound.mp3

 Relevant links:
	- https://developer.valvesoftware.com/wiki/Steam_browser_protocol
 
 To do (upstream changelog):
	future:
		- break out greetings into separate file
		- greetings can be divided into discrete arrays based on conditionality: time of day, nice, mean, etc., to make for a more custom and thoughtful interaction
		- extensibility: option (for possible future config file): turn on and off launch/exit sounds
		- extensibility: option (for possible future config file OR checkboxes in GUI): launching for TV or launch for PC play. Will toggle accordingly (RA will launch 
		- make script portable
			- define dependencies location (but fall back to default)
			- combine into .ZIP with structured dependencies
 
 Changelog:
	02/08/18:
		- bug fix: gui does not close when launching RA or SBPM
			- remediation: pass name of GUI when using all buttons
		- bug fix: audio switches to PC prematurely when RA launches a core
			- remediation: RA will close briefly when launching a core. determine how long this lasts, when script detects closeout, add a timeout to check if it's back again, if it is, resume script as normal, if not, then continue on to exitRoutineScript
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
*/

; #include %A_ScriptDir%\functions.ahk


arrayGreeting := ["Hello. What would you like to do?"
	, "Greetings. Please select an option."
	, "Howdy. What can I do for ya?"]

arrayExitButtonText := ["See ya!"
	, "Goodbye!"
	, "Later!"]
	
arraySamsonResponse := ["Change your mind?"
	, "Gotcha."
	, "Alrighty then."]

;arrayExitSound := ["soLongBowser.mp3"
;	, "bowserRoar.mp3"]


/*
	no selection timeout Samson quotes:
	"Cold feet?"
*/


; *** VARIABLE DECLARATIONS ***
pathDependencies	= F:\Emulation\RetroArch\

cliSteamBPM			= C:\Program Files (x86)\Steam\Steam.exe -start steam://open/bigpicture
cliRetroArch		= F:\Emulation\RetroArch\retroarch.exe

soundLaunch			= F:\Emulation\RetroArch\launchSound.mp3
soundExit			= F:\Emulation\RetroArch\exitSound.mp3
audioBowser			= F:\Emulation\RetroArch\soLongBowser.mp3
audioPromptSound	= F:\Emulation\RetroArch\promptSound.mp3
audioOutputTest		= F:\Emulation\RetroArch\audioOutputTest.mp3

nameGUI				= gameLauncher	; name of the GUI launcher to handle referencing it with 'Gui' command
									; 	note that exitRoutineGUI() uses guiName as a param to pass the name of the GUI
/* Variable naming conventions:
	Format used: typeSubtypeElement
	- types in this script: path_, cli_, sound_, audio_ (to be combined with sound_), name_, gui_, rand_)
	- subtypes: say you have 2 path variables, one path 
	
	nameGUI vs guiName
	- nameGUI: the type of variable is a NAME, and it's the NAME of WHAT, the Subtype is skipped here because there is none, so we are naming the GUI
*/

global cliSteamBPM
global cliRetroArch
global soundLaunch
global soundExit

global arrayGreeting
global arrayExitButtonText
global arraySamsonResponse

global dialogueGreeting
global dialogueExitButton
global dialogueSamsonResponse

global randGreeting
global randSamsonResponse

global audioBowser
global audioPromptSound
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
	
	SoundPlay, %audioOutputTest%
}


/*
isSteamRunning()
{
	** in development **
		--> see isSteamRunning.ahk
}
*/


launchRetroArch()									; Launch RetroArch, call audio functions
{
	; Window class: ahk_class RetroArch
	; Process name: ahk_exe retroarch.exe

	Gui, %nameGUI%:Destroy
	;isSteamRunning()
	
	audioToggleTV()

	Run, %cliRetroArch%
	WinWait, ahk_class RetroArch
	SoundPlay, %soundLaunch%
	
	WaitForRAClose:									; "Label" for "Goto" to jump to when it sees that RA is still loaded
	WinWaitClose, ahk_class RetroArch				
	{	
		Sleep, 5000									; Wait 5 seconds before checking if RA is still there
		
		IfWinNotExist, ahk_class RetroArch			; checks to see that RA intentionally closed or if it was just loading a core
		{
			exitRoutineScript()	
			return
		}
		else
		{
			Goto, WaitForRAClose
		}
	}
}


launchBPM()											; Launch Big Picture Mode and call audio functions
{
	Gui, %nameGUI%:Destroy
	
	audioToggleTV()
	Run, %cliSteamBPM%
	WinWait, ahk_class CUIEngineWin32				; Waits until BPM window is gone before changing 
	WinWaitClose 									; audio back to PC
		audioTogglePC()
}


sillyDialogue()
{
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


exitRoutineScript()									; handles "housekeeping" of closing out the script
{
	SoundPlay										; play the exit sound before toggling audio
		, %soundExit%
		, wait
	audioTogglePC()									; audio back to PC
}

exitRoutineGUI(guiName)
{
	Random
		, randExitSound
		, % arrayExitSound.MinIndex()
		, % arrayExitSound.MaxIndex()
		, NewSeed

	;MsgBox, randGreeting is %randGreeting%			; displays what index the random number landed on

	if (randGreeting = arrayGreeting.MinIndex())	; if Samson is being nice (the first item in the array)
	{												; then change the dialogueSamsonResponse
		dialogueSamsonResponse = That's on you!
	}
	
	;MsgBox, randSamsonResponse is %randSamsonResponse%   ; displays what index the random number landed on
	MsgBox, , Samson says..., %dialogueSamsonResponse%, 5
	
	SoundPlay, %audioBowser%
	
	Gui, %nameGUI%:Destroy 							; use guiName var passed from keypress to exitRoutineGUI so it can close GUI
	return
}


createGUI()
{
	txtTitle	= Game Launcher 2.1
	txtHello	= Samson here...
	txtBtnRA	= Launch &RetroArch
	txtBtnBPM	= Launch &Steam Big Picture Mode
	
	
	Gui, Destroy									; destroys old GUI if there is one
	Gui, %nameGUI%:New								; initialize a new GUI window where name is defined in var nameGUI
	Gui -MinimizeBox 								; +AlwaysOnTop +ToolWindow --> these are basic options for the GUI
	
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
	
	SoundPlay, %audioPromptSound%
	Gui, Show, , %txtTitle%
	return
}


launcherDialog()
{
	sillyDialogue()
	
	createGUI()
	return

	ButtonExit:
		exitRoutineGUI(nameGUI)						; pass pre-defined nameGUI to function exitRoutineGUI var guiName
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
	q::exitRoutineGUI(nameGUI)
#IfWinActive






/* Removed for debugging
joy5 & joy6::   ; Press LButton and then RButton on XBox controller
	audioToggleTV()
	launchBPM()
return
*/


/*
	- Regular steam:
		Window Title: Steam
		Class: ahk_class USurface_439389424
		Process: ahk_exe Steam.exe
	- Big Picture Mode:
		Window Title: Steam
		Class: CUIEngineWin32
		Process: Steam.exe
		active window position:
		x: 0
		y: 0
		w: 1920   h: 1080
- if display output is changed
	- Main display: 2. SyncMaster 2343(BWPlus/BWXPlus) (Digital)
	- Secondary Display: 1. LG TV
*/