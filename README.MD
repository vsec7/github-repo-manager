# 🛠️ GitHub Repo Manager

Automate repository operations for multiple GitHub users using a simple Bash script.

## 📦 Features

* Push all folders in current directory to GitHub as **public repositories**
* Change visibility of a **specific** or **all** repositories
* Delete:

  * A **specific** repo
  * All repos matching local folder names
  * **All** repos for each user
* Rotate multiple GitHub users automatically
* Adds a delay between requests to avoid API rate limits

## 📂 Folder Structure

Each folder inside your current directory (e.g. `repo1`, `repo2`) will be treated as a separate repo:

```
📁 my-repo-1/
📁 my-repo-2/
📁 my-repo-3/
📄 users.txt
📄 github-repo-manager.sh
```

## 📝 users.txt Format

```
github_username1,ghp_yourGitHubTokenHere
github_username2,ghp_anotherTokenHere
```

> 💡 You can generate a token at: [https://github.com/settings/tokens](https://github.com/settings/tokens)
> Make sure the token has the following **scopes**:
>
> * `repo`
> * `delete_repo`
> * `user`
> * `admin:repo_hook`
> * `workflow`

## 🧲 Requirements

```bash
sudo apt update
sudo apt install curl git
```

## 🚀 Usage

Make the script executable:

```bash
chmod +x github-repo-manager.sh
./github-repo-manager.sh
```

Choose from the menu:

```
📋 GitHub Repo Manager by github.com/vsec7
0) Exit
1) Push all folders as public repos
2) Change visibility of a specific repo
3) Change visibility of ALL repos
4) Delete a specific repo
5) Delete repos that match local folder names
6) Delete ALL repos for each user
```

## ⏱️ Delay

By default, each push/delete has a delay of **5 seconds** to avoid API rate limits. You can change this by editing:

```bash
DELAY_SECONDS=5
```


## 🧑‍💻 Credits

Created by **[@vsec7](https://github.com/vsec7)**

## Buy me Coffee

viloid.sol | viloid.bnb
