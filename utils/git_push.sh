#!/usr/bin/env bash

# GitHub Dump

cd "${OUTDIR}" || exit

GITHUB_TOKEN=$(< "${PROJECT_DIR}"/.github_token)	# Write Your Github Token In a Text File
[[ -z "$(git config --get user.email)" ]] && git config user.email "DroidDumps@github.com"
[[ -z "$(git config --get user.name)" ]] && git config user.name "DroidDumps"
if [[ -s "${PROJECT_DIR}"/.github_orgname ]]; then
	GIT_ORG=$(< "${PROJECT_DIR}"/.github_orgname)	# Set Your Github Organization Name
else
	GIT_USER="$(git config --get user.name)"
	GIT_ORG="${GIT_USER}"				# Otherwise, Your Username will be used
fi
# Check if already dumped or not
curl -sf "https://raw.githubusercontent.com/${GIT_ORG}/${repo}/${branch}/all_files.txt" 2>/dev/null && { printf "Firmware already dumped!\nGo to https://github.com/%s/%s/tree/%s\n" "${GIT_ORG}" "${repo}" "${branch}" && exit 1; }

# Copy Local ssh key to Github
ORIG_SSHKEY="$HOME/.ssh/id_rsa.pub"
DEFAULT_KEY="$HOME/.ssh/id_ed25519.pub"	
key_file="${ORIG_SSHKEY}"
username="${GIT_ORG}"    
password="${GITHUB_TOKEN}"

[ ! -s "$key_file" ] && key_file="$DEFAULT_KEY"
if [ ! -e "$key_file" ]; then
	printf "SSH key file doesn't exist: %s, it will be generated now.\n" "$key_file"
	ssh-keygen -t ed25519 -f "${key_file%.pub}"
fi
key=$(cat "$key_file")

response=$(curl -is https://api.github.com/user/keys -X POST -u "$username:$password" -H "application/json" -d "{\"title\": \"$username@$HOSTNAME\", \"key\": \"$key\"}" | grep 'Status: [45][0-9]\{2\}' | tr -d "\r")

[ "$(echo "$response" | grep -c 'Status: 401\|Bad credentials')" -eq 2 ] && { echo "Wrong password." && exit 5; }
[ "$(echo "$response" | grep -c 'Status: 422\|key is already in use')" -eq 2 ] && { echo "Key is already uploaded." && exit 5; }
# Display raw response for unkown 400 messages
[ "$(echo "$response" | grep -c 'Status: 4[0-9][0-9]')" -eq 1 ] && { echo "$response" && exit 1; }

unset ORIG_SSHKEY DEFAULT_KEY key_file key username password response

# Remove The Journal File Inside System/Vendor
find . -mindepth 2 -type d -name "\[SYS\]" -exec rm -rf {} \; 2>/dev/null
# Files larger than 76MB will be split into 47MB parts as *.aa, *.ab, etc.
mkdir -p "${TMPDIR}" 2>/dev/null
find . -size +76M | cut -d'/' -f'2-' >| "${TMPDIR}"/.largefiles
if [[ -s "${TMPDIR}"/.largefiles ]]; then
	printf '#!/bin/bash\n\n' > join_split_files.sh
	while read -r l; do
		split -b 47M "${l}" "${l}".
		rm -f "${l}" 2>/dev/null
		printf "cat %s.* 2>/dev/null >> %s\n" "${l}" "${l}" >> join_split_files.sh
		printf "rm -f %s.* 2>/dev/null\n" "${l}" >> join_split_files.sh
	done < "${TMPDIR}"/.largefiles
	chmod a+x join_split_files.sh 2>/dev/null
fi
rm -rf "${TMPDIR}" 2>/dev/null

git init		# Insure Your Github Authorization Before Running This Script
git config --global http.postBuffer 524288000		# A Simple Tuning to Get Rid of curl (18) error while `git push`
git checkout -b "${branch}"
find . \( -name "*sensetime*" -o -name "*.lic" \) | cut -d'/' -f'2-' >| .gitignore
[[ ! -s .gitignore ]] && rm .gitignore
git add --all
if [[ "${GIT_ORG}" == "${GIT_USER}" ]]; then
	curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{"name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/user/repos" >/dev/null 2>&1
else
	curl -s -X POST -H "Authorization: token ${GITHUB_TOKEN}" -d '{ "name": "'"${repo}"'", "description": "'"${description}"'"}' "https://api.github.com/orgs/${GIT_ORG}/repos" >/dev/null 2>&1
fi
curl -s -X PUT -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.mercy-preview+json" -d '{ "names": ["'"${manufacturer}"'","'"${platform}"'","'"${top_codename}"'"]}' "https://api.github.com/repos/${GIT_ORG}/${repo}/topics" 	# Update Repository Topics
git remote add origin https://github.com/${GIT_ORG}/${repo}.git
git commit -asm "Add ${description}"
git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}" || (
	git update-ref -d HEAD
	git reset system/ vendor/
	git checkout -b "${branch}"
	git commit -asm "Add extras for ${description}"
	git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
	git add vendor/
	git commit -asm "Add vendor for ${description}"
	git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
	git add system/system/app/ system/system/priv-app/ || git add system/app/ system/priv-app/
	git commit -asm "Add apps for ${description}"
	git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
	git add system/
	git commit -asm "Add system for ${description}"
	git push https://${GITHUB_TOKEN}@github.com/${GIT_ORG}/${repo}.git "${branch}"
)
# Telegram channel post
if [[ -s "${PROJECT_DIR}"/.tg_token ]]; then
	TG_TOKEN=$(< "${PROJECT_DIR}"/.tg_token)
	if [[ -s "${PROJECT_DIR}"/.tg_chat ]]; then    # TG Channel ID
		CHAT_ID=$(< "${PROJECT_DIR}"/.tg_chat)
	else
		CHAT_ID="@phoenix_droid_dumps"
	fi
	commit_head=$(git log --format=format:%H | head -n 1)
	commit_link="https://github.com/${GIT_ORG}/${repo}/commit/${commit_head}"
	printf "Sending telegram notification...\n"
	printf "<b>Brand: %s</b>" "${brand}" >| "${OUTDIR}"/tg.html
	{
		printf "\n<b>Device: %s</b>" "${codename}"
		printf "\n<b>Version:</b> %s" "${release}"
		printf "\n<b>Fingerprint:</b> %s" "${fingerprint}"
		printf "\n<b>GitHub Link:</b>"
		printf "\n<a href=\"%s\">Commit</a>" "${commit_link}"
		printf "\n<a href=\"https://github.com/%s/%s/tree/%s/\">%s</a>" "${GIT_ORG}" "${repo}" "${branch}" "${codename}"
	} >> "${OUTDIR}"/tg.html
	TEXT=$(< "${OUTDIR}"/tg.html)
	rm -rf "${OUTDIR}"/tg.html
	curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendmessage" --data "text=${TEXT}&chat_id=${CHAT_ID}&parse_mode=HTML&disable_web_page_preview=True" >/dev/null
fi

