

t3:
    @# git add .github/workflows/build.yml
    git add .
    git commit -m "F1"
    git push

main:
    just -l
    # just touchp .github/workflows/build.yml
    # just touchp lib/main.dart

# Create nested parent directories and touch a file
touchp file_path:
    mkdir -p "$(dirname "{{file_path}}")" \
    && touch "{{file_path}}"


make:
    # 1. Initialize git locally
    git init
    git add .
    git commit -m "Fresh start with cloud generation"

    # 2. Tell git to use your working token to talk to GitHub
    # git remote add origin https://github.com/ali1913/t2.git

    # 3. Force push to clear out any older broken files in your repository
    git branch -M main
    git push -u origin main --force

t2:
    git init
    git add .
    git commit -m "first commit"
    git branch -M main
    git remote add origin https://github.com/ali1913/t2.git
    git push -u origin main



# FlutterBot
# flutter2172bot
# Done! Congratulations on your new bot. You will find it at t.me/flutter2172bot. You can now add a description, about section and profile picture for your bot, see /help for a list of commands. By the way, when you've finished creating your cool bot, ping our Bot Support if you want a better username for it. Just make sure the bot is fully operational before you do this.

# Use this token to access the HTTP API:
# 8831364449:AAFDX9RwHOzWbC6M4mtAI3EySyw69j3EzH4
# Keep your token secure and store it safely, it can be used by anyone to control your bot.

# For a description of the Bot API, see this page: https://core.telegram.org/bots/api

# https://telegram.org/flutter2172bot


# doc:
# docker run --rm -v "$(pwd)":/app -w /app ghcr.io/cirruslabs/flutter:stable bash build.sh


get:
    gh run download --name release-apk
