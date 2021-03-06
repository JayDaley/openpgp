module OpenPGP
  ##
  # GNU Privacy Guard (GnuPG) wrapper.
  #
  # @see http://www.gnupg.org/
  class GnuPG
    class Error < IOError; end

    OPTIONS = {
      :batch                 => true,
      :quiet                 => true,
      :no_verbose            => true,
      :no_tty                => true,
      :no_permission_warning => true,
      :no_random_seed_file   => true,
    }

    attr_accessor :where
    attr_accessor :options

    def initialize(options = {})
      @where   = '/usr/bin/env gpg' # FIXME
      @options = OPTIONS.merge!(options)
    end

    ##
    # Determines if GnuPG is available.
    def available?
      !!version
    end

    ##
    # Returns the GnuPG version number.
    def version
      exec(:version).readline =~ /^gpg \(GnuPG\) (.*)$/ ? $1 : nil
    end

    ##
    # Generates a new OpenPGP keypair and stores it GnuPG's keyring.
    def gen_key(info = {})
      stdin, stdout, stderr = exec3(:gen_key) do |stdin, stdout, stderr|
        stdin.puts "Key-Type: #{info[:key_type]}"           if info[:key_type]
        stdin.puts "Key-Length: #{info[:key_length]}"       if info[:key_length]
        stdin.puts "Subkey-Type: #{info[:subkey_type]}"     if info[:subkey_type]
        stdin.puts "Subkey-Length: #{info[:subkey_length]}" if info[:subkey_length]
        stdin.puts "Name-Real: #{info[:name]}"              if info[:name]
        stdin.puts "Name-Comment: #{info[:comment]}"        if info[:comment]
        stdin.puts "Name-Email: #{info[:email]}"            if info[:email]
        stdin.puts "Expire-Date: #{info[:expire_date]}"     if info[:expire_date]
        stdin.puts "Passphrase: #{info[:passphrase]}"       if info[:passphrase]
        stdin.puts "%commit"
      end
      stderr.each_line do |line|
        if (line = line.chomp) =~ /^gpg: key ([0-9A-F]+) marked as ultimately trusted/
          return $1.to_i(16) # the key ID
        end
      end
      return nil
    end

    ##
    # Exports a specified key from the GnuPG keyring.
    def export(key_id = nil)
      OpenPGP::Message.parse(exec([:export, *[key_id].flatten]).read)
    end

    ##
    # Imports a specified keyfile into the GnuPG keyring.
    def import()
      # TODO
    end

    ##
    # Returns an array of key IDs/titles of the keys in the public keyring.
    def list_keys()
      # TODO
    end

    ##
    # Encrypts the given plaintext to the specified recipients.
    def encrypt(plaintext, options = {})
      # TODO
    end

    ##
    # Decrypts the given ciphertext using the specified key ID.
    def decrypt(ciphertext, options = {})
      # TODO
    end

    ##
    # Makes an OpenPGP signature.
    def sign()
      # TODO
    end

    ##
    # Makes a clear text OpenPGP signature.
    def clearsign()
      # TODO
    end

    ##
    # Makes a detached OpenPGP signature.
    def detach_sign()
      # TODO
    end

    ##
    # Verifies an OpenPGP signature.
    def verify()
      # TODO
    end

    ##
    # Executes a GnuPG command, yielding the standard input and returning
    # the standard output.
    def exec(command, options = {}, &block) #:yields: stdin
      exec4(command, options) do |pid, stdin, stdout, stderr|
        block.call(stdin) if block_given?
        stdin.close_write
        pid, status = Process.waitpid2(pid)
        raise Error, stderr.read.chomp if status.exitstatus.nonzero?
        stdout
      end
    end

    ##
    # Executes a GnuPG command, yielding and returning the standard input,
    # output and error.
    def exec3(command, options = {}, &block) #:yields: stdin, stdout, stderr
      exec4(command, options) do |pid, stdin, stdout, stderr|
        block.call(stdin, stdout, stderr) if block_given?
        stdin.close_write
        pid, status = Process.waitpid2(pid)
        raise Error, stderr.read.chomp if status.exitstatus.nonzero?
        [stdin, stdout, stderr]
      end
    end

    ##
    # Executes a GnuPG command, yielding the process identifier as well as
    # the standard input, output and error.
    def exec4(command, options = {}, &block) #:yields: pid, stdin, stdout, stderr
      require 'rubygems'
      require 'open4'
      block.call(*Open4.popen4(cmdline(command, options)))
    end

    protected

      ##
      # Constructs the GnuPG command-line for use with +exec+.
      def cmdline(command, options = {})
        command = [command].flatten
        cmdline = [where]
        cmdline += @options.merge(options).map { |k, v| !v ? nil : "#{option(k)} #{v == true ? '' : v.to_s}".rstrip }.compact
        cmdline << option(command.shift)
        cmdline += command
        cmdline.flatten.join(' ').strip
      end

      ##
      # Translates Ruby symbols into GnuPG option arguments.
      def option(option)
        "--" << option.to_s.gsub('_', '-')
      end
  end
end
