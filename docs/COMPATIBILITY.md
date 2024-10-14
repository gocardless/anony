# Compatibility

Our goal as Anony maintainers is for the library to be compatible with all supported versions of Ruby and Rails.

Specifically, any CRuby/MRI version that has not received an End of Life notice ([e.g. this notice for Ruby 2.1](https://www.ruby-lang.org/en/news/2017/04/01/support-of-ruby-2-1-has-ended/)) is supported. Similarly, any version of Rails listed as currently supported on [this page](http://guides.rubyonrails.org/maintenance_policy.html) is one we aim to support in Anony.

To that end, [our build matrix](../.github/workflows/test.yml) includes all these versions.

Any time Anony doesn't work on a supported combination of Ruby and Rails, it's a bug, and can be reported [here](https://github.com/gocardless/Anony/issues).

## Deprecation

Whenever a version of Ruby or Rails falls out of support, we will mirror that change in Anony by updating the build matrix and releasing a new minor version.

At that point, we will close any issues that only affect the unsupported version, and may choose to remove any workarounds from the code that are only necessary for the unsupported version.

We will then bump the minor version of Anony, to indicate the break in compatibility. Even if the new version of Anony happens to work on the unsupported version of Ruby or Rails, we consider compatibility to be broken at this point. We do not change the major version, as we are not making breaking changes to our API and we expect users of the gem to be keeping up to date with supported versions of Ruby and Rails.
