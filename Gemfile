source "https://rubygems.org"

# Specify platform to avoid incompatible gem versions
ruby "2.6.10"

# Jekyll core - Use version compatible with Ruby 2.6
# Jekyll 4.x requires Ruby 3.0+, so we use 3.9.x (same as GitHub Pages)
gem "jekyll", "~> 3.9"

# Markdown processor (GitHub Pages uses kramdown)
gem "kramdown", "~> 2.4"
gem "kramdown-parser-gfm", "~> 1.1"

# Pin ffi to version compatible with Ruby 2.6
# ffi 1.17+ requires Ruby 3.0+, so we use 1.15.x
gem "ffi", "~> 1.15.5"

# Disable Sass processing - site uses plain CSS
# This avoids native extension issues with sassc/ffi

