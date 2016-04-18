
require 'mail'
require 'mail/fields'

module Mail
  class DkimField < StructuredField
    FIELD_NAME = 'dkim-signature'
    CAPITALIZED_FIELD = 'DKIM-Signature'

    def initialize(value = nil, charset = 'utf-8')
      self.charset = charset
      value = strip_field(FIELD_NAME, value) if respond_to?(:strip_field)
      super(CAPITALIZED_FIELD, value, charset)
      self
    end

    def encoded
      "#{CAPITALIZED_FIELD}: #{do_wrap(prepend=CAPITALIZED_FIELD.length + 2)}\r\n"
    end

    def decoded
      value
    end

    # does not work if there are already spaces around = in tag list
    def do_wrap(prepend=0)
      words = value.split(/[ \t]/)
      custom_split_words = []
      words.each do |word|
        if word.start_with?("h=")
          # header field list can be folded at :
          custom_split_words.concat(word.split(/(?<=:)/))
        elsif word.start_with?("b=") or word.start_with?("bh=")
          # base64 encoded fields can be folded anywhere. Use fixed 
          # length substrings
          offset = 0
          len = 67
          while !word[offset].nil?
            custom_split_words <<= word[offset, len]
            offset += len
          end
        else
          custom_split_words <<= word
        end
      end
      #the rest of this is a simplified version of wrap from 
      # mail/fields/unstructured_field.rb
      folded_lines = []
      while !custom_split_words.empty?
        limit = 78 - prepend
        line = ""
        first_word = true
        while !custom_split_words.empty?
          break unless word = custom_split_words.first
          break if !line.empty? && (line.length + word.length + 1 > limit)
          # Remove the word from the queue ...
          custom_split_words.shift
          # Add word separator
          if first_word
            first_word = false
          else
            line << " "
          end
          line << word
        end
        folded_lines << line
        prepend = 0
      end
      folded_lines.join("\r\n    ")
    end
  end
end
