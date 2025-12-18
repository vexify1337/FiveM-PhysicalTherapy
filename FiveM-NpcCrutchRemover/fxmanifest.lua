fx_version 'cerulean'
game 'gta5'
shared_script '@WaveShield/resource/include.lua'
shared_script '@WaveShield/resource/waveshield.js'
author 'FearX Scripts'
description 'Physical Therapy - NPC Crutch Remover'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib'
}

escrow_ignore {
    'client/main.lua',
    'server/main.lua',
    'config.lua'
}

dependency '/assetpacks'