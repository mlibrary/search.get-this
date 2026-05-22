#!/bin/bash

#must be run from the project root directory
if [ -f ".env" ]; then
  echo "🌎 .env exists. Leaving alone"
else
  echo "🌎 .env does not exist. Copying env.example to .env"
  cp env.example .env
fi

if [ -f ".git/hooks/pre-commit" ]; then
  echo "🪝 .git/hooks/pre-commit exists. Leaving alone"
else
  echo " 🪝 .git/hooks/pre-commit does not exist. Copying .github/pre-commit to .git/hooks/"
  cp .github/pre-commit .git/hooks/pre-commit
fi

echo "🚢 Build docker images"
docker compose build

echo "📦 Installing Gems"
docker compose run --rm web bundle

echo "📦 Installing Node modules"
docker compose run --rm css npm install

echo "📦 Building css and js"
docker compose run --rm css npm run build

