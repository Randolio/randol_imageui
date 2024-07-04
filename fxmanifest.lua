fx_version 'cerulean'
game 'gta5'

author 'Randolio'
description 'Tool to create and display business menus.'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'bridge/client/**.lua',
    'cl_image.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/**.lua',
    'sv_config.lua',
    'sv_image.lua',
}

ui_page { 'html/index.html' }
  
files { 'html/index.html', 'html/script.js', 'html/styles.css', }

lua54 'yes'