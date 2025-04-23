;Creator:  Felk / Klef
;Purpose: Draw Rectangles on the screen that can be clicked through

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force

Coordmode Mouse, Screen

;global variables
;static variables
global guiHeight = 400, guiWidth = 300
;variables
global ttlBoxCount = 0, errorString =, centeringValue, boxColor:="blue", boxTransparency:=80, transp, notTransp, boxRelativeValue := 0, ddlText, windowSelected, tooltipState, tooltipMessageNumber = 1, shape = rectangle, resizingMode, selectCoordMode = off, windowToEdit
;arrays
global ArrayX := Object(), ArrayY := Object(), ArrayWindow := Object(), ArrayBoxName := Object(), ArrayW := Object(), ArrayH := Object(), ArrayHWND := Object(), ArrayRel := Object(), ArrayColor := Object(), ArrayTransparency := Object()
;hwnd
global MyEditHwnd, MyEditHwnd2, MyEditHwnd3, movedeleteHWND, DrawHWND, MainHWND, ColorHWND, TransparencyHWND, RelativeHWND, Text1HWND, Text2HWND, Text3HWND, Text4HWND, SelectCoordinatesHWND 
;Saved values
global savedX, savedY, savedX2, savedY2, savedWindowToEdit
;Markers
global 1Active = false, 2Active = false, 3Active = false, 4Active = false

;this part is just for some fun (also consider shell32.dll and imageres.dll)  which can be found in C:\windows\system32\ along with moricons.dll
;Icon [, FileName, IconNumber, 1] found at: http://ahkscript.org/docs/commands/Menu.htm
Menu, Tray, Icon, moricons.dll, 65

createMarkerGuis()
createMainGui()

SetTimer, update, 10000, 1000
SetTimer, relocateWindows, 10, 1000 ;at a value of 10 it relocates seamlessly
setTimer, markPositions, 50, 1000
SetTimer, updateButtons, 200
SetTimer, crosshairs, 10, 1000
SetTimer, crosshairs, off, 1000
SetTimer, tooltipTimer, 200, 1000
SetTimer, tooltipTimer, off
SetTimer, editRectanglesThread, 50
SetTimer, editRectanglesThread, off

return

