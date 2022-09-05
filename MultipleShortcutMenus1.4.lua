LUAGUI_NAME = "More Shortcut Menus"
LUAGUI_AUTH = "Zurph / TopazTK"
LUAGUI_DESC = "Credits to KSX Num & DA for offsets & Denhonator for the autosave script which was used as a reference for reading/writing files."

--All variables have had offset 0x56454E subtracted.
local canExecute = false
local bounceBool = false
local TextCheck = false
local SysBarBase = 0x255ED11 --This is the part we edit. The "IZE" part.
local FormCheck = 0x0446086

local ShortListFilterINST = 0x349718 - 0x56454E;
local ShortEquipFilterINST = 0x3C1A46 - 0x56454E;
local ShortCategoryFilterINST = 0x35924F - 0x56454E;
local ShortIconAssignINST = 0x2E99CA - 0x56454E;

local ShortIcon = 0x02 -- Change this for Rando use.

function _OnInit()
	if GAME_ID == 0x431219CC and ENGINE_TYPE == "BACKEND" then
		ConsolePrint("Customize 5 shortcut menus using R3/L3 while in the pause menu. Access those shortcut menus using L1 + R3 / L3 to scroll between them, or L1+D-pad/L1+R2 in-game.")
		
		-- Shortucttable Forms ASM Override!
		if ReadByte(ShortCategoryFilterINST) ~= 0x90 then
			-- Show Forms on the Shortcut Menu.
			WriteArray(ShortListFilterINST, { 0xEB, 0x4E, 0x90, 0x90 })
			WriteArray(ShortListFilterINST + 0x50, { 0x81, 0xCB, 0x00, 0x00, 0x24, 0x00 })
			WriteArray(ShortListFilterINST + 0x56, { 0xEB, 0xAA })
			
			-- Allow Forms to be shortcutted.
			WriteArray(ShortEquipFilterINST, { 0xEB, 0x1B, 0x90, 0x90, 0x90, 0x90, 0x90 })
			WriteArray(ShortEquipFilterINST + 0x1D, { 0x80, 0xF9, 0x15, 0x74, 0xF2 })
			WriteArray(ShortEquipFilterINST + 0x22, { 0x31, 0xC0, 0x48, 0x83, 0xC4, 0x28, 0xC3 })

			-- Magic Reassignment Fix.
			WriteArray(ShortCategoryFilterINST, { 0x90, 0x90 })

			-- Icon Reassignment Read.
			local iconRead = ReadArray(ShortIconAssignINST + 0x03, 0x19)

			-- Icon Reassignment Fix.
			WriteArray(ShortIconAssignINST, { 0xEB, 0x19 })
			WriteArray(ShortIconAssignINST + 0x02, iconRead)
			WriteArray(ShortIconAssignINST + 0x1B, { 0x3C, 0x0B, 0x75, 0x02, 0xB0, ShortIcon, 0x88, 0x47, 0x01, 0xEB, 0xDC })
		end

		canExecute = true
	else
		ConsolePrint("MultiShortcutMenu Install: failed.")
	end
