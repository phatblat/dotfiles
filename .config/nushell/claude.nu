# Run local claude installation or install if missing
def claude [...args] {
    if (".claude/local/claude" | path exists) {
        ^.claude/local/claude ...$args
    } else {
        print "Claude not found locally. Installing..."
        mise exec npm:@anthropic-ai/claude-code -- claude migrate-installer

        # After installation, run the command if it now exists
        if (".claude/local/claude" | path exists) {
            ^.claude/local/claude ...$args
        } else {
            print "Installation may have failed. Please check the output above."
            exit 1
        }
    }
}