;====Subroutines===
markPositions:
{
	GuiControlGet, windowSelected, Main: , Edit5			;store selected window in windowSel (because it has trouble accessing windowSelected)
	GuiControlGet, firstX, Main: , Edit1
	GuiControlGet, firstY, Main: , Edit2
	GuiControlGet, ndX, Main: , Edit3
	GuiControlGet, ndY, Main: , Edit4
	GuiControlGet, boxColor, Main: , ComboBox1
	GuiControlGet, boxTransparency, Main: , msctls_trackbar321
	
	DrawX = false
	DrawY = false
	DrawX2 = false
	DrawY2 = false
	colorChanged = false
	transparencyChanged = false
	DrawMarker5 = false
	ResizeMarker5 = false
		
	;relative mode is enabled
	ifEqual, boxRelativeValue, 1
		ifEqual, windowSelected, 
		{
			Gosub, removeMarkers
			return
		}
		else ifWinNotExist, %windowSelected%
		{
			Gosub, removeMarkers
			return
		}
	
	if resizingMode = on
	{
		Gui, Marker5: +LastFound
		WinGetPos, firstX, firstY, marker5Width, marker5Height
		
		ndX := firstX + marker5Width
		ndY := firstY + marker5Height
		
		ifEqual, boxRelativeValue, 1
		{
			firstX -= windowX
			firstY -= windowY
			ndX -= windowX
			ndY -= windowY
		}
		
		Gui, Main: +LastFound
		ControlSetText, edit1, %firstX%
		ControlSetText, edit2, %firstY%
		ControlSetText, edit3, %ndX%
		ControlSetText, edit4, %ndY%
		
		ifEqual, boxRelativeValue, 1
		{
			firstX += windowX
			firstY += windowY
			ndX += windowX
			ndY += windowY
		}
		
		DrawX(firstX)
		DrawY(firstY)
		DrawX2(ndX)
		DrawY2(ndY)
		
		;width = largest x minus smallest x and location of starting x is smallest x
		ifGreater, firstX, %ndX%
		{
			width := firstX - ndX
			locX := ndX
		}
		else
		{
			width := ndX - firstX
			locX := firstX
		}
		;height = largest y minus smallest y	and location of starting y is smallest y
		ifGreater, firstY, %ndY%
		{
			height := firstY - ndY
			locY := ndY
		}
		else
		{
			height := ndY - firstY
			locY := firstY
		}
		
		if shape = ellipse
			WinSet, Region, 0-0 W%width% H%height% E, marker5
		else if shape = rectangle
			WinSet, Region, 0-0 W%width% H%height%, marker5
		return
	} ;end of if resizingMode = on
	
	if firstX is number
		DrawX = true
	if firstY is number
		DrawY = true
	if ndX is number
		DrawX2 = true
	if ndY is number
		DrawY2 = true
	
	ifEqual, boxRelativeValue, 1
	{
		WinGetPos, windowX, windowY,,, % windowSelected
		
		if DrawX = true
			firstX += windowX
		if DrawY = true
			firstY += windowY
		if DrawX2 = true
			ndX += windowX
		if DrawY2 = true
			ndY += windowY
	}
	
	if DrawX = true
		DrawX(firstX)
	else
		if 1Active = true
			removeMarker(1)
	if DrawY = true
		DrawY(firstY)
	else
		if 2Active = true
			removeMarker(2)	
	if DrawX2 = true
		DrawX2(ndX)
	else
		if 3Active = true
			removeMarker(3)
	if DrawY2 = true
		DrawY2(ndY)
	else
		if 3Active = true
			removeMarker(3)	
	
	;width = largest x minus smallest x and location of starting x is smallest x
	ifGreater, firstX, %ndX%
	{
		width := firstX - ndX
		locX := ndX
	}
	else
	{
		width := ndX - firstX
		locX := firstX
	}
	;height = largest y minus smallest y	and location of starting y is smallest y
	ifGreater, firstY, %ndY%
	{
		height := firstY - ndY
		locY := ndY
	}
	else
	{
		height := ndY - firstY
		locY := firstY
	}

	if 1Active = true
		if 2Active = true 
			if 3Active = true
				if 4Active = true
				{
					DrawMarker5( locX,locY,width,height )
					
					if shape = ellipse
						WinSet, Region, 0-0 W%width% H%height% E, marker5
					else if shape = rectangle
						WinSet, Region, 0-0 W%width% H%height%, marker5
				}
				else
					Gui, marker5: Cancel
			else
				Gui, marker5: Cancel
		else	
			Gui, marker5: Cancel
	else
		Gui, marker5: Cancel	
} ;End of markPositions
return

