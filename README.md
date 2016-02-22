Automode Plugin for Cinch
========================
Auto op/halfop/voice users based on nick!user@host or apply the mode to an
entire channel

Usage
-----

Until I figure out how to make it into a gem, download the .rb file, and place 
it in a subdirectory of your bot entitled 
`plugins` then require it via `require_relative`. 
Add it to your bot like so:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ruby
require 'cinch'
require_relative 'plugins/automode.rb'

bot = Cinch::Bot.new do
configure do |c|
  c.server = 'your server'
  c.nick = 'your nick'
  c.realname = 'your realname'
  c.user = 'your user'
  c.channels = ['#yourchannel']
  c.plugins.plugins = [Cinch::Plugins::Automode]
end

bot.start
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Contained Commands
------------------

[automode (on|off)]
Enable/disable the plugin in the current channel. Default is off.

[add (op|halfop|voice) nick user@host]
Add nick with user@host to the auto-(op|halfop|voice) list

[del (op|halfop|voice) nick user@host]
Delete nick with user@host from the auto-(op|halfop|voice) list

[add channel (op|halfop|voice)]
Add the entire channel to the list, so anyone who joins gets the mode.

[del channel (op|halfop|voice)]
Delete the channel from the mode list.

License
-------

Licensed under The MIT License (MIT)
Please see LICENSE