module OpenPGP
  ##
  # OpenPGP ASCII Armor utilities.
  #
  # @see http://tools.ietf.org/html/rfc4880#section-6.2
  module Armor
    ##
    # @see http://tools.ietf.org/html/rfc4880#section-6.2
    module Markers
      MESSAGE           = 'MESSAGE'
      PUBLIC_KEY_BLOCK  = 'PUBLIC KEY BLOCK'
      PRIVATE_KEY_BLOCK = 'PRIVATE KEY BLOCK'
      SIGNATURE         = 'SIGNATURE'
    end

    ##
    # @see http://tools.ietf.org/html/rfc4880#section-6.2
    def self.header(marker)
      "-----BEGIN PGP #{marker.to_s.upcase}-----"
    end

    ##
    # @see http://tools.ietf.org/html/rfc4880#section-6.2
    def self.footer(marker)
      "-----END PGP #{marker.to_s.upcase}-----"
    end

    ##
    # @see http://tools.ietf.org/html/rfc4880#section-6
    # @see http://tools.ietf.org/html/rfc4880#section-6.2
    # @see http://tools.ietf.org/html/rfc2045
    def self.encode(data, marker = 'MESSAGE', headers = {})
      text = StringIO.new
      text << self.header(marker)     << "\n"
      headers.each { |key, value| text << "#{key}: #{value}\n" }
      text << "\n" << Base64.encode64(data)
      text << "="  << Base64.encode64([OpenPGP.crc24(data)].pack('N')[1, 3])
      text << self.footer(marker)     << "\n"
      text.string
    end

    ##
    # @see http://tools.ietf.org/html/rfc4880#section-6
    # @see http://tools.ietf.org/html/rfc2045
    def self.decode(text, marker = nil)
      data, crc, state = StringIO.new, nil, :begin
      text.each_line do |line|
        line.chomp!
        case state
          when :begin
            case line
              when /^-----BEGIN PGP ([^-]+)-----$/
                state = :head if marker.nil? || marker.to_s.upcase == $1
            end
          when :head
            state = :body if line =~ /^\s*$/
          when :body
            case line
              when /^=(....)$/
                crc = ("\0" << Base64.decode64($1)).unpack('N').first
                state = :end
              when /^-----END PGP ([^-]+)-----$/
                state = :end
              else
                data << Base64.decode64(line)
            end
          when :end
            break
        end
      end
      data.string
    end
  end

  include Armor::Markers
end