Draw:
{
	SetTimer, relocateWindows, off
	SetTimer, update, off
	SetTimer, markPositions, off	
	SetTimer, updateButtons, off
	SetTimer, tooltipTimer, off
	selectCoordMode = off
	tooltip
	GuiControlGet, windowSelected, Main: , Edit5			;store selected window in windowSel (because for some reason it has trouble accessing windowSelected)
	GuiControlGet, firstX, Main: , Edit1
	GuiControlGet, firstY, Main: , Edit2
	GuiControlGet, ndX, Main: , Edit3
	GuiControlGet, ndY, Main: , Edit4
	GuiControlGet, boxColor, Main: , ComboBox1
	GuiControlGet, boxTransparency, Main: , msctls_trackbar321
	
	;make sure text from textboxes is numbers and positive
	if !isNum(firstX)
		handleError("First x is not a number")
	else if firstX < 0
		handleError("First x must be positive")
	
	if !isNum(firstY)
		handleError("First y is not a number")
	else if firstY < 0
		handleError("First y must be positive")
	
	if !isNum(ndX)
		handleError("Second x is not a number")
	else if ndX < 0
		handleError("Second x must be positive")
	
	if !isNum(ndY)
		handleError("Second y is not a number")
	else if ndY < 0
		handleError("Second y must be positive")
	
	;notes: boxRelativeValue 0 if unchecked and 1 if checked. If box is checked then verify text of ComboBox
	if boxRelativeValue = 1 
		ifEqual windowSelected, 				;check that ComboBox to isn't empty
			handleError("Must Select a Window")
	
	ifNotEqual errorString, 						;check if there is an error
		msgbox, %errorString%
	else										;if there are no errors
	{
		;make sure first x is bigger than second x
		IfEqual, firstX, %ndX%
			handleError( "First X and Second X cannot be equal" )

		;make sure first y is bigger than second y
		IfEqual, firstY, %ndY%
			handleError( "First XYand Second Y cannot be equal" )
		
		;notes: boxRelativeValue 0 if unchecked and 1 if checked
		if boxRelativeValue = 1 
			IfWinNotExist, %windowSelected%			;verify that a window matching that name exists
				handleError("Window Not Fount")
		
		;check if there is an error
		ifNotEqual errorString, 
			msgbox, %errorString%
		else 
		{										;if no errors
			;width = largest x minus smallest x and location of starting x is smallest x
			ifGreater, firstX, %ndX%
			{
				width := firstX - ndX
				locX := ndX
			}
			else
			{
				width := ndX - firstX
				locX := firstX
			}
				
			;height = largest y minus smallest y	and location of starting y is smallest y
			ifGreater, firstY, %ndY%
			{
				height := firstY - ndY
				locY := ndY
			}
			else
			{
				height := ndY - firstY
				locY := firstY
			}

			++ttlBoxCount							;increases the count of the number of boxes by 1

			boxName = Box%ttlBoxCount%			;gives unique name to the box
			
			Gui, new,,%boxName%					;creates the box
			
			Gui, %boxName%: +LastFound
			Gui, %boxName%: -border -caption +alwaysontop +disabled +owner -sysmenu
			Gui, %boxName%: color, %boxColor%
			
			;0 being fully transparent and 254 being not transparent
			WinSet, Transparent, %boxTransparency%
			;changing this line messes things up
			WinSet, ExStyle, +0x20
			;set title to blank text so it doesn't appear in dropdownlist
			WinSetTitle, 
			;Get HWND of %boxName% and save it in title
			WinGet, title
			
			;if box is relative add the coordinates of the box to be relative to to the relative coordinates
			if boxRelativeValue = 1 
			{
				WinGetPos,x,y,,, %windowSelected%
				
				locX += x
				locY += y
			}
			
			Gui, %boxName%: show,NA x%locX% y%locY% w%width% h%height%, %boxName%
			Gui, Main: +LastFound
			
			if shape = ellipse
				WinSet, Region, 0-0 W%width% H%height% E, %boxName%
			else if shape = rectangle 	
				WinSet, Region, 0-0 W%width% H%height%, %boxName%
			else
				shape = rectangle			;make sure it's not some other value
				
			if boxRelativeValue = 1 
			{
				locX -= x
				locY -= y
			}
			
			ArrayX.insert(locX)
			ArrayY.insert(locY)
			ArrayW.insert(width)
			ArrayH.insert(height)
			ArrayWindow.insert(windowSelected)
			ArrayBoxName.insert(boxName)
			ArrayHWND.insert(title)
			ArrayRel.insert(boxRelativeValue)
			ArrayColor.insert(boxColor)
			ArrayTransparency.insert(boxTransparency)
			
			windowSelected = 
			savedX =
			savedY =
			savedX2 =
			savedY2 =
			Gosub, resetTextboxes 
		} ;End of else for if statement ifNotEqual errorString, 
	} ;End of ifNotEqual
	
	errorString := 
	
	Gosub, removeMarkers
	
	SetTimer, relocateWindows, on
	SetTimer, update, on
	SetTimer, markPositions, on	
	SetTimer, updateButtons, on
} ;End of DrawRectangle
return

SelectCoordinates: 
{
	SetTimer, crosshairs, on
	SetTimer, tooltipTimer, on
	SetTimer, update, off
	tooltipMessageNumber = 1
	tooltipState = on
	Gui, Main: +LastFound +disabled
	WinSet, Transparent, 100
	
	;notes: boxRelativeValue 0 if unchecked and 1 if checked
	if boxRelativeValue = 1 
		coordmode, mouse, window
	else
		coordmode, mouse, screen
	
	Sleep 300
	
	;gets x and y of first click
	KeyWait, LButton, D
	{
		;notes: boxRelativeValue 0 if unchecked and 1 if checked
		if boxRelativeValue = 1 
		{
			MouseGetPos, firstClickX, firstClickY, winID
			WinGetTitle, windowSelected, ahk_id %winID%
			
			ControlSetText, edit5, %windowSelected%
		}
		else
		{
			MouseGetPos, firstClickX, firstClickY
		}
		
		ControlSetText, edit1, %firstClickX%
		ControlSetText, edit2, %firstClickY%
	}

	Sleep 300

	;gets x and y of second click
	KeyWait, LButton, D
	{
		MouseGetPos, ndClickX, ndClickY
		
		ControlSetText, edit3, %ndClickX%
		ControlSetText, edit4, %ndClickY%
	}
	Gui, Main: +LastFound -disabled
	WinSet, Transparent, off
	SetTimer, crosshairs, off
	Gui, crosshair1: Cancel
	Gui, crosshair2: Cancel
	tooltipMessageNumber = 2
	selectCoordMode = on
	SetTimer, update, on
} ;End of selectCoordinates
return

