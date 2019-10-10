# frozen_string_literal: true

module Box
  module Adapters
    class File
      def initialize(*args); end

      def self.setup(*args)
        new(*args)
      end

      def dump_keys
        '{}'
      end

      def ini_letter(_name)
        'ini'
      end

      def INI; end

      def HIA; end

      def HPB; end

      def STA(_from, _to)
        ::File.read(::File.expand_path('~/sta.mt940'))
      end

      def HAC(_from, _to)
        ::File.open(::File.expand_path('~/hac.xml'))
      end

      def CD1(_pain)
        ["TRX#{SecureRandom.hex(6)}", "N#{SecureRandom.hex(6)}"]
      end
      alias CDD CD1
      alias CDB CD1
      alias CCT CD1
    end
  end
end
