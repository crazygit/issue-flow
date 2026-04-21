#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INSTALL_MODE="copy"
CODEX_DIR="${HOME}/.codex"
PLUGINS_DIR="${HOME}/.codex/plugins"
ISSUE_FLOW_DIR="${PLUGINS_DIR}/issue-flow"
CODEX_CONFIG_FILE="${CODEX_DIR}/config.toml"
CODEX_HOOKS_FILE="${CODEX_DIR}/hooks.json"
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

Prepare a personal Codex marketplace entry for issue-flow.

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

trim_whitespace() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
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

extract_plugins_array() {
  local content="$1"
  local length=${#content}
  local in_string=0
  local escaped=0
  local depth=0
  local waiting_for_array=0
  local plugins_start=-1
  local i ch

  for ((i = 0; i < length; i++)); do
    ch="${content:i:1}"

    if ((escaped)); then
      escaped=0
      continue
    fi

    if ((in_string)); then
      if [ "$ch" = "\\" ]; then
        escaped=1
      elif [ "$ch" = '"' ]; then
        in_string=0
      fi
      continue
    fi

    if [ "$depth" -eq 1 ] && [ $waiting_for_array -eq 0 ] && [ "${content:i:9}" = '"plugins"' ]; then
      waiting_for_array=1
    fi

    if [ "$ch" = '"' ]; then
      in_string=1
      continue
    fi

    if [ "$waiting_for_array" -eq 1 ] && [ "$ch" = "[" ]; then
      plugins_start=$i
      break
    fi

    case "$ch" in
      "{")
        depth=$((depth + 1))
        ;;
      "}")
        depth=$((depth - 1))
        ;;
    esac
  done

  if [ "$plugins_start" -lt 0 ]; then
    return 1
  fi

  in_string=0
  escaped=0
  depth=1

  for ((i = plugins_start + 1; i < length; i++)); do
    ch="${content:i:1}"

    if ((escaped)); then
      escaped=0
      continue
    fi

    if ((in_string)); then
      if [ "$ch" = "\\" ]; then
        escaped=1
      elif [ "$ch" = '"' ]; then
        in_string=0
      fi
      continue
    fi

    if [ "$ch" = '"' ]; then
      in_string=1
      continue
    fi

    case "$ch" in
      "[")
        depth=$((depth + 1))
        ;;
      "]")
        depth=$((depth - 1))
        if [ "$depth" -eq 0 ]; then
          printf '%s' "${content:plugins_start + 1:i - plugins_start - 1}"
          return 0
        fi
        ;;
    esac
  done

  return 1
}