selectColor:
{
	Gui, Main: Submit, NoHide
} ;End of selectCoordinates
return

selectTransparency:
{
	Gui, Main: Submit, NoHide
} ;End of selectTransparency
return

boxRelative:
{
	Gui, Main: Submit, NoHide
	SetTimer, tooltipTimer, off
	tooltip
	
	IfEqual, boxRelativeValue, 0
	{
		GuiControl, hide, %MyEditHwnd%
		GuiControl, hide, %MyEditHwnd2%
	}
	else
	{
		GuiControl, show, %MyEditHwnd%
		GuiControl, show, %MyEditHwnd2%
	}
	
	Gosub, resetTextboxes
	Gosub, removeMarkers
} ;End of boxRelative
return

getddlText:
{
	WinGet, myArray, list,,,Program Manager 			;gets names of all windows except program manager
	loop %myArray%
	{
		this_id := myArray%A_Index%
		WinGetTitle, this_title, ahk_id %this_id%
		addTitle = false
		
		;checks if window name is not an empty string
		ifNotEqual this_title, 
		{	
			addTitle = true
			
			;do not add any of the windows created to mark the screen
			loop % ArrayBoxName.MaxIndex()
				ifEqual, this_title, % ArrayBoxName[A_Index]
				{
					addTitle = false
					break
				}
		}
		
		ifEqual, addTitle, true
		{
			;adds window name to list to be displayed in dropdownlist
			ifEqual ddlText, 
				ddlText .= this_title
			else
				ddlText .= "|" this_title
		}
	}
} ;End of getddlText
return

selectWindow:
{
	Gui, Main: Submit, NoHide
}
return

update:
{
	Gui, Main: Submit, NoHide
	
	ddlText := 					;clears ddlText
	Gosub, getddlText			;fills ddlText with all open windows	
	
	;updates the dropdownlist with the new contents of ddlText
	GuiControl,, %MyEditHwnd%, |%windowSelected%||%ddlText%
}
return

relocateWindows:
{
	loop % ArrayX.MaxIndex()
	{
		rel := % ArrayRel[A_Index]
		
		ifEqual, rel, 1				;check if relative
		{
			windowName := % ArrayWindow[A_Index]
			
			;check that the window to be relative to exists
			ifWinExist, %windowName%
			{	
				WinGetPos,x,y,,, %windowName%
					
				numb = % ArrayX[A_Index]
				x := x + numb
				
				numb = % ArrayY[A_Index]
				y := y + numb
				
				w = % ArrayW[A_Index]
				h = % ArrayH[A_Index]
				
				boxName := % ArrayBoxName[A_Index]
				
				Gui, %boxName%: show,NA x%x% y%y% w%w% h%h%
			}
		}
	} ;end of loop, %relBoxCount%
} ;End of relocateWindows
return

