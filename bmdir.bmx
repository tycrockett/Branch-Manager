#Create-Directory
Definitions=()

# wam-Directory
Definitions+=('wam-->/Users/ty.crockett@getweave.com/Desktop/Weave/insys-webapp-wam')
wam () {
used=false
cd /Users/ty.crockett@getweave.com/Desktop/Weave/insys-webapp-wam
if [[ $1 == "run" ]]; then
	used=true
	npm run start-prod
fi
if [[ $1 == "altrun" ]]; then
	used=true
	npm run start
fi
if [[ $used == false ]]; then
	$1 $2 $3 $4
fi
}

# econ-Directory
Definitions+=('econ-->/Users/ty.crockett@getweave.com/Desktop/React/econ')
econ () {
used=false
cd /Users/ty.crockett@getweave.com/Desktop/React/econ
if [[ $1 == "run" ]]; then
	used=true
	npm run start
fi
if [[ $1 == "altrun" ]]; then
	used=true
	echo No Alternate run command created
fi
if [[ $used == false ]]; then
	$1 $2 $3 $4
fi
}

# lat-Directory
Definitions+=('lat-->/Users/ty.crockett@getweave.com/Desktop/React/linds-n-ty')
lat () {
used=false
cd /Users/ty.crockett@getweave.com/Desktop/React/linds-n-ty
if [[ $1 == "run" ]]; then
	used=true
	npm run start
fi
if [[ $1 == "altrun" ]]; then
	used=true
	echo No Alternate run command created
fi
if [[ $used == false ]]; then
	$1 $2 $3 $4
fi
}
