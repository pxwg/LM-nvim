# ZK Capture Chrome Extension

A lightweight Zotero-style Chrome frontend for the local `script/zk-capture` CLI.

## What it does

- Capture the current web page into `~/wiki/note`.
- Capture the current PDF tab into `~/wiki/assets/<note-id>-pdf/` and add/update `~/wiki/ref.bib`.
- Right-click a PDF download link and choose **Capture linked PDF to ZK**.

## Install for development

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Click **Load unpacked** and select this directory: `~/.config/nvim/chrome/zk-capture`.
4. Copy the extension id shown by Chrome.
5. Install the native messaging host:

   ```bash
   ~/.config/nvim/script/zk-capture-install-native-host <extension-id>
   ```

6. In the extension popup, click **Test native host**.

For current local `file://` PDF tabs, enable **Allow access to file URLs** on the extension detail page.

## CLI examples

```bash
~/.config/nvim/script/zk-capture web --url https://example.com
~/.config/nvim/script/zk-capture pdf-url --url https://arxiv.org/pdf/1603.02349.pdf
~/.config/nvim/script/zk-capture pdf-file --path ~/Downloads/paper.pdf
```

Set `ZK_WIKI_ROOT=/path/to/wiki` to target a wiki other than `~/wiki`.
