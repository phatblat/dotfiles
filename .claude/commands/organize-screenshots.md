# Organize Desktop Screenshots into Obsidian Vault

Organize macOS Desktop screenshot files into the Obsidian vault ("2nd Brain") by moving them, viewing them, writing brief descriptions, and embedding them in the corresponding daily notes.

## Objective

Move any screenshot PNG files from the macOS Desktop (`~/Desktop/Screenshot *.png`) into the Obsidian vault at `/Users/phatblat/Documents/2nd Brain/`, then add Obsidian image embeds with brief descriptions to the matching daily notes.

## Steps

### 1. List Desktop Screenshots
Use `mcp__Control_your_Mac__osascript` to run:
```bash
ls -1 ~/Desktop/Screenshot\ 2*.png 2>/dev/null
```
If no screenshots are found, report "No screenshots on Desktop" and stop.

### 2. Read Daily Notes for Matching Dates
For each unique date found in the screenshot filenames (format: `Screenshot YYYY-MM-DD at HH.MM.SS.png`), read the corresponding daily note from the VM mount at `/sessions/peaceful-epic-bell/mnt/2nd Brain/Daily Notes/`. Daily note filenames use the format `YYYY-MM-DD Weekday.md`. Identify which screenshots are already embedded in notes (look for `![[Screenshot YYYY-MM-DD at HH.MM.SS.png]]` patterns).

### 3. Move Uncaptured Screenshots to Vault
For screenshots NOT already referenced in daily notes, use `mcp__Control_your_Mac__osascript` to move them:
```bash
mv ~/Desktop/'Screenshot YYYY-MM-DD at HH.MM.SS.png' '/Users/phatblat/Documents/2nd Brain/'
```
Leave screenshots that are already captured in notes on the Desktop.

### 4. View Screenshots via Thumbnail Pipeline
Since the VM mount is a snapshot and won't reflect Mac-side file moves, use this thumbnail transfer pipeline to view each screenshot:

For batches of screenshots, use `mcp__Control_your_Mac__osascript`:
```bash
cd '/Users/phatblat/Documents/2nd Brain' && for f in 'Screenshot YYYY-MM-DD at HH.MM.SS.png' ...; do
  name=$(echo "$f" | sed 's/Screenshot 2026-//' | sed 's/ at /_/' | sed 's/.png//');
  sips -Z 400 -s format jpeg -s formatOptions 50 "$f" --out "/tmp/${name}.jpg" 2>/dev/null;
  echo "===FILE:${name}===";
  base64 -i "/tmp/${name}.jpg";
done
```

If the osascript output exceeds max tokens and is saved to a file, decode it with Python:
```python
import json, base64, os
raw = json.load(open("PATH_TO_SAVED_FILE"))
text = raw[0]['text']
parts = text.split('===FILE:')
for part in parts[1:]:
    idx = part.index('===')
    name = part[:idx].strip()
    rest = part[idx+3:]
    b64data = ''.join(rest.strip().split())
    outpath = f'/sessions/peaceful-epic-bell/thumbs/{name}.jpg'
    with open(outpath, 'wb') as f:
        f.write(base64.b64decode(b64data))
```

Then use the `Read` tool to view each decoded JPEG thumbnail.

### 5. Add Embeds with Descriptions to Daily Notes
For each screenshot, write a brief one-line description of what it shows, then add it to the corresponding daily note. Use the `Edit` tool to insert at a contextually appropriate location in the note (near related content sections).

Format:
```markdown
Brief description of what the screenshot shows
![[Screenshot YYYY-MM-DD at HH.MM.SS.png]]
```

Place screenshots near relevant sections based on:
- Timestamp alignment with meeting times or work sections
- Visual content matching note topics (e.g., AWS screenshots near infrastructure sections)
- Chronological order within sections when no better context exists

### 6. Verify
After updating all daily notes, re-read each modified note to confirm the embeds were placed correctly and descriptions are accurate.

## Constraints
- Use Obsidian wikilink embed syntax: `![[filename]]`
- Keep descriptions concise (one line, no markdown formatting)
- Do not modify existing content in daily notes — only insert new screenshot embeds
- Process screenshots in chronological order by date, then by time
- Batch osascript calls to minimize round-trips (group by date)
- The VM mount path is `/sessions/peaceful-epic-bell/mnt/2nd Brain/`
- The Mac vault path is `/Users/phatblat/Documents/2nd Brain/`
- Thumbnails working directory: `/sessions/peaceful-epic-bell/thumbs/` (create if needed)
