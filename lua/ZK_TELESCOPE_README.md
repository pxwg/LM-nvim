# ZK Telescope - Metadata-Enhanced Note Search

## Overview

The ZK Telescope plugin extends the original ZK note-taking system with comprehensive metadata search capabilities. It allows you to add and search notes using aliases, abstracts, keywords, and tags.

## Metadata Format

Add metadata at the beginning of your note files using block comments:

```typst
/* Metadata:
Aliases: ZK Note, Neovim Note, Zettelkasten Example
Abstract: This is a note about ZK and Neovim tools with enhanced search capabilities.
Keyword: ZK, Neovim, note-taking, Typst, metadata
*/
#import "../include.typ": *
#show: zettel

= Note Title <2602171536>
#tag.zk #tag.idea #tag.todo

Content goes here...
```

### Metadata Fields

- **Aliases**: Alternative names for the note (comma-separated)
- **Abstract**: A brief summary/description of the note
- **Keyword**: Searchable keywords (comma-separated)

## Search Modes

### 1. Multi-Mode Search (`:Zk search` or `zs`)

The main search interface with dynamic mode switching:

**Keybindings:**
- `<CR>`: Open selected note
- `<C-m>`: Toggle search mode (Title → Alias → Keyword → Abstract → Tag)
- `<C-f>`: Add filter (tag or keyword)
- `<C-c>`: Clear all filters

**Search Modes:**
- **Title** (default): Search by note titles
- **Alias**: Search by aliases
- **Keyword**: Search by keywords
- **Abstract**: Search by abstracts
- **Tag**: Search by tags

### 2. Specialized Search Commands

Direct search by specific metadata type:

```vim
:Zk alias      " Search by aliases
:Zk keyword    " Search by keywords
:Zk abstract   " Search by abstracts
```

## Usage Examples

### Example 1: Basic Search with Mode Toggle

1. Press `zs` or `:Zk search`
2. Start typing to search by title
3. Press `<C-m>` to switch to alias mode
4. Press `<C-m>` again to switch to keyword mode
5. Continue cycling through modes

### Example 2: Search with Filters

1. Press `zs` to open search
2. Press `<C-f>` to add a tag filter
3. Select a tag (e.g., "todo")
4. Search results now only show notes with #tag.todo
5. Press `<C-f>` again to add a keyword filter
6. Press `<C-c>` to clear all filters

### Example 3: Direct Keyword Search

1. Run `:Zk keyword`
2. Search through notes that have keywords
3. See keywords displayed alongside titles

## Display Format

Each search mode shows different information:

```
Title Mode:    [2602171536] Note Title #tag1 #tag2
Alias Mode:    [2602171536] Note Title (Alias1, Alias2)
Keyword Mode:  [2602171536] Note Title {keyword1, keyword2}
Abstract Mode: [2602171536] Note Title "This is the abstract..."
```

## Integration with Existing ZK System

The new telescope module integrates seamlessly with the existing ZK system:

- All existing keybindings work as before
- `zs` now uses the enhanced search
- `:Zk search` provides full metadata support
- Backward compatible with notes without metadata

## Implementation Details

### File Structure

```
lua/
├── zk_scripts.lua       # Main ZK functionality
└── zk_telescope.lua     # Metadata search plugin
```

### Metadata Parsing

The plugin uses Lua pattern matching to extract metadata from block comments at the beginning of note files. The parsing is efficient and only reads the header portion of each file.

### Performance

- Lazy loading: Telescope module only loaded when needed
- Efficient parsing: Only reads file headers for metadata
- Cached results: Search results are built once per search session

## Advanced Features

### Combined Filters

You can combine multiple filters:

1. Filter by tag "coding"
2. Filter by keyword "neovim"
3. Results show only notes with both criteria

### Fuzzy Matching

All search modes use Telescope's fuzzy matching:
- Match notes even with partial or out-of-order characters
- Smart sorting by relevance

## Future Enhancements

Potential future improvements:

- [ ] Date range filters
- [ ] Full-text content search
- [ ] Metadata validation
- [ ] Auto-complete for keywords/aliases
- [ ] Export metadata index
- [ ] Visual metadata editor

## Tips

1. **Consistent Formatting**: Use consistent keyword/alias formatting across notes
2. **Descriptive Abstracts**: Write clear, searchable abstracts
3. **Organized Keywords**: Use a controlled vocabulary for keywords
4. **Progressive Disclosure**: Start with title search, add filters as needed
5. **Metadata Templates**: Create templates for common note types

## Troubleshooting

### Metadata not recognized

- Ensure the metadata block starts at line 1
- Check the format: `/* Metadata:` must be exact
- Verify proper closing: `*/`

### Search not finding notes

- Check if notes have the metadata field you're searching
- Use `:Zk search` and cycle through modes
- Verify file paths and permissions

## Commands Summary

```vim
:Zk search     " Multi-mode metadata search
:Zk alias      " Search by aliases only
:Zk keyword    " Search by keywords only
:Zk abstract   " Search by abstracts only
:Zk todo       " Search notes with #tag.todo
:Zk done       " Search notes with #tag.done
:Zk tag        " Prompt for tag name to search
```

## Keybindings Summary

```vim
zs              " Open multi-mode search
zn              " Create new note
ze              " Export for AI
zt              " Search TODO notes
<C-t>           " Toggle todo item
<leader>zo      " Open PDF at cursor
<leader>fz      " Find zettel (same as zs)
<leader>fo      " Find orphan notes
```
