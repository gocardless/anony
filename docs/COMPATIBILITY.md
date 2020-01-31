# Compatibility

Our goal as Anony maintainers is for the library to be compatible with all supported versions of Ruby.

Specifically, any CRuby/MRI version that has not received an End of Life notice ([e.g. this notice for Ruby 2.1](https://www.ruby-lang.org/en/news/2017/04/01/support-of-ruby-2-1-has-ended/)) is supported.

To that end, [our build matrix](../.circleci/config.yml) includes all these versions.

Any time Anony doesn't work on a supported version of Ruby, it's a bug, and can be reported [here](https://github.com/gocardless/anony/issues).

# Deprecation

Whenever a version of Ruby falls out of support, we will mirror that change in Anony by updating the build matrix and releasing a new major version.

At that point, we will close any issues that only affect the unsupported version, and may choose to remove any workarounds from the code that are only necessary for the unsupported version.

We will then bump the major version of Anony, to indicate the break in compatibility. Even if the new version of Anony happens to work on the unsupported version of Ruby, we consider compatibility to be broken at this point.