editRectangles:
{
	SetTimer, relocateWindows, off
	SetTimer, update, off
	SetTimer, markPositions, off
	SetTimer, updateButtons, off
	SetTimer, tooltipTimer, on
	
	tooltipMessageNumber = 3
	tooltipState = on
	
	GuiControl, disable, %DrawHWND%
	GuiControl, disable, %movedeleteHWND%
	GuiControl, disable, %RelativeHWND%
	
	GuiControlGet, OutputVar,, Button4
	
	If OutputVar = Edit
	{
		GuiControl, Text, Button4, Stop			;Set the text to stop
		SetTimer, editRectanglesThread, on
		
		if ArrayX.MaxIndex() = 0
			msgbox, no rectangles found
		else if ArrayX.MaxIndex() < 0
			msgbox, how did this happen? 
		else
			loop % ArrayX.MaxIndex()
			{
				boxName := % ArrayBoxName[A_Index]
				
				Gui, %boxName%: +LastFound
				Gui, %boxName%: -disabled +sysmenu +resize -minimizebox -maximizebox
				WinSet, ExStyle, -0x20
			}
	}
	Else		;Stop EditingRectangles
	{ 
		GuiControl, Text, Button4, Edit				
		SetTimer, editRectanglesThread, off
		
		;reset windows
		loop % ArrayX.MaxIndex()
		{
			boxName := % ArrayBoxName[A_Index]
			boxHwnd := % ArrayHWND[A_Index]
			
			Gui, %boxName%: +LastFound
			Gui, %boxName%: -disabled -sysmenu -resize
			WinSet, ExStyle, +0x20
			
			if boxName = % ArrayBoxName[A_Index]
			{
				;get new size of box
				WinGetPos, x, y, w, h, ahk_id %boxHwnd%
				WinGetPos, x2, y2,,, % ArrayWindow[A_Index]
				
				x := x - x2
				y := y - y2
				
				updateArrays( x, y, w, h, A_Index)
			}
		} ;End of outer loop
		GuiControl, enable, %movedeleteHWND%
		GuiControl, enable, %RelativeHWND%
		GuiControl, enable, %DrawHWND%
		
		windowToEdit := 
		
		SetTimer, relocateWindows, on
		SetTimer, update, on
		SetTimer, markPositions, on
		SetTimer, updateButtons, on
		SetTimer, tooltipTimer, off
		tooltip
	} ;End of else statement
} ;End of EditRectangles
return 

editRectanglesThread:
{
	ifNotEqual, windowToEdit,
	{
		GuiControlGet, boxColor, Main: , ComboBox1
		GuiControlGet, boxTransparency, Main: , msctls_trackbar321
		
		Gui, %windowToEdit%: +LastFound
		Gui, %windowToEdit%: color, %boxColor%
		WinSet, Transparent, %boxTransparency%
		
		loop % ArrayBoxName.MaxIndex()
			ifEqual, windowToEdit, % ArrayBoxName[A_Index]
			{
				WinGetPos, , , width, height, % ArrayBoxName[A_Index]
				
				if shape = ellipse
					WinSet, Region, 0-0 W%width% H%height% E, % ArrayBoxName[A_Index]
				else if shape = rectangle
					WinSet, Region, 0-0 W%width% H%height%, % ArrayBoxName[A_Index]
					
				updateArrays2( boxColor, boxTransparency, A_Index )	
				
				break
			}
	}
}
return

