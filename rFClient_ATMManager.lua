local rF_PlayerBank = 0
local rF_PlayerCash = 0
local rF_Transactions = {}

local Scaleform = nil
local rF_ScaleformID = 'atm'

local rF_UsingATM = false
local rF_NearATM = false

local rF_LastTransactionWasWithdrawal = false;
local rF_LastTransactionAmount = 0;

local rF_ButtonParams = {}

local rF_CurrentATM = 0
local rF_CurrentScreen = 0

local rF_AwaitingResult = false
local rF_ReturnScaleform = 0

rF_ATMHashes = {
	[0] = -1126237515,
	[1] = -1364697528,
	[2] = 506770882
}

AddEventHandler('onClientResourceStart', function(resourceName) 
	if(GetCurrentResourceName() == resourceName) then
		TriggerServerEvent('rF_ATM:StartATM')
	end
end)

RegisterNetEvent('rF_ATM:TransactionSuccess')
AddEventHandler('rF_ATM:TransactionSuccess', function(rF_BankAmount, rF_CashAmount, rF_TransactionJSON)
	rF_PlayerBank = rF_BankAmount
	rF_PlayerCash = rF_CashAmount

	if(rF_TransactionJSON) then
		local DecodedTransaction = json.decode(rF_TransactionJSON)
		table.insert(rF_Transactions, DecodedTransaction)
	end

	if(Scaleform~=nil) then
		rF_OpenTransactionComplete()
	end
end)

RegisterNetEvent('rF_ATM:SetTransactions')
AddEventHandler('rF_ATM:SetTransactions', function(rF_TransactionsJSON)
	local DecodedTransactions = json.decode(rF_TransactionsJSON)
	rF_Transactions = DecodedTransactions
end)

RegisterNetEvent('rF_ATM:SetMoney')
AddEventHandler('rF_ATM:SetMoney', function(rF_BankAmount, rF_CashAmount)
	rF_PlayerBank = rF_BankAmount
	rF_PlayerCash = rF_CashAmount
end)

Citizen.CreateThread(function() 
	--Check if player is near an ATM
	while true do
		rF_NearATM = false
		if(not rF_UsingATM) then
			local PlayerPos = GetEntityCoords(GetPlayerPed(PlayerId()))
			for _, Hash in pairs(rF_ATMHashes) do
				ClosestATMObject = GetClosestObjectOfType(PlayerPos.x, PlayerPos.y, PlayerPos.z, 1.5, Hash, false, false, false)
				if(ClosestATMObject ~= 0) then
					rF_CurrentATM = ClosestATMObject
					rF_NearATM = true
				end
			end
		end
		Citizen.Wait(500)
	end
end)

Citizen.CreateThread(function() 
	--Display ATM help text
	while true do
		if(rF_NearATM) then
			SetTextComponentFormat('STRING');
	        AddTextComponentString('Press ~INPUT_CONTEXT~ to access ATM.');
	        DisplayHelpTextFromStringLabel(0, false, true, -1);

	        ShowHudComponentThisFrame(3);
	        ShowHudComponentThisFrame(4);
		end
		Citizen.Wait(50)
	end
end)

Citizen.CreateThread(function() 
	--Check if player is trying to use ATM
	while true do
		if(IsControlJustPressed(0, 51) and rF_NearATM and (not rF_UsingATM)) then
			Scaleform = nil
			rF_UsingATM = true

			local PlayerPed = PlayerPedId()
			local PlayerPedPos = GetEntityCoords(PlayerPed)
			local ATMPos = GetEntityCoords(rF_CurrentATM)
			local ATMHeading = GetEntityHeading(rF_CurrentATM)
			local ATMForwardVector = GetEntityForwardVector(rF_CurrentATM)

			ClearPedTasks(PlayerPed)
			local x = math.pow(PlayerPedPos.x - ATMPos.x, 2)
			local y = math.pow(PlayerPedPos.y - ATMPos.y, 2)
			local dist = math.sqrt(x+y)
			if(dist > 0.6) then
				TaskGoStraightToCoord(PlayerPed, ATMPos.x - ATMForwardVector.x / 1.75, ATMPos.y - ATMForwardVector.y / 1.75, PlayerPedPos.z, 0.75, 3000, ATMHeading, 1);
			end
			rF_WaitForATMAnim()

			rf_StartATMScaleform()
		end
		Citizen.Wait(0)
	end
end)

