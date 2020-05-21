# Releasing
To cut a new release of Anony follow these steps:

1. Create a new branch for the release.
```sh
git checkout master
git pull origin master
git checkout -b v{VERSION}
```

2. Update the version of the library in `lib/anony/version.rb` following the
   semantic versioning guidelines.

3. Update the CHANGELOG.md file with the list of changes made since the last
   release, including the version for the current changes. Please note that the
   version must start with the character `v` in order to match the git tag that
   will be pushed in a later step.

4. Create a pull request for this release to merge the version branch into
   master.

5. Once the pull request is approved and merged, change branch to master and
   pull the changes.
```sh
git checkout master
git pull origin master
```

6. Create a tag for the version and push. Please note that the version tag must
   start with the character `v`. The automated release process in CircleCI will
   take over from here.
```sh
git tag v{VERSION}
git push --tags
```
