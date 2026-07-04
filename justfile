


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