Citizen.CreateThread(function()
	--Draw ATM scaleform
	while true do
		if(Scaleform~=nil) then
			if(IsPedDeadOrDying(PlayerPedId(), true)) then
				Scaleform=nil
			end
			
			DisableAllControlActions(0)
			StopCinematicShot(true)

            if(GetLastInputMethod(0)) then
            	SetMouseCursorActiveThisFrame();
				rF_CallScaleformFunction(Scaleform, 'SET_MOUSE_INPUT', GetDisabledControlNormal(0, 239), GetDisabledControlNormal(0, 240))
            else
            	rF_CallScaleformFunction('setCursorInvisible')
            	rF_CallScaleformFunction('SET_MOUSE_INPUT', 0, 0)
            end

            if(IsDisabledControlJustPressed(0, 24)) then
            	BeginScaleformMovieMethod(Scaleform, 'GET_CURRENT_SELECTION');
            	rF_ReturnScaleform = EndScaleformMovieMethodReturn()

            	if(IsScaleformMovieMethodReturnValueReady(rF_ReturnScaleform)) then
            		rF_ATMMouseSelection(GetScaleformMovieMethodReturnValueInt(rF_ReturnScaleform))
            	else
            		rF_AwaitingResult = true
            	end
            elseif(IsDisabledControlJustReleased(0, 202)) then
            	rF_CloseMenu()
            elseif(IsDisabledControlJustPressed(0, 14)) then
            	rF_CallScaleformFunction(Scaleform, 'SCROLL_PAGE', -40)
            elseif(IsDisabledControlJustPressed(0, 15)) then
            	rF_CallScaleformFunction(Scaleform, 'SCROLL_PAGE', 40)
            end

            if(rF_AwaitingResult) then
            	if(IsScaleformMovieMethodReturnValueReady(rF_ReturnScaleform)) then
            		rF_ATMMouseSelection(GetScaleformMovieMethodReturnValueInt(rF_ReturnScaleform))
            	end
            end

            if(IsDisabledControlJustPressed(0, 27)) then
            	rF_CallScaleformFunction(Scaleform, 'SET_INPUT_EVENT', 8)
            elseif(IsDisabledControlJustPressed(0, 20)) then
            	rF_CallScaleformFunction(Scaleform, 'SET_INPUT_EVENT', 9)
            elseif(IsDisabledControlJustPressed(0, 14)) then
            	rF_CallScaleformFunction(Scaleform, 'SET_INPUT_EVENT', 11)
            elseif(IsDisabledControlJustPressed(0, 15)) then
            	rF_CallScaleformFunction(Scaleform, 'SET_INPUT_EVENT', 10)
            end

			DrawScaleformMovieFullscreen(Scaleform, 255, 255, 255, 255, 0)
		end
		Citizen.Wait(0)
	end
end)

function rf_StartATMScaleform()
	rF_LoadScaleform(rF_ScaleformID)
	rF_OpenMenuScreen()
end

function rF_LoadScaleform(ID)
	while(not HasScaleformMovieFilenameLoaded(ID)) do
		RequestScaleformMovie(ID)
		Citizen.Wait(0)
	end
	Scaleform = RequestScaleformMovie(ID)
end

function rF_ATMMouseSelection(SelectionID)
	rF_CallScaleformFunction(Scaleform, 'SET_INPUT_SELECT')
	if(rF_CurrentScreen == 0) then
		if(SelectionID == 1) then
			if(rF_PlayerBank > 0) then
				rF_OpenWithdrawalScreen()
			else
				rF_DisplayATMError('You have insufficient funds to make a withdrawal.')
			end
		elseif(SelectionID == 2) then
			if(rF_PlayerCash > 0) then
				rF_OpenDepositScreen()
			else
				rF_DisplayATMError('You have insufficient cash to make a deposit.')
			end
		elseif(SelectionID == 3) then
			rF_OpenTransactionScreen()
		elseif(SelectionID == 4) then
			rF_CloseMenu()
		elseif(SelectionID == 5) then
			rF_OpenTransferScreen()
		else
			rF_OpenMenuScreen()
		end
	elseif(rF_CurrentScreen == 1 or rF_CurrentScreen == 2) then
		if(SelectionID == 4) then
			rF_OpenMenuScreen()
		else
			rF_DepositWithdrawal(rF_ButtonParams[SelectionID])
		end
	elseif(rF_CurrentScreen == 3) then
		if(SelectionID == 1) then
			rF_OpenTransactionPending()
			TriggerServerEvent('rF_ATM:Transaction', rF_LastTransactionAmount, rF_LastTransactionWasWithdrawal)
		else 
			if(rF_LastTransactionWasWithdrawal) then
				rF_OpenWithdrawalScreen()
			else
				rF_OpenDepositScreen()
			end
		end
	elseif(rF_CurrentScreen == 5) then
		rF_OpenMenuScreen()
	elseif(rF_CurrentScreen == 6) then
		if(SelectionID == 1) then
			rF_OpenMenuScreen()
		end
	elseif(rF_CurrentScreen == 7) then
		if(SelectionID == 1) then
			rF_OpenMenuScreen()
		elseif(SelectionID == 2) then
			--go through with transfer
		end
	end
