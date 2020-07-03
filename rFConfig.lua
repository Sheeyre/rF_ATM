rF_Config = {}

--Database table containing user information
rF_Config['db-user-table'] = 'users'	
--Name of column that holds a user's unique identifier ie steamid, discordid (assumes same table as db-user-table)
rF_Config['db-user-identification-column'] = 'identifier'	
--Name of column that holds a user's bank balance (assumes same table as db-user-table)
rF_Config['db-user-bank-column'] = 'bank'	
--Name of column that holds a user's cash balance (assumes same table as db-user-table)
rF_Config['db-user-cash-column'] = 'cash'	


--Database table containing ATM transaction information
rF_Config['db-transaction-table'] = 'transactions'

rF_Config['atm-hashes'] = {
	[0] = -1126237515,
	[1] = -1364697528,
	[2] = 506770882
}
