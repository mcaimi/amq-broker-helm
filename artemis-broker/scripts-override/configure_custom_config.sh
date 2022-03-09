#!/bin/bash
set -e

INSTANCE_DIR=$1
DISABLER_TAG="<!-- Remove this tag to enable custom configuration -->"

declare -a CONFIG_FILES=("BOOTSTRAP_XML" "BROKER_XML" "LOGGING_PROPERTIES")

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
  file_text="${!config_file}"
  file_text=$(echo "$file_text" | sed  "/^$/d") # Remove empty lines

  # Format env var into filename 
  fname=$(echo "$config_file" | tr '[:upper:]' '[:lower:]' | sed -e 's/_/./g')

  #If file_text has disabler tag or is an empty/whitspace string 
  if echo "$file_text" | grep -q "$DISABLER_TAG" || [[ -z "${file_text// }" ]]; then  

    echo "Custom Configuration file '$config_file' is disabled"

  else

    echo "Custom Configuration file '$config_file' is enabled"

    # Overwrite default configuration file
    echo "$file_text" > $INSTANCE_DIR/etc/$fname

  fi

    # Swap env vars into configuration file
    swapVars $INSTANCE_DIR/etc/$fname
done