end

function rF_OpenMenuScreen()
	rF_CurrentScreen = 0

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Choose a service.')
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Withdraw')
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, 'Deposit')
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 5, 'Transfer')
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, 'Transaction Log')
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Exit')
	rF_CallScaleformFunction(Scaleform, 'DISPLAY_MENU')
end

function rF_OpenWithdrawalScreen()
	rF_CurrentScreen = 1

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Select the amount you wish to withdraw from this account.');

    rF_SetupATMMoneyButtons(rF_PlayerBank)
    rF_CallScaleformFunction(Scaleform, 'DISPLAY_CASH_OPTIONS')

    rF_LastTransactionWasWithdrawal = true
end

function rF_OpenDepositScreen()
	rF_CurrentScreen = 2

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Select the amount you wish to deposit into this account.');

    rF_SetupATMMoneyButtons(rF_PlayerCash)
    rF_CallScaleformFunction(Scaleform, 'DISPLAY_CASH_OPTIONS')

    rF_LastTransactionWasWithdrawal = false
end

function rF_OpenTransferScreen()
	rF_CurrentScreen = 7

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Select an account and an amount to transfer.');
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Cancel');
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, 'Transfer');
    rF_CallScaleformFunction(Scaleform, 'DISPLAY_TRANSFER')
end

function rF_OpenTransactionScreen()
	rF_CurrentScreen = 6

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Transaction Log');
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Back');

    if(#rF_Transactions > 0) then
    	i = #rF_Transactions + 1
    	for _, rF_Transaction in pairs(rF_Transactions) do
			if(rF_Transaction['reason'] == 'Cash Withdrawn') then
				rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', i, 0, rF_Transaction['amount'], rF_Transaction['reason'] .. ' ' .. rF_Transaction['date']:sub(0, 10))
			else
				rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', i, 1, rF_Transaction['amount'], rF_Transaction['reason'] .. ' ' .. rF_Transaction['date']:sub(0, 10))
			end
			i = i - 1
    	end
    end

    rF_CallScaleformFunction(Scaleform, 'DISPLAY_TRANSACTIONS')

    rF_LastTransactionWasWithdrawal = false
end

function rF_OpenConfirmationScreen(IsWithdrawal, Amount)
	rF_CurrentScreen = 3

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
	if(IsWithdrawal) then
    	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Do you wish to withdraw $'..rF_MoneyAddCommas(Amount)..' from your account?');
	else
    	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Do you wish to deposit $'..rF_MoneyAddCommas(Amount)..' into your account?');
	end
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Yes');
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, 'No');
    rF_CallScaleformFunction(Scaleform, 'DISPLAY_MESSAGE');
end

function rF_OpenTransactionPending()
	rF_CurrentScreen = 4

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Transaction Pending...');
    rF_CallScaleformFunction(Scaleform, 'DISPLAY_MESSAGE');
end

function rF_OpenTransactionComplete()
	rF_CurrentScreen = 5

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, 'Transaction Complete');
    rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Back');
    rF_CallScaleformFunction(Scaleform, 'DISPLAY_MESSAGE');
end

function rF_DisplayATMError(Error)
	rF_CurrentScreen = 5

	rF_UpdateDisplayBalance()

	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT_EMPTY')
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 0, Error)
	rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, 'Back')
	rF_CallScaleformFunction(Scaleform, 'DISPLAY_MESSAGE')
end

function rF_CloseMenu()
	rF_UsingATM = false
	Scaleform = nil

	ClearPedTasks(PlayerPedId())
end	

