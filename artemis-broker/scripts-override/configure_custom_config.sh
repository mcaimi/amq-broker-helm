#!/bin/bash
set -e

INSTANCE_DIR=$1

declare -a CONFIG_FILES=("bootstrap.xml" "broker.xml" "logging.properties")

function swapVars() {
  # Requires bash v4+
  declare -A SUBSTITUTIONS

  while read -r SUBVAR
  do
    SUBSTITUTIONS[$SUBVAR]=1
  done < <( awk '{
    while( match($0, /\$\{[a-zA-Z_0-9][a-zA-Z_0-9]*\}/) ) {
      print substr($0, RSTART, RLENGTH)
      sub(/\$\{[a-zA-Z_0-9][a-zA-Z_0-9]*\}/, "matched", $0)
    }
  }' $1 )

  echo "Found placeholder variables: \"${!SUBSTITUTIONS[@]}\". Customizing configuration.."

  for var in "${!SUBSTITUTIONS[@]}"; do
    sed -i "s#$var#$(eval echo \"$var\")#g" $1
  done
}

for config_file in ${CONFIG_FILES[@]};
do
  # Swap env vars into configuration file
  if [[ -e $INSTANCE_DIR/etc/$config_file ]]; then
    echo "Patching Custom Configuration file '$config_file'"
    swapVars $INSTANCE_DIR/etc/$config_file
  fi
done

