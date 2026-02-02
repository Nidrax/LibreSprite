# Contributing

## Branching Model
We use the following branch structure to manage development:
- `trunk`: This is the development branch for Besprited. All new features and bug fixes are merged here first.
- `ls-develop`: This branch tracks the latest changes from LibreSprite's `master` branch.
  We periodically merge changes from LibreSprite into our `trunk` branch to stay up-to-date with their developments.
  ***Any fixes to bugs shared with common LibreSprite codebase should be made against `LibreSprite:master` directly.***

Feature and fix branches should follow the naming convention: `username/short-description`, for example: `nidrax/v8-build-fix-windows`.