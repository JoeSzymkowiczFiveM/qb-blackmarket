fx_version 'cerulean'
game 'gta5'

client_scripts {
    '@salty_tokenizer/init.lua',
	"client/main.lua",
}

server_scripts {
    --'@oxmysql/lib/MySQL.lua',
    '@mongodb/lib/MongoDB.lua',
    '@salty_tokenizer/init.lua',
    "server/main.lua",
}