RegisterNetEvent('rF_ATM:Transaction')
AddEventHandler('rF_ATM:Transaction', function(rF_TransactionAmount, rF_IsWithdrawal)
	local source = source
	local SteamID = GetPlayerIdentifier(source, 0):sub(7)
		
	MySQL.ready(function()
	    MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @SteamID', { ['@SteamID'] = SteamID }, function(result)
			if(rF_IsWithdrawal) then
				local TransactionBankResult = result[1]['bank'] - rF_TransactionAmount
				local TransactionCashResult = result[1]['cash'] + rF_TransactionAmount
				if(TransactionBankResult >= 0) then
					if(rF_TransactionAmount>0) then
						local Transaction  = CreateTransaction(SteamID, 'Cash Withdrawn', -rF_TransactionAmount, GetFormattedTime())
						TriggerClientEvent('rF_ATM:TransactionSuccess', source, TransactionBankResult, TransactionCashResult, json.encode(Transaction))
					else
						TriggerClientEvent('rF_ATM:TransactionSuccess', source, TransactionBankResult, TransactionCashResult)
					end

					MySQL.Async.execute('UPDATE users SET bank = @TransactionBankResult, cash = @TransactionCashResult WHERE identifier = @SteamID', {
						['TransactionBankResult'] = TransactionBankResult,
						['TransactionCashResult'] = TransactionCashResult,
						['SteamID'] = SteamID
					})
				end
			else
				local TransactionBankResult = result[1]['bank'] + rF_TransactionAmount
				local TransactionCashResult = result[1]['cash'] - rF_TransactionAmount
				if(TransactionCashResult >= 0) then
					if(rF_TransactionAmount>0) then
						local Transaction = CreateTransaction(SteamID, 'Cash Deposited', rF_TransactionAmount, GetFormattedTime())
						TriggerClientEvent('rF_ATM:TransactionSuccess', source, TransactionBankResult, TransactionCashResult, json.encode(Transaction))
					else
						TriggerClientEvent('rF_ATM:TransactionSuccess', source, TransactionBankResult, TransactionCashResult)
					end

					MySQL.Async.execute('UPDATE users SET cash = @TransactionCashResult, bank = @TransactionBankResult WHERE identifier = @SteamID', {
						['TransactionBankResult'] = TransactionBankResult,
						['TransactionCashResult'] = TransactionCashResult,
						['SteamID'] = SteamID
					})
				end
			end
		end)
	end)
end)

RegisterNetEvent('rF_ATM:StartATM')
AddEventHandler('rF_ATM:StartATM', function()
	print("Starting ATM")
	local source = source
	local SteamID = GetPlayerIdentifier(source, 0):sub(7)

	MySQL.ready(function()
		local BankAmount = 0
		local CashAmount = 0
		local Transactions = {}

		MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @SteamID', { ['@SteamID'] = SteamID }, function(result)
			BankAmount = result[1]['bank']
			CashAmount = result[1]['cash']

			print("Sending $"..BankAmount.." - $"..CashAmount)
			TriggerClientEvent('rF_ATM:SetMoney', source, BankAmount, CashAmount)
		end)


		MySQL.Async.fetchAll('SELECT * FROM transactions WHERE player = @SteamID', { ['@SteamID'] = SteamID }, function(result)
			for k,v in pairs(result) do
				Transactions[k] = v
			end

			print("Sending $"..json.encode(Transactions))
			TriggerClientEvent('rF_ATM:SetTransactions', source, json.encode(Transactions))
		end)
	end)
end)

function CreateTransaction(SteamID, Reason, Amount, Date)
	MySQL.ready(function()
		MySQL.Async.execute('INSERT INTO transactions (player, reason, amount, date) VALUES (@SteamID, @Reason, @Amount, @Date)', {
			['SteamID'] = SteamID,
			['Reason'] = Reason,
			['Amount'] = Amount,
			['Date'] = Date
		})
	end)

	return {
		['player'] = SteamID,
		['reason'] = Reason,
		['amount'] = math.abs(Amount),
		['date'] = Date
	}
end

function GetFormattedTime()
	TimeTable = os.date('*t')
	local Day = '01'
	local Month  = '01'
	local Year = '1900'
	if(string.len(''..TimeTable['day']) == 1) then
		Day = '0'..TimeTable['day']
	else
		Day = TimeTable['day']
	end

	if(string.len(''..TimeTable['month']) == 1) then
		Month = '0'..TimeTable['month']
	else
		Month = TimeTable['month']
	end

	return ''..Month..'/'..Day..'/'..TimeTable['year']
end
