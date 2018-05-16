#!/usr/bin/env ruby
class Tokenizer
    TOKEN_TYPES = [
        [:def, /\bact\b/],
        [:begin, /{/],
        [:end, /}/],
        [:identifier, /\b[a-zA-Z]+\b/],
        [:integer, /\b[0-9]+\b/],
        [:oparen, /\(/],
        [:cparen, /\)/],
        [:comma, /,/],
        [:operator, /\+|-|\*|\/|=|>|<|>=|<=|&|\||%|!/],
        [:break, /[\r\n]+/]
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
        name = consume(:identifier).value
        arg_names = parse_arg_names
        consume(:begin)
        body = []
        while !chk_nxt(:end)
            body << parse_expr
        end
        consume(:end)
        DefNode.new(name, arg_names, body)
   end
   
   def parse_arg_names
       arg_names = []
       consume(:oparen)
       if chk_nxt(:identifier)
          arg_names << consume(:identifier).value
            while chk_nxt(:comma)
                consume(:comma)
                arg_names << consume(:identifier).value
            end
       end
       consume(:cparen)
       arg_names
   end
   
   def parse_expr
        
        if chk_nxt(:integer)
            parse_int
        elsif chk_nxt(:operator)
            parse_add
        elsif chk_nxt(:identifier) && chk_nxt(:oparen, 1)
            parse_call
        else
            parse_var_ref
        end
   end
   
   def parse_int
      IntegerNode.new(consume(:integer).value.to_i)
   end
   
   def parse_add
       OperatorNode.new(consume(:operator)).value
   end
   
   def parse_call
      name = consume(:identifier).value
      arg_exprs = parse_arg_exprs
      
      CallNode.new(name, arg_exprs)
   end
   
   def parse_arg_exprs
       arg_exprs = []
       consume(:oparen)
       if !chk_nxt(:cparen)
          arg_exprs << parse_expr
            while chk_nxt(:comma)
                consume(:comma)
                arg_exprs << parse_expr
            end
       end
       consume(:cparen)
       arg_exprs
   end
   
   def parse_var_ref
       VarRefNode.new(consume(:identifier).value)
   end
   
   def consume(expected_type)

      token = @tokens.shift 
      if token.type == expected_type
          token
      else
          raise RuntimeError.new("Expected token type #{expected_type.inspect} but got #{token.type.inspect}")
      end
   end
   
   def chk_nxt(expected_type, offset=0)
       @tokens.fetch(offset).type == expected_type
   end
   
end

class Generator
   def generate(node)
        case node
        when DefNode
            node.body.map! { |b| b.to_a }.each { |b| b.shift }
            "def %s %s %s end" % [
                node.name, 
                node.arg_names.join(","), 
                node.body.join(" ")
            ]
        when CallNode
            "%s %s" % [
                    node.name,
                    node.arg_exprs.map { |ex| generate(ex) }.join(",")
                ]
        when VarRefNode
            node.value
        when IntegerNode
            node.value
        when OperatorNode
            node.value
        else
            raise RuntimeError.new("Unexpected node type: #{node.class}")    
        end
   end
end

Token = Struct.new(:type, :value)
DefNode = Struct.new(:name, :arg_names, :body)
IntegerNode = Struct.new(:value)
OperatorNode = Struct.new(:value)
CallNode = Struct.new(:name, :arg_exprs)
VarRefNode = Struct.new(:value)
tokens = Tokenizer.new(File.read("test.src")).tokenize
p tokens
tree = Parser.new(tokens).parse
generated = Generator.new.generate(tree)
puts generated