move/deleteRectangles:
{	
	SetTimer, relocateWindows, off
	SetTimer, update, off
	SetTimer, markPositions, off
	SetTimer, updateButtons, off
	
	GuiControl, disable, %MyEditHwnd3%
	GuiControl, disable, %RelativeHWND%
	GuiControl, disable, %DrawHWND%
	
	GuiControlGet, OutputVar,, Button5
	If OutputVar = Move/Delete
	{
		GuiControl, Text, Button5, Stop
		
		if ArrayX.MaxIndex() = 0
			msgbox, no rectangles found
		else if ArrayX.MaxIndex() < 0
			msgbox, how did this happen? `n There is less than 0 boxes
		else
		{
			GuiControl, disable, %DrawHWND%
			GuiControl, disable, %MyEditHwnd3%			
		
			loop %ttlBoxCount%
			{
				boxName = Box%A_Index%
				
				Gui, %boxName%: +LastFound
				Gui, %boxName%: -disabled +caption +sysmenu -minimizebox -maximizebox
				
				WinSet, ExStyle, -0x20
			}
		}
	}
	Else
	{ ;Stop Moving/Deleting Rectangles
		GuiControl, Text, Button5, Move/Delete				;reset text in button
		
		;reset windows
		loop % ArrayX.MaxIndex()
		{
			boxName = Box%A_Index%
			boxHwnd := % ArrayHWND[A_Index]
			
			Gui, %boxName%: +LastFound
			Gui, %boxName%: -disabled -sysmenu -caption
			
			WinSet, ExStyle, +0x20
			
			;check if the box still exists
			ifWinExist, ahk_id %boxHwnd%
			{
				;get new size of box
				WinGetPos, x, y, w, h, ahk_id %boxHwnd%
				WinGetPos, x2, y2,,, % ArrayWindow[A_Index]
				
				x := x - x2
				y := y - y2
				
				updateArrays( x, y, w, h, A_Index)
			}
		} ;End of outer loop
		
		GuiControl, enable, %MyEditHwnd3%
		GuiControl, enable, %RelativeHWND%
		GuiControl, enable, %DrawHWND%
		
		SetTimer, relocateWindows, on
		SetTimer, update, on
		SetTimer, markPositions, on
		SetTimer, updateButtons, on
	} ;End of else statement
} ;End of move/deleteRectangles
return

updateButtons:
{
	invalid = true
	
	Gui, Main: +LastFound
	
	if ArrayX.MaxIndex() > 0
	{
		GuiControl, enable, %MyEditHwnd3%
		GuiControl, enable, %movedeleteHWND%
	}
	else ;there is more than 1 box
	{
		;make buttons not click-able if no boxes found
		GuiControl, disable, %MyEditHwnd3%
		GuiControl, disable, %movedeleteHWND%
	}
}
return

crosshairs:
{
	MouseGetPos, RulerX, RulerY, id
	WinGetTitle, title, ahk_id %id%
	
	ifEqual, title, Program Manager
		title =
	
	Gui, crosshair1: Default
	Gui, +LastFound
	Gui, color, %boxColor%
	WinSet, Transparent, %boxTransparency%
	Gui, show,NA H1 W%A_ScreenWidth% X0 Y%RulerY%
	
	Gui, crosshair2: Default
	Gui, +LastFound
	Gui, color, %boxColor%
	WinSet, Transparent, %boxTransparency%
	Gui, show,NA H%A_ScreenHeight% W1 X%RulerX% Y0
}
return

tooltipTimer:
{
	if tooltipState <> off
	{
		if tooltipMessageNumber = 1
		{
			tooltip, 
			( LTrim 
			Press Pause Key to toggle tooltip
			
			Left Click once to Select First X and Y
			Left Click again to Select Second X and Y
			
			x%RulerX% y%RulerY%
			Window Title: %title%
			)
		}
		else if tooltipMessageNumber = 2
		{
			ToolTip, 
			( LTrim 
			Press Pause Key to toggle tooltip
			
			Press ctrl + e to change to an ellipse
			Press ctrl + r to change to a rectangle
			Press ctr + w to enter/exit resizing mode
			Press esc to cancel
			)
		}
		else if tooltipMessageNumber = 3
		{
			MouseGetPos, , , id
			WinGetTitle title, ahk_id %id%
			StringLeft title, title, 40     ; Keep 40 chars of title
			
			ToolTip, 
			( LTrim 
			Press Pause Key to toggle tooltip
			
			Left click a rectangle or ellipse to select it
			Shape to Edit: %windowToEdit%
			
			Press ctrl + e to change selected shape to an ellipse
			Press ctrl + r to change selected shape to a rectangle
			
			Window: %title%
			)
			
			KeyWait, LButton, D T0.1 	;a timeout will result in ErrorLevel = 1
			{
				if ErrorLevel = 0				;no error
				{
					;only allow a box drawn to be editted
					loop % ArrayBoxName.MaxIndex()
						ifEqual, title, % ArrayBoxName[A_Index]
						{
							SetTimer, editRectanglesThread, off
							
							windowToEdit := title
							;set the controls equal to the saved values of the window to edit
							GuiControl, Main: , msctls_trackbar321, % ArrayTransparency[A_Index]
							Control, ChooseString , % ArrayColor[A_Index], , ahk_id %ColorHWND%
							
							SetTimer, editRectanglesThread, on
							break
						}
				}	
			} ;End of KeyWait
		}
	} ;End of tooltipState <> off
	else
		ToolTip
}
return

removeMarkers:
{
	Gui, marker1: Cancel
	Gui, marker2: Cancel
	Gui, marker3: Cancel
	Gui, marker4: Cancel
	Gui, marker5: Cancel
	
	1Active = false
	2Active = false
	3Active = false
	4Active = false
}
return

resetTextboxes:
{	
	ControlSetText, edit1, 
	ControlSetText, edit2, 
	ControlSetText, edit3, 
	ControlSetText, edit4,
	ControlSetText, edit5,
}
return

;dont mess with MainGuiClose
MainGuiClose: 
{
	exitApp
} ;End of MainGuiClose
return

;===functions===
updateArrays( x, y, w, h, index )
{
	ArrayX[index] := x
	ArrayY[index] := y
	ArrayW[index] := w
	ArrayH[index] := h
}
return

updateArrays2(col, transp, index) 
{
	ArrayColor[index] := col
	ArrayTransparency[index] := Transp
}
return

removeArrayAtIndex( index )				;currently not used
{
	ArrayX.remove( index )
	ArrayY.remove( index )
	ArrayW.remove( index )
	ArrayH.remove( index )
	ArrayWindow.remove( index )
	ArrayBoxName.remove( index )
	ArrayHWND.remove( index )
	ArrayRel.remove( index )
}
return

IsNum( str ) 
{
	if str is number
		return true
	return false
} ;End of isNum( str )
return

handleError( str )
{
	errorString := errorString "`n" str 
} ;End of handleError(  str )
return

createMainGui()
{
	;some initial calculations
	buttonWidth = 100
	ddlWidth = 250
	centeringValue := (guiWidth - buttonWidth) / 2
	centeringValueDDL := (guiWidth - ddlWidth) / 2
	guiXLocation := A_ScreenWidth - guiWidth
	
	Gui, new,,Main
	Gui, Main: -resize +LastFound
	WinSetTitle, ScreenSections
	
	WinGet, mainHWND, ID
	
	;add controls to main gui
	Gui, Main: Add, Button, Section xm+10 w%buttonWidth% hwndSelectCoordinatesHWND gSelectCoordinates, Select Coordinates

	Gui, Main: Add, Text, Section x10, Top left corner X:
	Gui, Main: Add, Edit, hwndText1HWND
	Gui, Main: Add, Text, , Top left corner Y:
	Gui, Main: Add, Edit, hwndText2HWND
	
	Gui, Main: Add, Checkbox, xm+150 ym+5 Section hwndRelativeHWND vboxRelativeValue gboxRelative, Relative Positioning
	Gui, Main: Add, Text, y+11, Bottom right corner X:
	Gui, Main: Add, Edit, vndX hwndText3HWND
	Gui, Main: Add, Text,, Bottom right corner Y:
	Gui, Main: Add, Edit, vndY hwndText4HWND Section,

	Gui, Main: Add, Button, Section w%buttonWidth% x%centeringValue% y+30 gDraw hwndDrawHWND,Draw
	
	Gui, Main: Add, Text, Section xs+5 ys+45, Additional Options
	
	Gui, Main: Add, DropDownList, Section vboxColor gselectColor hwndColorHWND w%buttonWidth% x%centeringValue%, black|green|silver|lime|grey|olive|white|yellow|maroon|navy|red|blue||purple|teal|fuchsia|aqua

	Gui, Main: Add, Text, Section xm ym vtransp, More Transparent
	Gui, Main: Add, Text, vnotTransp, Less Transparent
	Gui, Main: Add, Slider, Tooltip w%buttonWidth% x%centeringValue% Range0-254 gselectTransparency vboxTransparency hwndTransparencyHWND Buddy1transp Buddy2notTransp, 80
	
	Gosub, getddlText		;place text to be displayed in dropdownlist in ddlText
	
	Gui, Main: Add, Text, HwndMyEditHwnd2 xs+15, Select Window
	Gui, Main: Add, ComboBox, vwindowSelected gselectWindow x%centeringValueDDL% w%ddlWidth% HwndMyEditHwnd, %ddlText%
	
	Gui, Main: Add, Button, Section w%buttonWidth% geditRectangles HwndMyEditHwnd3, Edit
	
	Gui, Main: Add, Button, w%buttonWidth% x170 ys gmove/deleteRectangles HwndmovedeleteHWND, Move/Delete
	
	GuiControl, hide, %MyEditHwnd%
	GuiControl, hide, %MyEditHwnd2%
	GuiControl, disable, %MyEditHwnd3%
	GuiControl, disable, %movedeleteHWND%
	
	Gui, Main: Show, w%guiWidth% h%guiHeight% x%guiXLocation% y0
} ;End of createMainGui()
return

createMarkerGuis()
{
	Gui, new,, marker1		
	Gui, marker1: +LastFound
	Gui, marker1: -border -caption +alwaysontop +disabled +owner -sysmenu
	WinSetTitle, 
	WinSet, ExStyle, +0x20
	
	Gui, new,, marker2		
	Gui, marker2: +LastFound
	Gui, marker2: -border -caption +alwaysontop +disabled +owner -sysmenu
	WinSetTitle, 
	WinSet, ExStyle, +0x20
	
	Gui, new,, marker3		
	Gui, marker3: +LastFound
	Gui, marker3: -border -caption +alwaysontop +disabled +owner -sysmenu
	WinSetTitle, 
	WinSet, ExStyle, +0x20
	
	Gui, new,, marker4		
	Gui, marker4: +LastFound
	Gui, marker4: -border -caption +alwaysontop +disabled +owner -sysmenu
	WinSetTitle, 
	WinSet, ExStyle, +0x20
	
	Gui, new,, marker5		
	Gui, marker5: +LastFound
	Gui, marker5: -border -caption +alwaysontop +disabled +owner -sysmenu
	WinSetTitle, 
	WinSet, ExStyle, +0x20
	WinGet, marker5HWND, ID
	
	Gui, new,, crosshair1		
	Gui, crosshair1: +LastFound
	Gui, crosshair1: -border -caption +alwaysontop +disabled +owner -sysmenu
	WinSetTitle, 
	WinSet, ExStyle, +0x20
	
	Gui, new,, crosshair2		
	Gui, crosshair2: +LastFound
	Gui, crosshair2: -border -caption +alwaysontop +disabled +owner -sysmenu
	WinSetTitle, 
	WinSet, ExStyle, +0x20
}
return 

DrawX(x)
{
	Gui, marker1: Default
	Gui, +LastFound
	Gui, color, %boxColor%
	WinSet, Transparent, %boxTransparency%
	Gui, show,NA H%A_ScreenHeight% W1 X%x% Y0
			
	1Active = true
}
return

DrawY(y)
{
	Gui, marker2: Default
	Gui, +LastFound
	Gui, color, %boxColor%
	WinSet, Transparent, %boxTransparency%
	Gui, show,NA H1 W%A_ScreenWidth% X0 Y%y%
	
	2Active = true	
}
return

DrawX2(x2)
{
	Gui, marker3: Default
	Gui, +LastFound
	Gui, color, %boxColor%
	WinSet, Transparent, %boxTransparency%
	Gui, show,NA H%A_ScreenHeight% W1 X%x2% Y0
	
	3Active = true
}
return

DrawY2(y2)
{
	Gui, marker4: Default
	Gui, +LastFound
	Gui, color, %boxColor%
	WinSet, Transparent, %boxTransparency%
	Gui, show,NA H1 W%A_ScreenWidth% X0 Y%y2%
	
	4Active = true
}
return

DrawMarker5( x,y,w,h )
{
	Gui, marker5: Default
	Gui, +LastFound
	Gui, color, %boxColor%
	WinSet, Transparent, %boxTransparency%
	Gui, show,NA H%h% W%w% X%x% Y%y%, marker5
}
return

removeMarker(numb)
{
	Gui, marker%numb%: Cancel
	%numb%Active = false
}
return

;===key remapping===
Pause::
	if tooltipState <> off	
		tooltipState = off
	else
		tooltipState = on
return

^r::shape = rectangle
return

^e::shape = ellipse
return

^w::
	if selectCoordMode = on		;only allow resizing mode while selectCoordMode is on
	{
		if resizingMode <> on
		{
			resizingMode = on
			
			Gui, marker5: +LastFound
			Gui, marker5: -disabled +sysmenu +resize -minimizebox -maximizebox
			WinSet, ExStyle, -0x20
			
			GuiControl, disable, %Text1HWND%
			GuiControl, disable, %Text2HWND%
			GuiControl, disable, %Text3HWND%
			GuiControl, disable, %Text4HWND%
			GuiControl, disable, %SelectCoordinatesHWND%
		}
		else
		{
			resizingMode = off
			
			Gui, marker5: +LastFound
			Gui, marker5: -disabled -sysmenu -resize
			WinSet, ExStyle, +0x20
			
			GuiControl, enable, %Text1HWND%
			GuiControl, enable, %Text2HWND%
			GuiControl, enable, %Text3HWND%
			GuiControl, enable, %Text4HWND%
			GuiControl, enable, %SelectCoordinatesHWND%
		}	
	}
	
return	

ESC::Esc ; Esc here so that esc key still performs esc function
	windowSelected = 
	savedX =
	savedY =
	savedX2 =
	savedY2 =
	Gui, Main: +LastFound
	GuiControl, enable, %Text1HWND%
	GuiControl, enable, %Text2HWND%
	GuiControl, enable, %Text3HWND%
	GuiControl, enable, %Text4HWND%
	GuiControl, enable, %SelectCoordinatesHWND%
	
	selectCoordMode = off
	SetTimer, crosshairs, off
	SetTimer, tooltipTimer, off
	
	Gosub, resetTextboxes
	Gosub, removeMarkers
	
	tooltip
return

;=====THE END====