function rF_DepositWithdrawal(Amount)
	if(rF_CurrentScreen == 1) then
		rF_OpenConfirmationScreen(true, Amount)
		rF_LastTransactionAmount=Amount
	elseif(rF_CurrentScreen == 2) then
		rF_OpenConfirmationScreen(false, Amount)
		rF_LastTransactionAmount=Amount
	elseif(rF_CurrentScreen == 5) then
		rF_OpenMenuScreen()
	end
end

function rF_SetupATMMoneyButtons(Amount)
	if(Amount > 100000) then
		rF_ButtonParams = {}
		rF_ButtonParams[1] = 50
		rF_ButtonParams[2] = 500
		rF_ButtonParams[3] = 2500
		rF_ButtonParams[5] = 10000
		rF_ButtonParams[6] = 100000

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$500')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, '$2,500')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 5, '$10,000')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 6, '$100,000')

		rF_ButtonParams[7] = Amount
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 7, '$'..rF_MoneyAddCommas(Amount))
	elseif(Amount>10000) then
		rF_ButtonParams = {}
		rF_ButtonParams[1] = 50
		rF_ButtonParams[2] = 500
		rF_ButtonParams[3] = 2500
		rF_ButtonParams[5] = 10000

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$500')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, '$2,500')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 5, '$10,000')

		rF_ButtonParams[6] = Amount
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 6, '$'..rF_MoneyAddCommas(Amount))
	elseif(Amount>2500) then
		rF_ButtonParams = {}
		rF_ButtonParams[1] = 50
		rF_ButtonParams[2] = 500
		rF_ButtonParams[3] = 2500

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$500')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, '$2,500')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')

		rF_ButtonParams[5] = Amount
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 5, '$'..rF_MoneyAddCommas(Amount))
	elseif(Amount>500) then
		rF_ButtonParams = {}
		rF_ButtonParams[1] = 50
		rF_ButtonParams[2] = 500

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$500')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')

		rF_ButtonParams[3] = Amount

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 3, '$'..rF_MoneyAddCommas(Amount))
	elseif(Amount>50) then
		rF_ButtonParams = {}
		rF_ButtonParams[1] = 50

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$50')
		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')

		rF_ButtonParams[2] = Amount

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 2, '$'..rF_MoneyAddCommas(Amount))
	else
		rF_ButtonParams = {}

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 4, 'Back')

		rF_ButtonParams[1] = Amount

		rF_CallScaleformFunction(Scaleform, 'SET_DATA_SLOT', 1, '$'..rF_MoneyAddCommas(Amount))
	end
end

function rF_WaitForATMAnim()
	Citizen.Wait(200)

	while GetScriptTaskStatus(PlayerPedId(), 0x7d8f4411) ~= 7 do
		Citizen.Wait(10)
	end

	rF_PlayAnim('amb@prop_human_atm@male@idle_a', 'idle_b', -1, 8.0, 1)
end

function rF_PlayAnim(Dictionary, Name, Duration, LeadIn, Flag)
	while(not HasAnimDictLoaded(Dictionary)) do
		RequestAnimDict(Dictionary)
		Citizen.Wait(0)
	end

	TaskPlayAnim(PlayerPedId(), Dictionary, Name, LeadIn, 8.0, Duration, Flag, 0, false, false, true)
end

function rF_UpdateDisplayBalance()
	rF_CallScaleformFunction(Scaleform, 'DISPLAY_BALANCE', GetPlayerName(PlayerId()), 'Account balance ', rF_PlayerBank)
end

function rF_CallScaleformFunction(Scaleform, Function, ...)
	local arg={...}
	BeginScaleformMovieMethod(Scaleform, Function)
	for k, Argument in pairs(arg) do
		if (type(Argument) == 'number') then
			if(math.type(Argument) == 'float') then
				PushScaleformMovieMethodParameterFloat(Argument)
			else
				PushScaleformMovieMethodParameterInt(Argument)
			end
		elseif (type(Argument) == 'string') then
			PushScaleformMovieMethodParameterString(Argument)
		elseif (type(Argument) == 'bool') then
			PushScaleformMovieMethodParameterBool(Argument)
		end
	end
	EndScaleformMovieMethod()
end	

function rF_MoneyAddCommas(Amount)
	if(type(Amount)=='number') then
		Amount = ''..Amount
	end
    return #Amount % 3 == 0 and Amount:reverse():gsub('(%d%d%d)', '%1,'):reverse():sub(2) or Amount:reverse():gsub('(%d%d%d)', '%1,'):reverse()
end	