end
function _OnFrame()
	UpdateMagic()
	ReadInput = 0x1ACF3C
	ReadPause = 0x1CE2B6
	MenuFlag = 0x6877DA
	Shortcuts = 0x44625A
	SaveData = 0x450B62
	if canExecute == true  then 
		if ReadByte(FormCheck) ~= 0x03 then
		_readMenu = ReadByte(SaveData)
		_readFlag = ReadShort(MenuFlag)
	
		_readSave = ReadArray(Shortcuts, 0x08) --Unused Save Data area, to save shortcut menu to. 
		_readLoad = ReadArray(SaveData + 0x01 + (0x08 * _readMenu), 0x08) --Where the data is loaded from. Loads in "pieces", and +1 denotes the area of 8 bytes to grab.

		if ReadInt(ReadInput) & 0x0400 == 0x0400 or _readFlag == 0x03 then
			if bounceBool == false then
				if ReadInt(ReadInput) & 0x02 == 0x02 and _readMenu < 4 then --L3 Pressed. Prevents input lockout. Scrolls UP
					WriteByte(SaveData, _readMenu + 1) 
					bounceBool = true
				end
		
				if ReadInt(ReadInput) & 0x04 == 0x04 and _readMenu > 0 then --R3 pressed. Prevents input lockout. Scrolls DOWN
					WriteByte(SaveData, _readMenu - 1)
					bounceBool = true 
				end	
			end

			if ReadInt(ReadInput) & 0x0F == 0x00 and bounceBool == true then
				bounceBool = false
			end
		end
		
		if _readFlag == 0x00 or (_readFlag == 0x03 and ReadInt(ReadInput) & 0x0F ~= 0x00) then
			WriteArray(Shortcuts, _readLoad)
		end

		if _readFlag == 0x03 and ReadInt(ReadInput) & 0x0F == 0x00 then
			WriteArray(SaveData + 0x01 + (0x08 * _readMenu), _readSave)
		end
		--Classic Style Below: Swaps the current menu in the save data area, allowing you to access the menus like before.
		if ReadInt(ReadInput) & 0x0400 == 0x0400 and _readFlag == 0x00 then --Prevents input lockout, so you can glide without needing an additional if statements.
			if ReadInt(ReadInput) & 0x10 == 0x10 then --L1+Up
				WriteByte(SaveData, 0x0)
			elseif ReadInt(ReadInput) & 0x20 == 0x20 then --L1+Right
				WriteByte(SaveData, 0x1)
			elseif ReadInt(ReadInput) & 0x40 == 0x40 then --L1+Down
				WriteByte(SaveData, 0x2)
			elseif ReadInt(ReadInput) & 0x80 == 0x80 then --L1+Left
				WriteByte(SaveData, 0x3)
			elseif ReadInt(ReadInput) & 0x0600 == 0x0600 then --L1+R2. Requires 00 after the 0x06 as otherwise it won't swap properly.
				WriteByte(SaveData, 0x4)
			end
		end
		if ReadByte(SysBarBase-1) == 0xA6 then --Checks the byte RIGHT BEFORE where we edit in Customize. This prevents errors with the script upon refreshing, as the byte we changed would be different.
			CustomTXT = 0x255ED11 --Base KH2 SysBar
			TextCheck = true
		elseif ReadByte(SysBarBase-1) == 0x00 then --Compares same sys.bar offset across different sys.bars.
			CustomTXT = 0x255D625 --GoA ROM
			TextCheck = true
		elseif ReadByte(SysBarBase-1) == 0x9E then 
			CustomTXT = 0x255E915 --Double Plus SysBar
			TextCheck = true
		elseif ReadByte(SysBarBase-1) == 0x01 then
			CustomTXT = 0x255D625 --SMT Spell Names + GoA ROM SysBar
			TextCheck = true 
		end
	if TextCheck == true then 
		if ReadByte(CustomTXT+1) ~= 0x0A then 
			WriteArray(CustomTXT+1, {0x0A, 0x0B, 0x09, 0xE0, 0x0B, 0x50, 0x2B, 0x09}) --Initial write. These values stay constant and only need to be written once.
		elseif _readMenu == 0 and ReadByte(CustomTXT) ~= 0x91 then --Change text. 2nd check ensures it isn't written every single frame.
			WriteByte(CustomTXT, 0x91)
			WriteByte(CustomTXT+0x9, 0xEE)
			--Replaces the Option string in-game, to allow for the dynamic button prompts. 
		elseif _readMenu == 1 and ReadByte(CustomTXT) ~= 0x92 then
			WriteByte(CustomTXT, 0x92)
			WriteByte(CustomTXT+0x9, 0xF1)
		elseif _readMenu == 2 and ReadByte(CustomTXT) ~= 0x93 then
			WriteByte(CustomTXT, 0x93)
			WriteByte(CustomTXT+0x9, 0xEF)
		elseif _readMenu == 3 and ReadByte(CustomTXT) ~= 0x94 then
			WriteByte(CustomTXT, 0x94)
			WriteByte(CustomTXT+0x9, 0xF0)
		elseif _readMenu == 4 and ReadByte(CustomTXT) ~= 0x95 then
			WriteByte(CustomTXT, 0x95)
			WriteByte(CustomTXT+0x9, 0xE3)
		end
		end		
	end
--Saving/Loading Presets.
		if _readFlag == 0x03 then
			if ReadInt(ReadInput) == 0x0F01 then
				local f = io.open("KH2Shortcuts.dat", "rb")
				if f ~= nil then
					WriteString(SaveData, f:read("*a")) --Reading Shortcut Data from the .dat file, & writing to the game as a string. 
					f:close()
				end
			elseif ReadInt(ReadInput) == 0x0801 then
				local f = io.open("KH2Shortcuts.dat", "wb")
					f:write(ReadString(SaveData,0x29)) --Reading Shortcut Data from the Save File, & storing to .dat as a string.
					f:close()
			end
		end
	end
end

