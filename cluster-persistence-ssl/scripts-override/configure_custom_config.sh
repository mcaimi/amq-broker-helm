#!/bin/sh
set -e

INSTANCE_DIR=$1
DISABLER_TAG="<!-- Remove this tag to enable custom configuration -->"

declare -a CONFIG_FILES=("BROKER_XML" "LOGGING_PROPERTIES")

function swapVars() {
  declare -a SUPPORTED_VARIABLES

  while IFS= read -r line ; do
    while [[ "$line" =~ (\$\{[a-zA-Z_0-9][a-zA-Z_0-9]*\}) ]] ; do
      LHS=${BASH_REMATCH[1]}
      SUPPORTED_VARIABLES+=("$LHS")
      line=${line//$LHS//} #endloop
    done
  done < $1

  for var in "${SUPPORTED_VARIABLES[@]}"; do
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

