#
# Copyright (C) 2015 Conjur Inc.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
require 'conjur/cli'
require 'shellwords'

# Class for generating `conjur` bash completions
class Conjur::CLI::Complete
  def initialize line, point=nil
    @line = line
    @words = tokenize_cmd @line
    point ||= @line.length
    @current_word=(tokenize_cmd @line.slice(0,point)).length-1
    # fix arrays for empty "current word"
    # ie "conjur group list "
    if @line.match(/[ =]$/)
      @words << ''
      @current_word += 1
    end
    @command, index = walk_to_subcommand @words, @current_word
    @flag_words, @arg_words = classify_words @words.drop(index)
  end

  # Finds the most specific subcommand in {Conjur::CLI.commands}
  #
  # @param words [Array] the words being completed
  # @param current_word [Integer] the index of the word being completed
  # @return [Conjur::CLI::Command, Integer] the GLI object of the subcommand,
  #   then its index in `words`
  def walk_to_subcommand words, current_word
    index = 1
    command = Conjur::CLI
    loop do
      word = words[index]
      sub = subcommands command
      if sub.has_key? word.to_sym and index < current_word
        command = command.commands[word.to_sym]
        index += 1
      else
        break
      end
    end
    return command, index
  end

  # Find words belonging to flags and arguments
  #
  # @param words [Array] the words being classified
  # @return [Array, Array] the flags and their associated values, then
  #   the arguments
  def classify_words words
    flags = []
    args = []
    while not words.empty?
      if words.first.start_with? '-'
        flags.push [words.first, words.drop(1).first]
        words = words.drop(1)
      elsif words.first.length
        args.push words.first
      end
      words = words.drop(1)
    end
    return flags, args
  end

  # Generate array of subcommands for which documentation is not hidden
  #
  # @param cmd [Conjur::CLI::Command] the command to search
  # @return [Array] the subcommands
  def subcommands cmd
    cmd.commands.select do |_, c|
      c.nodoc.nil?
    end
  end

  # Split line according on spaces and after '='
  #
  # @param line [String] to split
  # @return [Array] the substrings
  def tokenize_cmd line
    line.split(/ |(?<==)/)
  end

  def complete kind
    case kind.to_s.downcase
    when 'resource'
      complete_resource
    when 'role'
      complete_role
    when 'file'
      complete_file @words[@current_word]
    when 'hostname'
      complete_hostname
    else
      complete_resource kind if [
        'group',
        'user',
        'variable',
        'host',
        'layer',
      ].member? kind
    end or []
  end
  
  # generate completions for the switches and flags of a Conjur::CLI::Command
  #
  # @param cmd [Conjur::CLI::Command] command for which to search for flags
  #   and switches
  # @return [Array] completion words
  def complete_flags cmd
    cmd.flags.values.map do |flag|
      candidates = [flag.name]
      candidates += flag.aliases if flag.aliases
      candidates.map do |c|
        "-#{'-' if c.length > 1}#{c}#{'=' if c.length > 1}"
      end
    end + cmd.switches.values.map do |switch|
      candidates = [switch.name]
      candidates += switch.aliases if switch.aliases
      candidates.map do |c|
        "-#{'-' if c.length > 1}#{c}"
      end
    end
  end

  def complete_args cmd, prev, num_args
    kind=nil
    if prev.start_with? '-'
      flag_name=prev.match(/--?([^=]+)=?/)[1].to_sym
      flag = cmd.flags[flag_name]
      desc = flag.argument_name
      kind = desc.to_s.downcase
    else
      desc = cmd.arguments_description if defined? cmd.arguments_description
      kind = desc.to_s.downcase.split[num_args]
    end
    complete kind
  end

  def complete_resource resource_kind=nil
    Conjur::Command.api.resources({kind: resource_kind})
      .map do |r|
      res = Resource.new r.attributes['id']
      if resource_kind
        res.name
      else
        res.shellescape
      end
    end
  end

  def complete_role
    Conjur::Command.api.current_role.all
      .map do |r| Resource.new(r.roleid).shellescape end
  end

  def complete_file word
    # use Bash's file completion for compatibility
    `bash -c "compgen -f #{word}"`.shellsplit
  end

  def complete_hostname
    `bash -c "compgen -A hostname"`.shellsplit
  end

  def to_ary
    word = @words[@current_word]
    prev = @words[@current_word-1]
    if word.start_with? '-'
      complete_flags @command
    else
      (subcommands @command).keys.map(&:to_s) +
        (complete_args @command, prev, @arg_words.length)
    end.flatten
      .select do |candidate|
      candidate.start_with? word end
      .map do |candidate|
      "#{candidate}#{' ' if not candidate.end_with? '='}" end
  end
end

class Conjur::CLI::Complete::Resource
  attr_reader :account, :kind, :name
  attr_writer :include_account
  def initialize resource_string, include_account=false
    @include_account = include_account
    fields = resource_string.split ':'
    raise ArgumentError.new "too many fields (#{args.first})" if fields.length > 3
    fields.unshift nil while fields.length < 3
    @account, @kind, @name = fields
  end

  def to_ary
    [(@account if @include_account), @kind, @name].reject { |a| a.nil? }
  end

  def to_s
    to_ary.join ':'
  end

  def shellescape
    to_ary.join '\:'
  end
end
