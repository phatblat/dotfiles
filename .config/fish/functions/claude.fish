function claude \
    --description='Run local claude installation or install if missing'

    set -l claude_path ~/.claude/local/claude

    if test -e $claude_path
        $claude_path $argv
    else
        echo "Claude not found locally. Installing..."
        mise exec npm:@anthropic-ai/claude-code -- claude migrate-installer
        
        # After installation, run the command if it now exists
        if test -e $claude_path
            $claude_path $argv
        else
            echo "Installation may have failed. Please check the output above."
            return 1
        end
    end
end
