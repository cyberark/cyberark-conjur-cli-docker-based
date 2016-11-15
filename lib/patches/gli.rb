# Patch GLI's help formatters so they don't show subcommands that are
# supposed to be hidden.
module CommandHelpFormatPatch
  def format
    @command.commands.reject! {|k,c| c.nodoc}
    @command.commands_declaration_order.reject! {|c| c.nodoc}

    super
  end
end

module HelpCompletionFormatPatch
  def format
    name = @args.shift
    
    base = @command_finder.find_command(name)
    base = @command_finder.last_found_command if base.nil?
    base = @app if base.nil?
    
    prefix_to_match = @command_finder.last_unknown_command
    
    base.commands.reject {|_,c| c.nodoc}.values.map { |command|
      [command.name,command.aliases]
    }.flatten.compact.map(&:to_s).sort.select { |command_name|
      prefix_to_match.nil? || command_name =~ /^#{prefix_to_match}/
    }.join("\n")
  end
end

GLI::Commands::HelpModules::CommandHelpFormat.send(:prepend, CommandHelpFormatPatch)
GLI::Commands::HelpModules::HelpCompletionFormat.send(:prepend, HelpCompletionFormatPatch)
