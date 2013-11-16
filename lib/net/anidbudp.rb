require 'socket'
require 'openssl'
require 'timeout'

module Net
  PROTOVER = 3
  CLIENTNAME = 'anidbruby'
  CLIENTVER = 1

  FILE_AMASKS = {
    :anime_total_episodes    => 0x80000000,
    :highest_episode_number  => 0x40000000,
    :year                    => 0x20000000,
    :type                    => 0x10000000,
    :related_aid_list        => 0x08000000,
    :related_aid_type        => 0x04000000,
    :category_list           => 0x02000000,
    #reserved                => 0x01000000,
    :romaji_name             => 0x00800000,
    :kanji_name              => 0x00400000,
    :english_name            => 0x00200000,
    :other_name              => 0x00100000,
    :short_name_list         => 0x00080000,
    :synonym_list            => 0x00040000,
    #retired                 => 0x00020000,
    #retired                 => 0x00010000,
    :epno                    => 0x00008000,
    :ep_english_name         => 0x00004000,
    :ep_romaji_name          => 0x00002000,
    :ep_kanji_name           => 0x00001000,
    :ep_rating               => 0x00000800,
    :ep_vote_count           => 0x00000400,
    #unused                  => 0x00000200,
    #unused                  => 0x00000100,
    :group_name              => 0x00000080,
    :group_short_name        => 0x00000040,
    #unused                  => 0x00000020,
    #unused                  => 0x00000010,
    #unused                  => 0x00000008,
    #unused                  => 0x00000004,
    #unused                  => 0x00000002,
    :date_aid_record_updated => 0x00000001,
  }

  FILE_AMASKS_ORDER = [
    :anime_total_episodes, :highest_episode_number, :year, :type, :related_aid_list, :related_aid_type, :category_list, 
    :romaji_name, :kanji_name, :english_name, :other_name, :short_name_list, :synonym_list, 
    :epno, :ep_english_name, :ep_romaji_name, :ep_kanji_name, :ep_rating, :ep_vote_count, 
    :group_name, :group_short_name, :date_aid_record_updated, 
  ]

  FILE_FMASKS = {
    #unused             => 0x80000000,
    :aid                => 0x40000000,
    :eid                => 0x20000000,
    :gid                => 0x10000000,
    :mylist_id          => 0x08000000,
    :other_episodes     => 0x04000000,
    :is_deprecated      => 0x02000000,
    :state              => 0x01000000,
    :size               => 0x00800000,
    :ed2k               => 0x00400000,
    :md5                => 0x00200000,
    :sha1               => 0x00100000,
    :crc32              => 0x00080000,
    #unused             => 0x00040000,
    #unused             => 0x00020000,
    #reserved           => 0x00010000,
    :quality            => 0x00008000,
    :source             => 0x00004000,
    :audio_codec_list   => 0x00002000,
    :audio_bitrate_list => 0x00001000,
    :video_codec        => 0x00000800,
    :video_bitrate      => 0x00000400,
    :video_resolution   => 0x00000200,
    :file_type          => 0x00000100,
    :dub_language       => 0x00000080,
    :sub_language       => 0x00000040,
    :length             => 0x00000020,
    :description        => 0x00000010,
    :aired_date         => 0x00000008,
    #unused             => 0x00000004,
    #unused             => 0x00000002,
    :anidb_file_name    => 0x00000001,
  }

  FILE_FMASKS_ORDER = [
    :aid, :eid, :gid, :mylist_id, :other_episodes, :is_deprecated, :state, 
    :size, :ed2k, :md5, :sha1, :crc32, 
    :quality, :source, :audio_codec_list, :audio_bitrate_list, :video_codec, :video_bitrate, :video_resolution, :file_type, 
    :dub_language, :sub_language, :length, :description, :aired_date, :anidb_file_name, 
  ]

  ANIME_AMASKS = {
    :aid                    => 0x80000000000000,
    :dateflags             => 0x40000000000000,
    :year                   => 0x20000000000000,
    :type                   => 0x10000000000000,
    :related_aid_list       => 0x08000000000000,
    :related_aid_type       => 0x04000000000000,
    :category_list          => 0x02000000000000,
    :category_weight_list   => 0x01000000000000,
    :romaji_name            => 0x00800000000000,
    :kanji_name             => 0x00400000000000,
    :english_name           => 0x00200000000000,
    :other_name             => 0x00100000000000,
    :short_name_list        => 0x00080000000000,
    :synonym_list           => 0x00040000000000,
    #retired                => 0x00020000000000,
    #retired                => 0x00010000000000,
    :episodes               => 0x00008000000000,
    :highest_episode_number => 0x00004000000000,
    :special_ep_count       => 0x00002000000000,
    :air_date               => 0x00001000000000,
    :end_date               => 0x00000800000000,
    :url                    => 0x00000400000000,
    :picname                => 0x00000200000000,
    :category_id_list       => 0x00000100000000,
    :rating                 => 0x00000080000000,
    :vote_count             => 0x00000040000000,
    :temp_rating            => 0x00000020000000,
    :temp_vote_count        => 0x00000010000000,
    :average_review_rating  => 0x00000008000000,
    :review_count           => 0x00000004000000,
    :award_list             => 0x00000002000000,
    :is_18_restricted       => 0x00000001000000,
    :anime_planet_id        => 0x00000000800000,
    :ANN_id                 => 0x00000000400000,
    :allcinema_id           => 0x00000000200000,
    :AnimeNfo_id            => 0x00000000100000,
    #unused                 => 0x00000000080000,
    #unused                 => 0x00000000040000,
    #unused                 => 0x00000000020000,
    :date_record_updated    => 0x00000000010000,
    :character_id_list      => 0x00000000008000,
    :creator_id_list        => 0x00000000004000,
    :main_creator_id_list   => 0x00000000002000,
    :main_creator_name_list => 0x00000000001000,
    #unused                 => 0x00000000000800,
    #unused                 => 0x00000000000400,
    #unused                 => 0x00000000000200,
    #unused                 => 0x00000000000100,
    :specials_count         => 0x00000000000080,
    :credits_count          => 0x00000000000040,
    :other_count            => 0x00000000000020,
    :trailer_count          => 0x00000000000010,
    :parody_count           => 0x00000000000008,
    #unused                 => 0x00000000000004,
    #unused                 => 0x00000000000002,
    #unused                 => 0x00000000000001,
  }

  ANIME_AMASKS_ORDER = [
    :aid, :dateflags, :year, :type, :related_aid_list, :related_aid_type, :category_list, :category_weight_list, 
    :romaji_name, :kanji_name, :english_name, :other_name, :short_name_list, :synonym_list, 
    :episodes, :highest_episode_number, :special_ep_count, :air_date, :end_date, :url, :picname, :category_id_list, 
    :rating, :vote_count, :temp_rating, :temp_vote_count, :average_review_rating, :review_count, :award_list, :is_18_restricted, 
    :anime_planet_id, :ANN_id, :allcinema_id, :AnimeNfo_id, :date_record_updated, 
    :character_id_list, :creator_id_list, :main_creator_id_list, :main_creator_name_list, 
    :specials_count, :credits_count, :other_count, :trailer_count, :parody_count, 
  ]


  ANIME_AMASKS_ORDER.delete(:aid)

  DEFAULT_FILE_FFIELDS =  [ :aid, :eid, :gid, :length, :quality, :video_resolution,
                            :source, :sub_language, :dub_language ]
  DEFAULT_FILE_AFIELDS =  [ :type, :year, :highest_episode_number,
                            :english_name, :romaji_name, :epno, :ep_english_name,
                            :ep_romaji_name, :group_name, :group_short_name ]
  DEFAULT_ANIME_AFIELDS = [ :aid, :dateflags, :year, :type, :romaji_name, :english_name,
                            :episodes, :highest_episode_number, :air_date, :end_date,
                            :is_18_restricted ]
  EPISODE_FIELDS =        [ :eid, :aid, :length, :rating, :votes, :epno,
                            :english_name, :romaji_name, :kanji_name, :aired ]
  GROUP_FIELDS =          [ :gid, :rating, :votes, :acount, :fcount, :name,
                            :short_name, :irc_channel, :irc_server, :url, :picname ]
  MYLIST_FIELDS =         [ :lid, :fid, :eid, :aid, :gid, :date, :state, :viewdate,
                            :storage, :source, :other, :filestate ]
  MULTI_MYLIST_FIELDS =   [ :title, :episodes, :unknown_ep_list, :hdd_ep_list, :cd_ep_list, :deleted_ep_list]

  MYLIST_STATES = {
    :unknown     => 0,
    :hdd         => 1,
    :cd          => 2,
    :deleted     => 3,
  }

  MYLIST_FILE_STATES = {
    :original    => 0,
    :invalid     => 1,
    :self_edited => 2,
    :self_ripped => 10,
    :dvd         => 11,
    :vhs         => 12,
    :tv          => 13,
    :theaters    => 14,
    :streamed    => 15,
    :other       => 100,
  }
  
  class AniDBUDP
    class Error               < Exception   ; end

    class BannedError         < Error       ; end

    class ParameterError      < Error       ; end

    class ClientError         < Error       ; end
    class ClientAuthError     < ClientError ; end
    class ClientAccessError   < ClientError ; end
    class ClientBannedError   < ClientError ; end
    class ClientOutdatedError < ClientError ; end
    class ClientSessionError  < ClientError ; end

    class ServerError         < Error       ; end
    class ServerTimeout       < ServerError ; end
    class ServerOfflineError  < ServerError ; end

    class Reply
      attr_accessor :tag, :code, :text, :lines

      def initialize(msg)
        if msg[0] =~ /^radb(\d+) (\d+) (.*)$/
          @tag = $1.to_i
          @code = $2.to_i
          @text = $3
          @lines = msg[1..-1]
        else
          @code = nil
          @lines = msg
          @text = ""
          @tag = nil
        end
      end

      def to_s
        "#{@code} : #{@text}" + (@lines.empty? ? '' : "(#{@lines.join(' / ')})")
      end
    end

    class << self
      def escape(v)
        case v
        when true  then "1"
        when false then "0"
        when nil   then ""
        else            v.to_s.gsub(/&/, '&amp;').gsub(/\n/, '<br />')
        end
      end
      def unescape(v)
        v.to_s.gsub(/<br ?\/>/, "\n").gsub(/`/, "'")
      end
      def unescape!(v)
        v = v.to_s unless v.is_a? String
        v.gsub!(/<br ?\/>/, "\n")
        v.gsub!(/`/, "'")
        v
      end
      def ed2k_file_hash(file_name)
        #ed2k block size is 9500 KiB
        ed2k_block = 9500 * 1024
        ed2k_hash = ""
        file_size = nil
        File.open(file_name, 'rb') do |f|
          file_size = f.stat.size #while at it, fetch the size of the file
          while block = f.read(ed2k_block) do
            #hashes are concatenated md4 per block size for ed2k hash
            ed2k_hash << OpenSSL::Digest::MD4.digest(block)
          end
          #on size of modulo block size, append another md4 hash of a blank string
          ed2k_hash << OpenSSL::Digest::MD4.digest("") if(file_size % ed2k_block) == 0
        end
        #finally
        ed2k_hash = OpenSSL::Digest::MD4.hexdigest(ed2k_hash)
        [ file_size, ed2k_hash ]
      end
    end

    attr_accessor :connected, :authenticated, :nat, :last_reply, :last_command, :sid

    def initialize(host, port, localport, user = nil, pass = nil, nat = false, logger = nil)
      @tag = 0
      @host = host
      @port = port
      @localport = localport
      @user = user
      @pass = pass
      @connected = false
      @authenticated = false
      @nat = (nat ? true : false)
      @last_activity = Time.now
      @dead = false
      if logger.nil?
        @logger = Object.new
        if $DEBUG
          @logger.instance_eval("def proto(v = '') ; puts v ; end")
        else
          @logger.instance_eval("def proto(v = '') ; end")
        end
      else
        @logger = logger
      end
    end

    def connect(user = nil, pass = nil, nat = false)
      raise ServerOfflineError.new("Trying to send a command to a dead server") if @dead
      @sock = UDPSocket.new()
      @sock.bind(0, @localport)
      @sock.connect(@host, @port)
      @connected = true
      @nat = nat if nat
      @user = user if user
      @pass = pass if pass
    end

    def disconnect()
      @sock.shutdown if @connected
      @connected = false
      @sock = nil
    end

    def connected?
      @connected
    end

    def authenticated?
      @authenticated
    end

    def dead?
      @dead
    end

    def keep_alive()
      if @connected && (Time.now - @last_activity) > 120
        uptime
      end
    end

    # PING
    #   [nat=1]
    # 300 PONG
    #   {int4 port} (when nat=1)
    def ping
      if @nat
        command("PING",
                :nat => 1)
      else
        command("PING")
      end
    end

    # AUTH
    #   user={str username}
    #  &pass={str password}
    #  &protover={int4 apiversion}
    #  &client={str clientname}
    #  &clientver={int4 clientversion}
    # [&nat=1
    #  &comp=1
    #  &enc={str encoding}
    #  &mtu{int4 mtu value}
    #  &imgserver=1]
    #
    # 200 {str session_key} [{str ip}:{int2 port}] LOGIN ACCEPTED
    #  [{str image server name}]
    # 201 {str session_key} [{str ip}:{int2 port}] LOGIN ACCEPTED - NEW VERSION AVAILABLE
    #  [{str image server name}]
    # 500 LOGIN FAILED
    # 503 CLIENT VERSION OUTDATED
    # 504 CLIENT BANNED - {str reason}
    # 505 ILLEGAL INPUT OR ACCESS DENIED
    # 601 ANIDB OUT OF SERVICE - TRY AGAIN LATER
    def auth
      if @user.nil? || @pass.nil?
        raise ParameterError.new("Need username and password to connect")
      end
      @sid = nil
      replies = nil
      1.upto(3) do |x|
        replies = raw_command("AUTH",
                              :user => @user,
                              :pass => @pass,
                              :protover => PROTOVER,
                              :client => CLIENTNAME,
                              :clientver => CLIENTVER,
                              :nat => @nat ? 1 : 0,
                              :enc => 'UTF-8',
                              :imgserver => 0)
        definitive = process_auth(replies)
        break if @sid || @dead
      end
      if @sid.nil?
        @logger.proto "Authentication failed : #{replies.join("--")}"
        @autheticated = false
        @dead = true
        raise ServerOfflineError.new("Authentication failed - unable to find SID #{replies.join("--")}")
      end
    end

    # UPTIME
    #
    # 208 UPTIME
    #   {int4 udpserver uptime in milliseconds}
    def uptime
      replies = raw_command("UPTIME")
    end

    # FILE
    #   fid={int4 id}
    #  &fmask={hexstr fmask}
    #  &amask={hexstr amask}
    #
    # 220 FILE
    #   {int4 fid}
    #  |(...fields...)
    # 322 MULTIPLE FILES FOUND
    #   {int4 fid 0}
    #  |{int4 fid 1}
    #  |...
    #  |{int4 fid n}
    # 320 NO SUCH FILE
    def file(fid,
             file_fields = DEFAULT_FILE_FFIELDS,
             anime_fields = DEFAULT_FILE_AFIELDS)
      file_any(:fid, [ fid ], file_fields, anime_fields) \
        if(fid && fid.to_i != 0)
    end

    # FILE
    #   size={int8 size}
    #  &ed2k={str ed2khash}
    #  &fmask={hexstr fmask}
    #  &amask={hexstr amask}
    def search_file(name, size, ed2k,
                    file_fields = DEFAULT_FILE_FFIELDS,
                    anime_fields = DEFAULT_FILE_AFIELDS)
      file_any(:ed2k, [ name, size, ed2k ], file_fields, anime_fields) \
        if(size && ed2k && size.to_i != 0 && ed2k != '')
    end

    # FILE
    #   aid={int4 anime id}
    #  &gid={int4 group id}
    #  &epno={int4 episode number}
    #  &fmask={hexstr fmask}
    #  &amask={hexstr amask}
    def file_by_ids(aid, gid, epno,
             file_fields = DEFAULT_FILE_FFIELDS,
             anime_fields = DEFAULT_FILE_AFIELDS)
      file_any(:aid, [ aid, gid, epno ], file_fields, anime_fields) \
        if(aid && gid && epno && aid.to_i != 0 && gid.to_i != 0 && epno.strip != '0' && epno.strip != '00')
    end

    # ANIME
    #    aid={int4 id}
    #  [&amask={hexstr}]
    #
    # 230 ANIME
    #    {int4 aid}
    #   |(...fields...)
    # 330 NO SUCH ANIME
    def anime(aid,
              anime_fields = DEFAULT_ANIME_AFIELDS)
      anime_any(:aid, [ aid ], anime_fields) \
        if(aid && aid.to_i != 0)
    end

    # ANIME
    #   aname={str anime name}
    # [&amask={hexstr}]
    def search_anime(name,
                     anime_fields = DEFAULT_ANIME_AFIELDS)
      anime_any(:aname, [ name ], anime_fields) \
        if(name && name.strip != '')
    end

    # EPISODE
    #    eid={int4 eid}
    #
    # 240 EPISODE
    #   {int4 eid}
    #  |{int4 aid}
    #  |{int4 length}
    #  |{int4 rating}
    #  |{int4 votes}
    #  |{str epno}
    #  |{str eng}
    #  |{str romaji}
    #  |{str kanji}
    #  |{int4 aired}
    # 340 NO SUCH EPISODE
    def episode(eid)
      episode_any(:eid, [ eid ]) \
        if(eid && eid.to_i != 0)
    end

    # EPISODE
    #    aid={int4 anime id}
    #   &epno={int4 episode number}
    def search_episode(aid, epno)
      episode_any(:aidno, [ aid, epno ]) \
        if(aid && epno && aid.to_i != 0 && epno.strip != '0' && epno.strip != '00')
    end

    # GROUP
    #    gid={int4 gid}
    #
    # 250 GROUP
    #    {int4 gid}
    #   |{int4 rating}
    #   |{int4 votes}
    #   |{int4 acount}
    #   |{int fcount}
    #   |{str name}
    #   |{str short}
    #   |{str irc channel}
    #   |{str irc server}
    #   |{str url}
    #   |{str picname}
    # 350 NO SUCH GROUP
    def group(gid)
      group_any(:gid, [ gid ]) \
        if(gid && gid.to_i != 0)
    end
    # GROUP
    #    gname={str group name}
    def search_group(name)
      group_any(:name, [ name ]) \
        if(name && name.strip != '')
    end

    # MYLIST
    #    lid={int4 lid}
    #
    # 221 MYLIST
    #    {int4 lid}
    #   |{int4 fid}
    #   |{int4 eid}
    #   |{int4 aid}
    #   |{int4 gid}
    #   |{int4 date}
    #   |{int2 state}
    #   |{int4 viewdate}
    #   |{str storage}
    #   |{str source}
    #   |{str other}
    #   |{int2 filestate}
    # 321 NO SUCH ENTRY
    def mylist(lid)
      mylist_any(:lid, [ lid ]) \
        if(lid && lid.to_i != 0)
    end

    # MYLIST
    #    fid={int4 fid}
    def mylist_by_fid(fid)
      mylist_any(:fid, [ fid ]) \
        if(fid && fid.to_i != 0)
    end

    # MYLIST
    #    fid={int4 fid}
    def mylist_by_ed2k(size, ed2k)
      mylist_any(:ed2k, [ size, ed2k ]) \
        if(size && ed2k && size.to_i != 0 && ed2k.strip != '')
    end
    
    def mylist_by_aid(aid)
      mylist_any(:aid, [aid]) if (aid && aid.to_i != 0) 
    end  

    # MYLISTADD
    #    fid={int4 fid}
    #  [&state={int2 state}]
    #  [&viewed={boolean viewed}]
    #  [&viewdate={int4 viewdate}]
    #  [&source={str source}]
    #  [&storage={str storage}]
    #  [&other={str other}]
    #  [&edit={boolean edit}]
    #
    # 320 NO SUCH FILE
    # 330 NO SUCH ANIME
    # 350 NO SUCH GROUP
    # 210 MYLIST ENTRY ADDED
    #   {int4 mylist id of new entry}
    # 310 FILE ALREADY IN MYLIST
    # 322 MULTIPLE FILES FOUND
    #   {int4 fid 1}|{int4 fid 2}|...|{int4 fid n}
    # 311 MYLIST ENTRY EDITED
    # 411 NO SUCH MYLIST ENTRY
    def mylist_add(fid, edit = false, viewed = 0, state = :hdd, source = nil, storage = nil)
      return unless(fid && fid.to_i != 0)
      reply = mylist_add_any(:fid, [ fid ], edit, viewed, state, source, storage)
    end

    # MYLISTADD
    #    size={int4 size}
    #   &ed2k={str ed2k hash}
    #  [&state={int2 state}]
    #  [&viewed={boolean viewed}]
    #  [&viewdate={int4 viewdate}]
    #  [&source={str source}]
    #  [&storage={str storage}]
    #  [&other={str other}]
    #  [&edit={boolean edit}]
    def mylist_add_by_ed2k(size, ed2k, edit = false, viewed = 0, state = :hdd, source = nil, storage = nil)
      return unless(size && ed2k && size.to_i != 0 && ed2k.strip != '')
      reply = mylist_add_any(:ed2k, [ size, ed2k ], edit, viewed, state, source, storage)
    end

    # MYLISTDEL
    #    lid={int4 lid}
    #
    # 211 MYLIST ENTRY DELETED
    #    {int4 number of entries}
    # 411 NO SUCH MYLIST ENTRY
    def mylist_del(lid)
      return unless(lid && lid.to_i != 0)
      reply = command('MYLISTDEL',
                      :lid => lid)
      if reply.code == 211
        reply.lines[0].to_i
      else
        nil
      end
    end

    # MYLISTDEL
    #    fid={int4 fid}
    def mylist_del_by_fid(fid)
      return unless(fid && fid.to_i != 0)
      reply = command('MYLISTDEL',
                      :fid => fid)
      if reply.code == 211
        reply.lines[0].to_i
      else
        nil
      end
    end

    # MYLISTDEL
    #    size={int4 size}
    #   &ed2k={str ed2k hash}
    def mylist_del_by_ed2k(size, ed2k)
      return unless(size && ed2k && size.to_i != 0 && ed2k.strip != '')
      reply = command('MYLISTDEL',
                      :size => size,
                      :fid => fid)
      if reply.code == 211
        reply.lines[0].to_i
      else
        nil
      end
    end

    # LOGOUT
    #
    # 203 LOGGED OUT
    # 403 NOT LOGGED IN
    def logout()
      if @sid
        raw_command('LOGOUT')
        @logger.proto "Logged out."
        @authenticated = false
        @sid = nil
      end
    end

    private
    def process_auth(replies)
      if replies.count == 0
        @sid = nil
        @dead = true
      else
        c = replies.select { |r| [ 200, 201 ].include? r.code }
        case c.count
        when 0
          @sid = nil
          @dead = true
          if replies.find { |r| r.code == 500 }
            raise ClientAuthError.new("Authentication failed.")
          end
        when 1
          @sid = find_sid(c[0])
          @authenticated = true
        else
          c.reverse.each_with_index do |r, i|
            sid = find_sid(r)
            if sid
              lr = exchange("UPTIME s=#{sid};tag=radb#{@tag}", @tag)
              @tag += 1
              if lr.find { |r| r.code == 208 }
                @sid = sid
                @authenticated = true
                break
              end
            end
          end
        end
      end
    end

    def file_any(type, pars, file_fields, anime_fields)
      fmask = file_fields.inject(0) do |m, k|
        begin
          m += FILE_FMASKS[k]
        rescue Exception => e
          raise ParameterError.new("FILE file field #{k} unrecognized.")
        end
      end
      amask = anime_fields.inject(0) do |m, k|
        begin
          m += FILE_AMASKS[k]
        rescue Exception => e
          raise ParameterError.new("FILE anime field #{k} unrecognized.")
        end
      end
      reply = case type
      when :fid
        command('FILE',
                :fid   => pars[0],
                :fmask => '%08x' % [ fmask ],
                :amask => '%08x' % [ amask ])
      when :ed2k
        command('FILE',
                :size  => pars[1],
                :ed2k  => pars[2],
                :fmask => '%08x' % [ fmask ],
                :amask => '%08x' % [ amask ])
      when :aid
        command('FILE',
                :aid   => pars[0],
                :gid   => pars[1],
                :epno  => pars[2],
                :fmask => '%08x' % [ fmask ],
                :amask => '%08x' % [ amask ])

      end
      if reply.code == 220
        h = { :file => {}, :anime => {}}
        lr = reply.lines[0].split(/\|/)
        h[:fid] = lr.shift.to_i
        FILE_FMASKS_ORDER.each do |k|
          if file_fields.include? k
            h[:file][k] = lr.shift
          end
        end
        FILE_AMASKS_ORDER.each do |k|
          if anime_fields.include? k
            h[:anime][k] = lr.shift
          end
        end
        h
      else
        nil
      end
    end

    def anime_any(type, pars, anime_fields)
      amask = anime_fields.inject(0) do |m, k|
        begin
          m += ANIME_AMASKS[k]
        rescue Exception => e
          raise ParameterError.new("ANIME field #{k} unrecognized.")
        end
      end
      reply = if type == :aid
        command('ANIME',
                :aid   => pars[0],
                :amask => '%08x' % [ amask ])
      else
        command('ANIME',
                :aname => pars[0],
                :amask => '%08x' % [ amask ])
      end
      if reply.code == 230
        h = { :anime => {}}
        lr = reply.lines[0].split(/\|/)
        h[:aid] = lr.shift.to_i
        ANIME_AMASKS_ORDER.each do |k|
          if anime_fields.include? k
            h[:anime][k] = lr.shift
          end
        end
        h[:anime][:ended] = h[:anime][:dateflags].to_i[4] == 1
        h
      else
        nil
      end
    end

    def episode_any(type, pars)
      reply = if type == :eid
        command('EPISODE',
                :eid   => pars[0])
      else
        command('EPISODE',
                :aid  => pars[0],
                :epno => pars[1])
      end
      if reply.code == 240
        h = { :episode => {}}
        lr = reply.lines[0].split(/\|/)
        h[:eid] = lr.shift.to_i
        EPISODE_FIELDS[1..-1].each do |k|
          h[:episode][k] = lr.shift
        end
        h
      else
        nil
      end
    end

    def group_any(type, pars)
      reply = if type == :gid
        command('GROUP',
                :gid   => pars[0])
      else
        command('GROUP',
                :gname => pars[0])
      end
      if reply.code == 250
        h = { :group => {}}
        lr = reply.lines[0].split(/\|/)
        h[:gid] = lr.shift.to_i
        GROUP_FIELDS[1..-1].each do |k|
          h[:group][k] = lr.shift
        end
        h
      else
        nil
      end
    end

    def mylist_any(type, pars)
      reply = case type
      when :lid
        command('MYLIST',
                :lid   => pars[0])
      when :fid
        command('MYLIST',
                :fid   => pars[0])
      when :ed2k
        command('MYLIST',
                :size   => pars[0],
                :ed2k   => pars[1])
      when :name
        command('MYLIST', 
                :aname => pars[0])
      when :aid
        command('MYLIST',
                :aid => pars[0])                    
      end
      case reply.code
      when 221
        mylist_response(reply, MYLIST_FIELDS).tap {|h| 
          h[:mylist][:lid] = h[:mylist][:lid].to_i
          h[:mylist][:single_episode] = true
      }
      when 312
        mylist_response(reply, MULTI_MYLIST_FIELDS).tap {|h| h[:mylist][:single_episode] = false}
      else  
        nil
      end
    end
    
    def mylist_response(reply, fields)
      {:mylist => {}.tap do |h|
        lr = reply.lines[0].split(/\|/)
        fields.each do |k|
          h[k] = lr.shift
        end
      end }  
    end  

    def mylist_add_any(type, pars, edit = false, viewed = 0, state = :hdd, source = nil, storage = nil)
      h = { :viewed => viewed,
            :state => MYLIST_STATES[state],
            :source => source,
            :storage => storage,
            :edit => edit }
      case type
      when :fid
        h[:fid] = pars[0]
      when :ed2k
        h[:size] = pars[0]
        h[:ed2k] = pars[1]
      end

      reply = command('MYLISTADD', h)
      case reply.code
      when 210
        [:added, reply.lines[0].to_i]
      when 310
        h = {}
        lr = reply.lines[0].split(/\|/)
        h[:lid] = lr.shift.to_i
        [:exists, h[:lid]]
      when 311
        [:edited, nil]
      when 411
        [:notfound, nil]
      else
        nil
      end
    end

    def command(cmd, params = {})
      raise ServerOfflineError.new("Trying to send a command to a dead server") if @dead
      r = nil
      loop do
        if !@authenticated && !['AUTH','LOGOUT','PING'].include?(cmd) 
          auth
        end
        params[:s] = @sid if @sid
        params[:tag] = "radb#{@tag}"
        p = cmd + ' ' + params.collect do |k, v|
          "#{k}=#{AniDBUDP.escape(v)}" if v
        end.compact.join('&')
        begin
          lr = exchange(p, @tag)
          r = parse_reply(lr, @tag)
        rescue ServerOfflineError,
               ClientBannedError => e
          @sid = nil
          @autenticated = false
          @connected = false
          @dead = true
          @logger.proto e.message
          raise e
        rescue ClientAuthError,
               ClientSessionError => e
          @authenticated = false
          @sid = nil
          r = nil
        end
        @tag += 1
        break if r
      end
      r
    end
    public :command

    def raw_command(cmd, params = {})
      raise ServerOfflineError.new("Trying to send a command to a dead server") if @dead
      params[:s] = @sid if @sid
      params[:tag] = "radb#{@tag}"
      p = cmd + ' ' + params.collect do |k, v|
        "#{k}=#{AniDBUDP.escape(v)}" if v
      end.compact.join('&')
      begin
        lr = exchange(p, @tag)
      rescue ServerOfflineError,
             ClientBannedError => e
        @sid = nil
        @autenticated = false
        @connected = false
        @dead = true
        lr = []
      end
      @tag += 1
      lr
    end

    def exchange(cmd, tag)
      @last_command = cmd
      lr = []
      found = false
      tries = 1
      loop do
        send cmd
        Timeout.timeout(10, ServerTimeout) do
          begin
            msg = recv
            r = Reply.new(msg)
            lr << r
            found = true # (r.code == 555 || r.tag.nil? || r.tag == tag)
          rescue ServerTimeout => e
            tries += 1
          end
        end
        break if found || tries > 2
      end
      if lr.empty?
        raise ServerOfflineError.new("AniDB server does not respond")
      else
        Timeout.timeout(2.1, ServerTimeout) do
          begin
            loop do
              msg = recv
              r = Reply.new(msg)
              lr << r
            end
          rescue ServerTimeout => e
          end
        end
        if $DEBUG
          @logger.proto(tr)
        end
        lr
      end
    end

    def send(c)
      @logger.proto ">>> #{c}"
      @sock.puts(c)
      @sock.flush
      @last_activity = Time.now
    end

    def recv()
      fmsg, send = @sock.recvfrom(1400)
      @sock.flush
      @last_activity = Time.now
      fmsg.chomp!
      @logger.proto "<<< #{fmsg.gsub(/\n/, "\n << ")}"
      r = fmsg.split(/\n/)
      r.each { |lr| AniDBUDP.unescape!(lr) }
      r
    end

    def parse_reply(lr, tag)
      r = lr.find { |e| e.tag == tag }
      r = lr.shift unless r
      lr.delete(r)
      lr.each do |e|
        @logger.proto "Discarding duplicate packet (#{e.inspect})."
      end
      @last_reply = r
      case r.code
      when 200..499
      when 500, 501
        raise ClientAuthError.new("Authentication failed in reply to #{@last_command}")
      when 502, 505 # Conflict in the wiki
        raise ClientAccessError.new("Access denied in reply to #{@last_command}")
      when 503
        raise ClientOutdatedError.new("Client version too old")
      when 504
        reason = r.text.sub(/^.*-/, '').strip
        raise ClientBennedError.new("Client has been banned - #{reason}")
      when 506
        raise ClientSessionError.new("Wrong session key in reply to #{@last_command}")
      when 555
        raise BannedError.new("User has been banned - #{r.lines.join(' ')}")
      when 500..599
        raise ClientError.new("Client error #{r} in reply to #{@last_command}")
      when 600..699
        raise ServerError.new("Server error #{r}")
      when nil
        raise Error.new("Unparseable response : #{r}")
      else
        raise Error.new(r.to_s)
      end
      r
    end

    def find_sid(reply)
      if @nat
        if reply.text =~ /^([^\s]+) ([0-9.:]+)/
          sid = $1
        end
      else
        if reply.text =~ /^([^\s]+) /
          sid = $1
        end
      end
      sid
    end
  end
end
