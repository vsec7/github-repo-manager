#!/bin/bash
# GitHub Repo Manager by github.com/vsec7

set -e

USERS_FILE="users.txt"
BASE_DIR=$(pwd)
DELAY_SECONDS=5

mapfile -t users < "$USERS_FILE"
user_count=${#users[@]}

if [ $user_count -eq 0 ]; then
  echo "❌ No users found in users.txt"
  exit 1
fi

echo ""
echo "📋 GitHub Repo Manager by github.com/vsec7"
echo "0) Exit"
echo "1) Push all folders as public repos"
echo "2) Change visibility of a specific repo"
echo "3) Change visibility of ALL repos"
echo "4) Delete a specific repo"
echo "5) Delete repos that match local folder names"
echo "6) Delete ALL repos for each user"
echo ""
read -p "Select an option [0-6]: " choice

get_real_username() {
  local token="$1"
  curl -s -H "Authorization: token $token" https://api.github.com/user | grep -oP '"login":\s*"\K[^"]+'
}

push_all_folders() {
  i=0
  for folder in "$BASE_DIR"/*/; do
    folder_name=$(basename "$folder")
    user_line="${users[$i]}"
    token=$(echo "$user_line" | cut -d',' -f2)
    real_username=$(get_real_username "$token")

    if [ -z "$real_username" ]; then
      echo "❌ Invalid token for user $((i+1)). Skipping."
      i=$(((i + 1) % user_count))
      continue
    fi

    echo "📦 Pushing $folder_name as $real_username"

    cd "$folder"
    rm -rf .git
    git init
    git config user.name "$real_username"
    git config user.email "$real_username@users.noreply.github.com"
    git add .
    git commit -m "Initial commit"
    git branch -M main

    curl -s -H "Authorization: token $token" \
      -d "{\"name\":\"$folder_name\",\"private\":false}" \
      https://api.github.com/user/repos > /dev/null

    remote_url="https://${real_username}:${token}@github.com/${real_username}/${folder_name}.git"
    git remote add origin "$remote_url"
    git push -u origin main

    echo "✅ Pushed. Waiting $DELAY_SECONDS seconds..."
    sleep "$DELAY_SECONDS"
    rm -rf .git
    cd "$BASE_DIR"
    i=$(((i + 1) % user_count))
  done
}

change_visibility() {
  read -p "Enter repo name: " repo_name
  read -p "New visibility (public/private): " new_visibility

  if [[ "$new_visibility" != "public" && "$new_visibility" != "private" ]]; then
    echo "❌ Invalid visibility option."
    return
  fi

  visibility_flag=$( [ "$new_visibility" == "private" ] && echo true || echo false )

  for user_line in "${users[@]}"; do
    token=$(echo "$user_line" | cut -d',' -f2)
    username=$(get_real_username "$token")
    api_url="https://api.github.com/repos/${username}/${repo_name}"

    echo "🔄 Changing $username/$repo_name to $new_visibility..."

    curl -s -X PATCH "$api_url" \
      -H "Authorization: token $token" \
      -H "Accept: application/vnd.github+json" \
      -H "Content-Type: application/json" \
      -d "{\"private\": $visibility_flag}" > /dev/null
  done
}

change_visibility_all_repos() {
  read -p "Set visibility to (public/private): " visibility
  if [[ "$visibility" != "public" && "$visibility" != "private" ]]; then
    echo "❌ Invalid visibility option."
    return
  fi
  visibility_flag=$( [ "$visibility" == "private" ] && echo true || echo false )

  for user_line in "${users[@]}"; do
    token=$(echo "$user_line" | cut -d',' -f2)
    username=$(get_real_username "$token")

    repos=$(curl -s -H "Authorization: token $token" "https://api.github.com/user/repos?per_page=100" | grep -oP '"name":\s*"\K[^"]+')

    for repo_name in $repos; do
      curl -s -X PATCH \
        -H "Authorization: token $token" \
        -H "Content-Type: application/json" \
        -d "{\"private\":$visibility_flag}" \
        "https://api.github.com/repos/${username}/${repo_name}" > /dev/null
      sleep 1
    done
  done
}

delete_repo() {
  read -p "Enter repo name to delete: " repo_name
  for user_line in "${users[@]}"; do
    token=$(echo "$user_line" | cut -d',' -f2)
    username=$(get_real_username "$token")
    curl -s -X DELETE \
      -H "Authorization: token $token" \
      "https://api.github.com/repos/${username}/${repo_name}" > /dev/null
  done
}

delete_all_repos() {
  echo "⚠️ This will delete ALL repos for ALL users."
  read -p "Type 'yes' to continue: " confirm
  if ! [[ "$confirm" =~ ^[Yy](es)?$ ]]; then
    echo "❌ Cancelled."
    return
  fi

  for user_line in "${users[@]}"; do
    token=$(echo "$user_line" | cut -d',' -f2)
    username=$(get_real_username "$token")

    repos=$(curl -s -H "Authorization: token $token" "https://api.github.com/user/repos?per_page=100" | grep -oP '"full_name":\s*"\K[^"]+')

    for repo in $repos; do
      curl -s -X DELETE \
        -H "Authorization: token $token" \
        "https://api.github.com/repos/$repo" > /dev/null
      sleep 1
    done
  done
}

delete_repos_matching_folders() {
  echo "⚠️ This will delete all remote repos matching your local folder names."
  read -p "Type 'yes' to confirm: " confirm
  if ! [[ "$confirm" =~ ^[Yy](es)?$ ]]; then
    echo "❌ Cancelled."
    return
  fi

  for user_line in "${users[@]}"; do
    token=$(echo "$user_line" | cut -d',' -f2)
    username=$(get_real_username "$token")

    for folder in "$BASE_DIR"/*/; do
      repo_name=$(basename "$folder")
      curl -s -X DELETE \
        -H "Authorization: token $token" \
        "https://api.github.com/repos/${username}/${repo_name}" > /dev/null
      sleep 1
    done
  done
}

case "$choice" in
  0) echo "👋 Exiting."; exit 0 ;;
  1) push_all_folders; echo "✅ All folders pushed."; exit 0 ;;
  2) change_visibility; echo "✅ Visibility updated."; exit 0 ;;
  3) change_visibility_all_repos; echo "✅ All repo visibilities updated."; exit 0 ;;
  4) delete_repo; echo "✅ Repo deleted."; exit 0 ;;
  5) delete_repos_matching_folders; echo "✅ Matching repos deleted."; exit 0 ;;
  6) delete_all_repos; echo "✅ All repos deleted."; exit 0 ;;
  *) echo "❌ Invalid option."; exit 1 ;;
esac