function UpdateMagic()
	FireTier = 0x9AA644-0x56454E --Count of Fires
	BlizzTier = FireTier+0x1	--Count of Blizzards
	ThunTier = BlizzTier+0x1	--Count of Thunders
	CureTier = ThunTier+0x1		--Count of Cures
	MagTier = CureTier+0x38		--Count of Magnets
	RefTier = MagTier+0x1		--Count of Reflects
	local Save = 0x450B61
	local CheckingSave = Save+0x02
	
	for i = 0, 19, 1 do
		--Update Fire to Fira
		if ReadByte(CheckingSave) == 49 and ReadByte(FireTier) == 2 then
			WriteByte(CheckingSave, 0x77)
		end
		--Update Fire or Fira to Firaga.
		if ReadByte(CheckingSave) == 49 and ReadByte(FireTier) == 3 or ReadByte(CheckingSave) == 119 and ReadByte(FireTier) == 3 then
			WriteByte(CheckingSave, 0x78)
		end
		--Update Blizzard to Blizzara (BLIZZARD AND THUNDER ARE SWAPPED AHHHHH)
		if ReadByte(CheckingSave) == 51 and ReadByte(BlizzTier) == 2 then
			WriteByte(CheckingSave, 0x79)
		end
		--Update Blizzard or Blizzara to Blizzaga.
		if ReadByte(CheckingSave) == 51 and ReadByte(BlizzTier) == 3 or ReadByte(CheckingSave) == 121 and ReadByte(BlizzTier) == 3 then
			WriteByte(CheckingSave, 0x7A)
		end
		--Update Thunder to Thundara
		if ReadByte(CheckingSave) == 50 and ReadByte(ThunTier) == 2 then
			WriteByte(CheckingSave, 0x7B)
		end
		--Update Thunder or Thundara to Thundaga.
		if ReadByte(CheckingSave) == 50 and ReadByte(ThunTier) == 3 or ReadByte(CheckingSave) == 123 and ReadByte(ThunTier) == 3 then
			WriteByte(CheckingSave, 0x7C)
		end
		--Update Cure to Cura
		if ReadByte(CheckingSave) == 52 and ReadByte(CureTier) == 2 then
			WriteByte(CheckingSave, 0x7D)
		end
		--Update Cure or Cura to Curaga.
		if ReadByte(CheckingSave) == 52 and ReadByte(CureTier) == 3 or ReadByte(CheckingSave) == 125 and ReadByte(CureTier) == 3 then
			WriteByte(CheckingSave, 0x7E)
		end
		--Update Magnet to Magnera
		if ReadByte(CheckingSave) == 174 and ReadByte(MagTier) == 2 then
			WriteByte(CheckingSave, 0xAF)
		end
		--Update Magnet or Magnera to Magnega.
		if ReadByte(CheckingSave) == 174 and ReadByte(MagTier) == 3 or ReadByte(CheckingSave) == 175 and ReadByte(MagTier) == 3 then
			WriteByte(CheckingSave, 0xB0)
		end
		--Update Reflect to Reflera
		if ReadByte(CheckingSave) == 177 and ReadByte(RefTier) == 2 then
			WriteByte(CheckingSave, 0xB2)
		end
		--Update Reflect or Reflera to Reflega.
		if ReadByte(CheckingSave) == 177 and ReadByte(RefTier) == 3 or ReadByte(CheckingSave) == 178 and ReadByte(RefTier) == 3 then
			WriteByte(CheckingSave, 0xB3)
		end
		CheckingSave = CheckingSave+0x02 --Update location of CheckSave

	end
end

--Future updates: Rewrite & clean up code further.
--Further compatibility with mods that edit sys.bar.
--Find cleaner way i/o instead of using strings.
--Cleaner, less hard-coded method of command ID updates

--CMD IDS: (in decimal)
--Fire 		-> 49		Fira 		-> 119		Firaga 		-> 120		(HEX: 0x31/0x77/0x78)
--Blizzard 	-> 51		Blizzara 	-> 121		Blizzaga 	-> 122		(HEX: 0x33/0x79/0x7A)
--Thunder 	-> 50		Thundara 	-> 123 		Thundaga 	-> 124		(HEX: 0x32/0x7B/0x7C)
--Cure 		-> 52		Cura		-> 125		Curaga 		-> 126		(HEX: 0x34/0x7D/0x7E)
--Magnet	-> 174		Magnera		-> 175		Magnega		-> 176		(HEX: 0xAE/0xAF/0xB0)
--Reflect	-> 177		Reflera		-> 178		Reflega		-> 179		(HEX: 0xB1/0xB2/0xB3)	
