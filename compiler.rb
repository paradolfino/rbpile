#!/usr/bin/env ruby
class Tokenizer
    TOKEN_TYPES = [
        [:def, /\bdef\b/],
        [:end, /\bend\b/],
        [:identifier, /\b[a-zA-Z]+\b/],
        [:integer, /\b[0-9]+\b/],
        [:oparen, /\(/],
        [:cparen, /\)/],
        ]
    def initialize(code)
       @code = code 
    end
    
    def tokenize
        tokens = []
        until @code.empty?
            tokens << tokenize_once
            @code = @code.strip
        end
        tokens
    end
    
    def tokenize_once
            TOKEN_TYPES.each do |type, re|
                re = /\A(#{re})/
                if @code =~ re
                    value = $1
                    @code = @code[value.length..-1]
                    return Token.new(type, value)
                end
                
            end
        raise RuntimeError.new("Couldn't match token on #{@code.inspect}")
    end
    
end

class Parser
   def initialize(tokens)
      @tokens = tokens 
   end
   
   def parse
       parse_def
   end
   
   def parse_def
       consume(:def)
      name = consume(:identifier)
      arg_names = parse_arg_names
      body = parse_expr
      consume(:end)
   end
   
   def parse_arg_names
       consume(:oparen)
       consume(:cparen)
   end
   
   def parse_expr
       parse_int
   end
   
   def parse_int
      consume(:integer) 
   end
   
   def consume(expected_type)
      token = @tokens.shift 
      if token.type == expected_type
          token
      else
          raise RuntimeError.new("Expected token type #{exoected_type.inspect} but got #{token.type.inspect}")
      end
   end
end

Token = Struct.new(:type, :value)

tokens = Tokenizer.new(File.read("test.src")).tokenize

puts tokens.map(&:inspect).join("\n")

tree = Parser.new(token).parse

p tree