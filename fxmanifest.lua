fx_version 'bodacious'
games { 'gta5' }

description 'GTA V ATM for FiveM'

client_scripts {
	'rFClient_ATMManager.lua'
}

server_scripts {
    'rFServer_ATMManager.lua',
    'rFConfig.lua',
    '@mysql-async/lib/MySQL.lua'
}