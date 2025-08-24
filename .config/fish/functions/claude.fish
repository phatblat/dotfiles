function claude \
    --description='Run local claude installation or install if missing'

    if test -e .claude/local/claude
        .claude/local/claude $argv
    else
        echo "Claude not found locally. Installing..."
        mise exec npm:@anthropic-ai/claude-code -- claude migrate-installer
        
        # After installation, run the command if it now exists
        if test -e .claude/local/claude
            .claude/local/claude $argv
        else
            echo "Installation may have failed. Please check the output above."
            return 1
        end
    end
end
