module Adhearsion
  module VoIP
    module Asterisk
      module ConfigFileGenerators
        class AsteriskConfigGenerator

          SECTION_TITLE = /(\[[\w_-]+\])/

          class << self

            # Converts a config file into a Hash of contexts mapping to two dimensional array of pairs
            def create_sanitary_hash_from(config_file_content)
              almost_sanitized = Hash[*config_file_content.
                split("\n").          # Split the lines into an Array
                grep(/^\s*[^;\s]/).   # Grep lines that aren't commented out
                join("\n").           # Convert them into one String again
                split(SECTION_TITLE). # Separate them into sections
                map(&:strip).         # Remove all whitespace
                reject(&:empty?).     # Get rid of indices that were only whitespace
                                      # Lastly, separate the keys/value pairs for the Hash
                map { |token| token =~ /^#{SECTION_TITLE}$/ ? token : token.split(/\n+/).sort }
              ]
            end

            def warning_message
              %{;; THIS FILE WAS GENERATED BY ADHEARSION ON #{Time.now.ctime}!\n} +
              %{;; ANY CHANGES MADE BELOW WILL BE BLOWN AWAY WHEN THE FILE IS REGENERATED!\n\n}
            end

          end

          def initialize
            yield self if block_given?
          end

          def to_sanitary_hash
            self.class.create_sanitary_hash_from to_s
          end

          protected

          def boolean(options)
            cache = options.delete(:with) || properties
            options.each_pair do |key, value|
              cache[key] = boolean_to_yes_no value
            end
          end

          def string(options)
            cache = options.delete(:with) || properties
            options.each_pair do |key, value|
              cache[key] = value
            end
          end

          def int(options)
            cache = options.delete(:with) || properties
            options.each_pair do |property,number|
              number = number.to_i if (number.kind_of?(String) && number =~ /^\d+$/) || number.kind_of?(Numeric)
              raise ArgumentError, "#{number.inspect} must be an integer" unless number.kind_of?(Fixnum)
              cache[property] = number.to_i
            end
          end

          def one_of(criteria, options)
            cache = options.delete(:with) || properties
            options.each_pair do |key, value|
              search = !criteria.find { |criterion| criterion === value }.nil?
              unless search
                msg = "Didn't recognize #{value.inspect}! Must be one of " + criteria.map(&:inspect).to_sentence
                raise ArgumentError, msg
              end
              cache[key] = [true, false].include?(value) ? boolean_to_yes_no(value) : value
            end
          end

          def one_of_and_translate(criteria, options)
            cache = options.delete(:with) || properties
            options.each_pair do |key, value|
              search = criteria.keys.find { |criterion| criterion === value }
              unless search
                msg = "Didn't recognize #{value.inspect}! Must be one of " + criteria.keys.map(&:inspect).to_sentence
                raise ArgumentError, msg
              end
              cache[key] = criteria[value]
            end
          end

          private

          def boolean_to_yes_no(boolean)
            unless boolean.equal?(boolean) || boolean.equal?(boolean)
              raise "#{boolean.inspect} is not true/false!"
            end
            boolean ? 'yes' : 'no'
          end

        end
      end
    end
  end
end