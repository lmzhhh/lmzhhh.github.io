#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Use Homebrew Ruby without changing the system Ruby or shell configuration.
if command -v brew >/dev/null 2>&1; then
  ruby_prefix="$(brew --prefix ruby@3.3 2>/dev/null || true)"
  if [[ -x "$ruby_prefix/bin/ruby" ]]; then
    export PATH="$ruby_prefix/bin:$PATH"
  fi
fi

if ! command -v ruby >/dev/null 2>&1 || ! ruby -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1") ? 0 : 1)'; then
  echo "Ruby 3.1+ is required. On macOS, run: brew install ruby@3.3" >&2
  exit 1
fi

if ! bundle --version >/dev/null 2>&1; then
  echo "Bundler is required. Install it for your Ruby with: gem install bundler" >&2
  exit 1
fi

action="${1:-serve}"
if [[ $# -gt 0 ]]; then shift; fi
case "$action" in
  setup|serve|build) ;;
  *) echo "Usage: $0 [setup|serve|build] [Jekyll options]" >&2; exit 1 ;;
esac

bundle config set --local path vendor/bundle
if [[ ! -f Gemfile.lock ]] || ! bundle check >/dev/null 2>&1; then
  bundle install
fi

case "$action" in
  setup)
    echo "Jekyll dependencies are ready. Start the site with: npm run dev"
    ;;
  serve)
    export JEKYLL_ENV=development
    exec bundle exec jekyll serve --config _config.yml,_config_local.yml \
      --host 127.0.0.1 --livereload "$@"
    ;;
  build)
    export JEKYLL_ENV=development
    exec bundle exec jekyll build --config _config.yml,_config_local.yml "$@"
    ;;
esac
