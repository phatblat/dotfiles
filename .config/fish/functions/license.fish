function license \
    --description 'Writes out LICENSE file, adds link to readme and commits changes.'

    set -l year (date "+%Y")

    # Write LICENSE file
    echo -n "ISC License

Copyright ©️ $year Ben Chatelain

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED \"AS IS\" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
" >LICENSE

    # Append license info to README.md
    echo -n "
## 📄 License

This repo is licensed under the ISC License. See the [LICENSE](LICENSE) file for rights and limitations.
" >>README.md

    # Commit the changes
    git add LICENSE README.md
    git commit -m '📄 Add license to README.md'
end