split_json_array_items() {
  local content="$1"
  local length=${#content}
  local in_string=0
  local escaped=0
  local depth=0
  local start=0
  local i ch item

  JSON_ARRAY_ITEMS=()

  for ((i = 0; i < length; i++)); do
    ch="${content:i:1}"

    if ((escaped)); then
      escaped=0
      continue
    fi

    if ((in_string)); then
      if [ "$ch" = "\\" ]; then
        escaped=1
      elif [ "$ch" = '"' ]; then
        in_string=0
      fi
      continue
    fi

    if [ "$ch" = '"' ]; then
      in_string=1
      continue
    fi

    case "$ch" in
      "{"|"[")
        depth=$((depth + 1))
        ;;
      "}"|"]")
        depth=$((depth - 1))
        ;;
      ",")
        if [ "$depth" -eq 0 ]; then
          item="$(trim_whitespace "${content:start:i - start}")"
          if [ -n "$item" ]; then
            JSON_ARRAY_ITEMS+=("$item")
          fi
          start=$((i + 1))
        fi
        ;;
    esac
  done

  item="$(trim_whitespace "${content:start}")"
  if [ -n "$item" ]; then
    JSON_ARRAY_ITEMS+=("$item")
  fi
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
  local content plugins_array plugin
  local filtered_plugins=()

  if [ -f "$MARKETPLACE_FILE" ]; then
    content="$(cat "$MARKETPLACE_FILE")"
    if plugins_array="$(extract_plugins_array "$content")"; then
      split_json_array_items "$plugins_array"
      for plugin in "${JSON_ARRAY_ITEMS[@]}"; do
        if [[ "$plugin" =~ \"name\"[[:space:]]*:[[:space:]]*\"issue-flow\" ]]; then
          continue
        fi
        filtered_plugins+=("$plugin")
      done
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
[features]
codex_hooks = true

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
      in_features = 0
      in_superpowers = 0
      in_issue_flow = 0
      found_features = 0
      found_codex_hooks = 0
      found_superpowers = 0
      found_issue_flow = 0
    }

    function ensure_codex_hooks_line() {
      if (in_features && !found_codex_hooks) {
        print "codex_hooks = true"
        found_codex_hooks = 1
      }
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
      ensure_codex_hooks_line()
      ensure_plugin_enabled_line()
      in_features = 0
      in_superpowers = 0
      in_issue_flow = 0

      if ($0 ~ /^\[features\][[:space:]]*$/) {
        in_features = 1
        found_features = 1
      }
      else if ($0 ~ /^\[plugins\."superpowers@openai-curated"\][[:space:]]*$/) {
        in_superpowers = 1
      }
      else if ($0 == "[plugins.\"" issue_flow_plugin_id "\"]") {
        in_issue_flow = 1
      }

      print
      next
    }

    {
      if (in_features && $0 ~ /^[[:space:]]*codex_hooks[[:space:]]*=/) {
        if (!found_codex_hooks) {
          print "codex_hooks = true"
          found_codex_hooks = 1
        }
        next
      }

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
      ensure_codex_hooks_line()
      ensure_plugin_enabled_line()

      if (!found_features) {
        if (NR > 0) {
          print ""
        }
        print "[features]"
        print "codex_hooks = true"
      }

      if (!in_superpowers && !found_superpowers) {
        if (NR > 0 || found_features) {
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

managed_issue_flow_hook_command() {
  printf 'bash "%s/hooks/run-hook.cmd" session-start' "$ISSUE_FLOW_DIR"
}

merge_codex_hooks() {
  local managed_command

  managed_command="$(managed_issue_flow_hook_command)"

  perl -MJSON::PP -e '
    use strict;
    use warnings;
    use JSON::PP qw(decode_json);

    my ($file, $managed_command, $status_message) = @ARGV;
    my $doc = {};

    if (-f $file && -s $file) {
      local $/;
      open my $fh, "<", $file or die "Failed to read $file: $!";
      my $content = <$fh>;
      close $fh;
      $doc = decode_json($content);
      die "Expected top-level JSON object in $file\n" unless ref($doc) eq "HASH";
    }

    $doc->{hooks} = {} unless ref($doc->{hooks}) eq "HASH";
    $doc->{hooks}{SessionStart} = [] unless ref($doc->{hooks}{SessionStart}) eq "ARRAY";

    my @filtered_groups = grep {
      my $group = $_;
      my $hooks = ref($group) eq "HASH" && ref($group->{hooks}) eq "ARRAY" ? $group->{hooks} : [];
      my $is_managed = 0;

      for my $hook (@{$hooks}) {
        next unless ref($hook) eq "HASH";
        if (($hook->{command} // q{}) eq $managed_command) {
          $is_managed = 1;
          last;
        }
      }

      !$is_managed;
    } @{$doc->{hooks}{SessionStart}};

    push @filtered_groups, {
      matcher => "startup|resume",
      hooks => [
        {
          type => "command",
          command => $managed_command,
          statusMessage => $status_message,
        }
      ],
    };

    $doc->{hooks}{SessionStart} = \@filtered_groups;

    my $encoder = JSON::PP->new->ascii->pretty->canonical;
    open my $out, ">", $file or die "Failed to write $file: $!";
    print {$out} $encoder->encode($doc);
    close $out;
  ' "$CODEX_HOOKS_FILE" "$managed_command" "Loading issue-flow workspace context"
}

print_summary() {
  cat <<EOF
Codex local plugin install complete.

Installed paths:
  issue-flow:  $ISSUE_FLOW_DIR
  marketplace: $MARKETPLACE_FILE
  config:      $CODEX_CONFIG_FILE
  hooks:       $CODEX_HOOKS_FILE

Next steps:
  1. Restart Codex.
  2. Open the plugin directory and confirm "Superpowers" and "issue-flow" are enabled.
  3. If needed, look for "issue-flow" under "$MARKETPLACE_DISPLAY_NAME".
EOF
}

prepare_directories
stage_issue_flow
write_marketplace
merge_codex_config
merge_codex_hooks
print_summary
