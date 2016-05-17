module Box
  module Adapters
    class File
      def initialize(*args); end

      def self.setup(*args)
        return new(*args)
      end
      def dump_keys
        "{}"
      end
      def ini_letter(name)
        "ini"
      end
      def INI;end
      def HIA;end
      def HPB;end
      def STA(from, to)
        ::File.read( ::File.expand_path("~/sta.mt940"))
      end

      def HAC(from, to)
        ::File.open( ::File.expand_path("~/hac.xml"))
      end

      def CD1(pain)
        ["TRX#{SecureRandom.hex(6)}", "N#{SecureRandom.hex(6)}"]
      end
      alias :CDD :CD1
      alias :CDB :CD1
      alias :CCT :CD1
    end
  end
end
