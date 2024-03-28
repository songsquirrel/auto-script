# installs NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# need restart terminal to use nvm
# download and install Node.js
nvm install 20

# verifies the right Node.js version is in the environment
node -v # should print `v20.11.1`

# verifies the right NPM version is in the environment
npm -v # should print `10.2.4`


# 参考文档:https://nodejs.org/en/download/package-manager