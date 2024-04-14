#!/bin/bash



## update check https://www.christianengvall.se/check-for-changes-on-remote-origin-git-repository/
echo "Checking for updates..."
git fetch
 HEADHASH=$(git rev-parse HEAD)
 UPSTREAMHASH=$(git rev-parse main@{upstream})

 if [ "$HEADHASH" != "$UPSTREAMHASH" ]
 then
   echo -e "${oc_COLOR_NOTIFICATION}Updates available, do you want to update? \[Y/N\]${oc_COLOR_NOCOLOR}"
   read u
    if [ "$u" == "Y" ] || [ "$u" == "y" ]
      then
        echo "Updating..."
        git pull origin main
        echo -e ${oc_COLOR_WHITE}Since last update...${oc_COLOR_NOCOLOR}
        git log HEAD..origin/main --oneline
    fi
 else
   echo "${oc_COLOR_WHITE}Up to date!${oc_COLOR_NOCOLOR}"
 fi

## Start script
echo "${oc_COLOR_QUESTION}DevHub (leave blank for default $devHub)${oc_COLOR_NOCOLOR}"
read o
if [ ! -z "$o" ]
  then
    devHub=$o
fi

echo "This script will create a new scratch org off of $devHub. Checking pre-conditions..."



# read in name of project
echo ""
echo -e "${oc_COLOR_QUESTION}What is the alias for the org? This might be a Org62 case number (37711301-pushUpgrades), trailhead exercise, etc.${oc_COLOR_NOCOLOR}"
read oc_alias
datedAlias+=$oc_alias

# user can override the scratch definition if desired
echo ""
echo -e "${oc_COLOR_QUESTION}Scratch Definition (Enter 0 for default "$scratchDef")${oc_COLOR_NOCOLOR}"
  select file in "${oc_installedDir}/..scratchDefs/"*.json; do
    if [ $REPLY == "0" ]; then
      echo Default chosen
      break;
    elif [[ -z $file ]]; then
      echo -e "${oc_COLOR_WARN}Invalid selection, try again${oc_COLOR_NOCOLOR}" >&2
    else
      scratchDef=$file
      break;
    fi
done
echo Scratch definition set: $scratchDef

# default parent folder is set but can be overridden
echo ""
echo -e "${oc_COLOR_QUESTION}What folder should this go in? (Leave blank for default $folder)${oc_COLOR_NOCOLOR}"
read f
if [ ! -z "$f" ]
  then
    folder=$f
fi

# echo "Devhub: $devHub"
# echo "scratchDef: $scratchDef"
# echo "alias: $oc_alias"

# create the scratch org and project folder. 
# Once done, open folder in code and install dependencies
sf org create scratch -f $scratchDef -a $oc_alias -v $devHub -w 10 -y 21
sf org resume scratch --use-most-recent
echo "Scratch org creation done"
echo "Setting target-org and generating project"
sf project generate -t standard -n $datedAlias -d $folder

# write the readme
echo -e "${oc_COLOR_QUESTION}Describe this goals for this project${oc_COLOR_NOCOLOR}"
read goals
echo "# ${oc_alias}" > $folder/$datedAlias/README.md
echo "" >> $folder/$datedAlias/README.md
echo $goals >> $folder/$datedAlias/README.md

# open code editor
code $folder/$datedAlias -g $folder/$datedAlias/README.md:2
cd $folder/$datedAlias
sf config set target-org=$oc_alias
echo "Resetting the password"
sf org generate password --complexity 3
echo "Installing dependencies"
npm i

echo "Creating pre-commit hook for Code Analyzer"
echo -e "// lint-staged.config.js
module.exports = {
  \"**/*.cls\": (filenames) => \"sf scanner run -f table -s 3 -t \" + filenames.join(\", \") 
};
" > lint-staged.config.js

echo "Creating GitHub Action Workflow Rules"
mkdir -p .github/workflows
cp -a "${oc_installedDir}/utilities/fileTemplates/workflows/." .github/workflows/

if $oc_github
then
  echo "Creating a git repo locally and on GitHub"
  git init 
  gh repo create $datedAlias --private  -s .  --disable-wiki --disable-issues
else
  echo "Github CLI not setup, skipping Git-related steps"
fi

echo "Opening the new org"
sf org open -o $oc_alias
echo "You will need to authenticate your new org"