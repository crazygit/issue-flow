#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INSTALL_MODE="copy"
CODEX_DIR="${HOME}/.codex"
PLUGINS_DIR="${HOME}/.codex/plugins"
ISSUE_FLOW_DIR="${PLUGINS_DIR}/issue-flow"
CODEX_CONFIG_FILE="${CODEX_DIR}/config.toml"
MARKETPLACE_DIR="${HOME}/.agents/plugins"
MARKETPLACE_FILE="${MARKETPLACE_DIR}/marketplace.json"
MARKETPLACE_NAME="codex-personal-plugins"
MARKETPLACE_DISPLAY_NAME="Personal Plugins"

extract_marketplace_metadata() {
  local key="$1"
  local default_value="$2"

  if [ ! -f "$MARKETPLACE_FILE" ]; then
    printf '%s' "$default_value"
    return
  fi

  perl -MJSON::PP -e '
    use strict;
    use warnings;
    use JSON::PP qw(decode_json);

    my ($file, $key, $default_value) = @ARGV;

    if (!-f $file || !-s $file) {
      print $default_value;
      exit 0;
    }

    local $/;
    open my $fh, "<", $file or do {
      print $default_value;
      exit 0;
    };
    my $content = <$fh>;
    close $fh;

    my $doc = eval { decode_json($content) };
    if (!$doc || ref($doc) ne "HASH") {
      print $default_value;
      exit 0;
    }

    if ($key eq "name") {
      my $value = $doc->{name};
      print defined($value) && $value ne q{} ? $value : $default_value;
      exit 0;
    }

    if ($key eq "displayName") {
      my $value = ref($doc->{interface}) eq "HASH" ? $doc->{interface}{displayName} : undef;
      print defined($value) && $value ne q{} ? $value : $default_value;
      exit 0;
    }

    print $default_value;
  ' "$MARKETPLACE_FILE" "$key" "$default_value"
}

usage() {
  cat <<'EOF'
Usage: bash scripts/install-codex.sh [--copy|--dev-link] [--help]

Prepare a personal Codex marketplace entry for the issue-flow plugin bundle.
The bundle includes both `issue-flow` and `bugfix-flow` skills.

Options:
  --copy      Copy the current repository into ~/.codex/plugins/issue-flow (default)
  --dev-link  Symlink the current repository into ~/.codex/plugins/issue-flow
  --help      Show this help text
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --copy)
      INSTALL_MODE="copy"
      ;;
    --dev-link)
      INSTALL_MODE="dev-link"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

prepare_directories() {
  mkdir -p "$CODEX_DIR" "$PLUGINS_DIR" "$MARKETPLACE_DIR"
}

stage_issue_flow() {
  rm -rf "$ISSUE_FLOW_DIR"

  if [ "$INSTALL_MODE" = "dev-link" ]; then
    ln -s "$REPO_ROOT" "$ISSUE_FLOW_DIR"
    return
  fi

  cp -R "$REPO_ROOT" "$ISSUE_FLOW_DIR"
  rm -rf "$ISSUE_FLOW_DIR/.git"
}

managed_issue_flow_plugin() {
  cat <<'EOF'
{
  "name": "issue-flow",
  "source": {
    "source": "local",
    "path": "./.codex/plugins/issue-flow"
  },
  "policy": {
    "installation": "AVAILABLE",
    "authentication": "ON_INSTALL"
  },
  "category": "Productivity"
}
EOF
}

