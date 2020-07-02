# rF_ATM

rF_ATM is a FiveM resource that brings the original GTA V ATM to FiveM servers.  

**As this resource is not linked to a framework, you may have to alter the database values on the server file to match your framework.**   

## Events
### rF_ATM:Transaction - Client to Server - Params(rF_TransactionAmount, rF_IsWithdrawal)
**Sent each time a player makes a client side transaction on an ATM.**
1. Verifies that the transaction is possible given the player's current bank and cash values.
2. Updates database table to reflect new bank and cash values for the player.
3. Creates a database entry for the transaction.
3. Sends the player's client an event (`rF_ATM:TransactionSuccess`) to signal that the transaction was successful and to update the player's ATM values (bank, cash, transaction).

### rF_ATM:StartATM - Client to Server - Params()
**Sent when the client script initializes.**
1. Fetches bank, cash and transaction values from the database.
2. Sends the player's client two events (`rF_ATM:SetMoney`, `rF_ATM:SetMoney`) to initialize the client's ATM values (bank, cash, transaction).

### rF_ATM:TransactionSuccess - Server to Client - Params(rF_BankAmount, rF_CashAmount, rF_TransactionJSON)
**Sent when the server verifies a transaction.**
1. Sets `rF_PlayerBank` and `rF_PlayerCash` to reflect the values from the server.
2. Adds the given transaction to the transactions table, `rF_Transactions`.
