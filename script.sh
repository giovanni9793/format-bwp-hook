#!/bin/bash

decryptXmllintFormat(){
	# implicit encoding https://webfocusinfocenter.informationbuilders.com/wfappent/TL2s/TL_lang/source/xmlencod.htm
	echo "$1"\
	| sed -z 's|"\([^"]*\)\&lt;\([^"]*\)"|"\1<\2"|g'\
	| sed -z 's|"\([^"]*\)\&gt;\([^"]*\)"|"\1>\2"|g'
	# | sed -z 's|"\([^"]*\)\&amp;\([^"]*\)"|"\1&\2"|g'
	# | sed -z 's|"\([^"]*\)\&apos;\([^"]*\)"|"\1''\2"|g'
}

encryptXml(){
	echo "$1" | sed -z 's|<|\&lt;|g'\
	| sed -z 's|"|\&quot;|g' # should be last conversion
}
partialEncryptXml(){
	echo "$1" | sed -z 's|\&#xa;|\&#10;|g'
}
decryptXml(){
	echo "$1" | sed -z 's|\&lt;|<|g'\
	| sed -z 's|\&gt;|>|g'\
	| sed -z 's|\&quot;|"|g'\
	| sed -z 's|\&#10;|\n|g'\
	| sed -z 's|\&#xa;|\n|g'
}
partialDecryptXml(){
	echo "$1"\
	| sed -z 's|\&gt;|>|g'\
	| sed -z 's|\&#10;|\&#xa;|g'
}
prepareOriginal(){
	# echo "$1" | sed -e 's/[]\/$*.^[]/\\&/g'
	echo "$1" | sed -z 's|\[|\\[|g'
}
prepareReplace(){
	echo "$1" | sed -e 's/[\/&]/\\&/g' | sed -e 's/|/\\|/g'
}

for path in "$@"
do
	echo -e "File: ${path}"
	placeHolder='_PLACEHOLDER_'
	prefix="${path}_"
	occurrences=$(csplit -n 5 -f "${prefix}" "${path}" '/expression=/' '{*}' | wc -l)
	for (( i=1; i<${occurrences}; i++ ))
	do 
		echo "Occurrence number $i"
		inputNo="0000${i}"
	  	inputNo="${inputNo: -5}"
		file=$(cat "${prefix}${inputNo}")
		found=$(echo "$file" | sed -z 's|.*expression="\([^"]*\)".*|\1|')
		foundDecryped=$(decryptXml "$found")
		firstChar=$(echo "${foundDecryped}" | sed -z 's| ||g')
		firstChar="${firstChar:0:1}"
		if [[ "${firstChar}" != "<" ]]; then
			echo "skip"
			continue
		fi
		# implicit encoding https://webfocusinfocenter.informationbuilders.com/wfappent/TL2s/TL_lang/source/xmlencod.htm
		foundFormatted=$(xmllint --format <(echo "${foundDecryped}"))
		foundXmllintDecrypted=$(decryptXmllintFormat "${foundFormatted}")
		result=$(encryptXml "${foundXmllintDecrypted}")
		result=$(echo "${result}" | sed -z "s|\\n|${placeHolder}|g")
		sed2=$(prepareReplace "${result}")
		data=$(sed -z -f <(echo "s|expression=\"\([^\"]*\)\"|expression=\"${sed2}\"|") "${prefix}${inputNo}")
		echo "${data}" | sed -z "s|${placeHolder}|\\n|g" > "${prefix}${inputNo}"
	done
	cat "${prefix}"* > "$path"
	rm "${prefix}"*
done