write_marketplace_document() {
  local plugin_items=("$@")
  local managed_plugin
  local total index
  local marketplace_name
  local marketplace_display_name

  managed_plugin="$(managed_issue_flow_plugin)"
  marketplace_name="$(extract_marketplace_metadata "name" "$MARKETPLACE_NAME")"
  marketplace_display_name="$(extract_marketplace_metadata "displayName" "$MARKETPLACE_DISPLAY_NAME")"
  MARKETPLACE_NAME="$marketplace_name"
  MARKETPLACE_DISPLAY_NAME="$marketplace_display_name"
  total=$(( ${#plugin_items[@]} + 1 ))

  {
    cat <<EOF
{
  "name": "$marketplace_name",
  "interface": {
    "displayName": "$marketplace_display_name"
  },
  "plugins": [
EOF

    index=0
    for plugin in "${plugin_items[@]}"; do
      index=$((index + 1))
      printf '%s\n' "$plugin" | sed 's/^/    /'
      if [ "$index" -lt "$total" ]; then
        printf ',\n'
      else
        printf '\n'
      fi
    done

    index=$((index + 1))
    printf '%s\n' "$managed_plugin" | sed 's/^/    /'
    if [ "$index" -lt "$total" ]; then
      printf ',\n'
    else
      printf '\n'
    fi

    cat <<'EOF'
  ]
}
EOF
  } >"$MARKETPLACE_FILE"
}

write_marketplace() {
  local plugin_lines plugin
  local filtered_plugins=()

  if [ -f "$MARKETPLACE_FILE" ]; then
    plugin_lines="$(perl -MJSON::PP -e '
      use strict;
      use warnings;
      use JSON::PP qw(decode_json);

      my ($file) = @ARGV;
      exit 0 unless -f $file && -s $file;

      local $/;
      open my $fh, "<", $file or exit 0;
      my $content = <$fh>;
      close $fh;

      my $doc = eval { decode_json($content) };
      exit 0 unless $doc && ref($doc) eq "HASH";

      my $plugins = $doc->{plugins};
      exit 0 unless ref($plugins) eq "ARRAY";

      my $encoder = JSON::PP->new->ascii->canonical;
      for my $plugin (@{$plugins}) {
        next unless ref($plugin) eq "HASH";
        next if ($plugin->{name} // q{}) eq "issue-flow";
        print $encoder->encode($plugin), "\n";
      }
    ' "$MARKETPLACE_FILE")"

    if [ -n "$plugin_lines" ]; then
      while IFS= read -r plugin; do
        filtered_plugins+=("$plugin")
      done <<<"$plugin_lines"
    fi
  fi

  write_marketplace_document "${filtered_plugins[@]}"
}

merge_codex_config() {
  local tmp_file
  local issue_flow_plugin_id

  issue_flow_plugin_id="issue-flow@${MARKETPLACE_NAME}"
  if [ ! -f "$CODEX_CONFIG_FILE" ]; then
    cat >"$CODEX_CONFIG_FILE" <<EOF
[plugins."superpowers@openai-curated"]
enabled = true

[plugins."$issue_flow_plugin_id"]
enabled = true
EOF
    return
  fi

  tmp_file="$(mktemp)"

  awk -v issue_flow_plugin_id="$issue_flow_plugin_id" '
    BEGIN {
      in_superpowers = 0
      in_issue_flow = 0
      found_superpowers = 0
      found_issue_flow = 0
    }

    function ensure_plugin_enabled_line() {
      if (in_superpowers && !found_superpowers) {
        print "enabled = true"
        found_superpowers = 1
      }
      if (in_issue_flow && !found_issue_flow) {
        print "enabled = true"
        found_issue_flow = 1
      }
    }

    /^\[/ {
      ensure_plugin_enabled_line()
      in_superpowers = 0
      in_issue_flow = 0

      if ($0 ~ /^\[plugins\."superpowers@openai-curated"\][[:space:]]*$/) {
        in_superpowers = 1
      }
      else if ($0 == "[plugins.\"" issue_flow_plugin_id "\"]") {
        in_issue_flow = 1
      }

      print
      next
    }

    {
      if (in_superpowers && $0 ~ /^[[:space:]]*enabled[[:space:]]*=/) {
        if (!found_superpowers) {
          print "enabled = true"
          found_superpowers = 1
        }
        next
      }

      if (in_issue_flow && $0 ~ /^[[:space:]]*enabled[[:space:]]*=/) {
        if (!found_issue_flow) {
          print "enabled = true"
          found_issue_flow = 1
        }
        next
      }

      print
    }

    END {
      ensure_plugin_enabled_line()

      if (!in_superpowers && !found_superpowers) {
        if (NR > 0) {
          print ""
        }
        print "[plugins.\"superpowers@openai-curated\"]"
        print "enabled = true"
      }

      if (!in_issue_flow && !found_issue_flow) {
        print ""
        print "[plugins.\"" issue_flow_plugin_id "\"]"
        print "enabled = true"
      }
    }
  ' "$CODEX_CONFIG_FILE" >"$tmp_file"

  mv "$tmp_file" "$CODEX_CONFIG_FILE"
}

print_summary() {
  cat <<EOF
Codex local plugin install complete.

Installed paths:
  plugin bundle: $ISSUE_FLOW_DIR
  marketplace:   $MARKETPLACE_FILE
  config:        $CODEX_CONFIG_FILE

Next steps:
  1. Restart Codex.
  2. Open the plugin directory and confirm "Superpowers" and "issue-flow" are enabled.
  3. Use either 'issue-flow' or 'bugfix-flow' from the installed plugin bundle.
  4. If needed, look for "issue-flow" under "$MARKETPLACE_DISPLAY_NAME".
EOF
}

prepare_directories
stage_issue_flow
write_marketplace
merge_codex_config
print_summary
