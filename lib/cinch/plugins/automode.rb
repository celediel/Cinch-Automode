#!/usr/bin/env ruby
# encoding=utf-8

require 'sequel'

# These are all very annoying.
# rubocop:disable Metrics/LineLength, Metrics/ClassLength, Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/AbcSize

module Cinch
  module Plugins
    # Automode plugin using Sequel + SQLite database
    class Automode
      include Cinch::Plugin
      listen_to :join

      private

      def initialize(*args)
        super
        @automode = {}
        # Initialize the db
        @db = Sequel.sqlite('riria.db')
        # Create the tables if they don't exist
        @db.create_table? :users do
          primary_key :id
          String :name
          String :mode
        end
        @db.create_table? :hostmasks do
          primary_key :id
          Int :user_id
          String :mask
        end
        @db.create_table? :userchans do
          primary_key :id
          Int :user_id
          String :chan
        end
        @db.create_table? :channels do
          primary_key :id
          String :chan
          String :mode
        end
      end

      # reading and writing database methods
      def read_db(nick, hostmask, channel)
        return 'no' unless @db.table_exists?(:users)

        users = @db[:users] # Users table
        hosts = @db[:hostmasks] # Hostmasks table
        userchans = @db[:userchans] # User channels table
        chans = @db[:channels] # Automode all channels table

        unless chans.where(chan: channel).all.empty?
          return chans.where(chan: channel).first[:mode]
        end

        return 'no' if users.where(nick: nick).first.nil?
        return 'admin' if users.where(nick: nick).first[:mode] == 'admin'

        user_id = users.where(nick: nick).first[:id]
        has_hostmasks = hosts.where(user_id: user_id).map(:mask)
        has_channels = userchans.where(user_id: user_id).map(:chan)

        return 'no' unless has_hostmasks.include?(hostmask)
        return 'no' unless has_channels.include?(channel)
        users.where(nick: nick).first[:mode]
      end

      def write_db(nick, hostmask, mode, in_chan)
        users = @db[:users]
        hosts = @db[:hostmasks]
        chans = @db[:userchans]

        # If user isn't in db, add user to db
        if users.where(nick: nick).first.nil?
          users.insert(nick: nick, mode: mode)
        else
          # If user is in db, update mode with provided
          users.where(nick: nick).update(mode: mode)
        end

        user_id = users.where(nick: nick).first[:id]
        if hosts.where(user_id: user_id, mask: hostmask).first.nil?
          hosts.insert(user_id: user_id, mask: hostmask)
        end

        if chans.where(user_id: user_id, chan: in_chan).first.nil?
          chans.insert(user_id: user_id, chan: in_chan)
        end

        # Words to say
        output = "User #{users.where(nick: nick).first[:nick]} added "
        output << "hostmask #{hosts.where(user_id: user_id).all[-1][:mask]} "
        output << "with mode #{users.where(nick: nick).first[:mode]}"

        output
      end

      def add_channel(chan, mode)
        chans = @db[:channels]
        if chans.where(chan: chan).first.nil?
          chans.insert(chan: chan, mode: mode)
        else
          chans.where(chan: chan).update(mode: mode)
        end
        output = "#{chans.where(chan: chan).first[:chan]} "
        output << "added with mode #{chans.where(chan: chan).first[:mode]}"

        output
      end

      public

      match(/automode (on|off)$/, method: :endisable)
      def endisable(m, option)
        hostmask = m.raw.split(' ')[0].delete(':').split('!')[1]
        return unless read_db(m.user.nick, hostmask, nil) == 'admin'
        @automode[m.channel] = option == 'on'

        m.reply "Automode is now #{@automode[m.channel] ? 'enabled' : 'disabled'}"
      end

      def listen(m)
        @automode[m.channel] ||= true
        return unless @automode[m.channel]
        return if m.user.nick == bot.nick
        hostmask = m.raw.split(' ')[0].delete(':').split('!')[1]
        mode = read_db(m.user.nick, hostmask, m.channel.to_s)
        case mode
        when 'admin'
          m.channel.op(m.user)
        when 'op'
          m.channel.op(m.user)
        when 'halfop'
          m.channel.mode("+h #{m.user}")
        when 'voice'
          m.channel.voice(m.user)
        when 'no'
          return
        else
          return
        end
      end

      match(/add(?: (.+))?/, method: :add_user)
      def add_user(m, query)
        hostmask = m.raw.split(' ')[0].delete(':').split('!')[1]
        return unless read_db(m.user.nick, hostmask, nil) == 'admin'
        # .add mode nick user@host
        query = query.split(' ')
        mode = query[0]
        nick = query[1]
        hostmask = query[2]
        goodtypes = %w(op halfop voice admin)
        goodmask = /(.*)@(.*)/ =~ hostmask

        if mode == 'channel'
          m.reply add_channel(m.channel.to_s, query[1])
          return
        end

        m.reply('Bad mode type!') && return unless goodtypes.include?(mode)
        m.reply('Bad hostmask!') && return unless goodmask
        m.reply write_db(nick, hostmask, mode, m.channel.to_s)
      end

      match(/del(?: (.+))?/, method: :del_user)
      def del_user(m, query)
        hostmask = m.raw.split(' ')[0].delete(':').split('!')[1]
        return unless read_db(m.user.nick, hostmask, nil) == 'admin'
        # .del nick user@host >>> remove host from nick
        # .del nick >>> remove nick from db
        nick = query.split[0]
        host = query.split[1]
        users = @db[:users]
        hosts = @db[:hostmasks]

        if nick == 'channel'
          chan_todel = m.channel.to_s
          chans = @db[:channels]
          m.reply 'Channel not in db' && return if chans.where(chan: chan_todel).first.nil?
          them = chans.where(chan: chan_todel).first[:mode]
          chans.where(chan: chan_todel).delete
          m.reply "#{chan_todel} with mode #{them} removed"
          return
        end

        m.reply('User not in db!') && return if users.where(nick: nick).all.empty?

        user_id = users.where(nick: nick).first[:id]
        if host.nil?
          u_num = users.where(nick: nick).delete
          h_num = hosts.where(user_id: user_id).delete
          if u_num.zero? && h_num.zero?
            m.reply('Not baleeted!')
          else
            m.reply('Baleeted!')
          end
        else
          h_num = hosts.where(user_id: user_id, mask: host).delete
          if h_num.zero?
            m.reply('Not baleeted!')
          else
            m.reply('Baleeted!')
          end
        end
      end
    end
  end
end

# vim:tabstop=2 softtabstop=2 expandtab shiftwidth=2 smarttab foldmethod=syntax:
