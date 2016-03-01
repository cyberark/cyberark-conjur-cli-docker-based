# Publishing the CLI

We distribute the Conjur CLI as an Omnibus package for Ubuntu, Centos, OSX and also as a rubygem.

Experimentally, the CLI is also avaliable as a non-Omnibus deb package called 'rubygems-conjur-cli'
which depends on ruby2.0.

Steps to publish a new version of the CLI:

1. Update `VERSION` in [lib/conjur/version.rb](lib/conjur/version.rb)
2. Update the [CHANGELOG.md](CHANGELOG.md) with any changes for this version
3. Commit these changes with the message `"v#{VERSION}"`, where `VERSION` = the new version
4. Go to the specific build page for the commit [in Jenkins](https://jenkins.conjur.net/job/cli-ruby/)
5. In the left sidebar, open `Promotion Status`
6. Click `Approve` for the "rubygems" promotion and wait for it to finish
7. Click `Approve` for the "packages" promotion, this will kick off the [omnibus-conjur](https://jenkins.conjur.net/job/omnibus-conjur/) build flow [1](#ref1).
8. Download the [deb](https://jenkins.conjur.net/job/omnibus-conjur-ubuntu/), [rpm](https://jenkins.conjur.net/job/omnibus-conjur-centos/) and [pkg](https://jenkins.conjur.net/job/omnibus-conjur-osx/) packages from their build pages in Jenkins.
9. Move the downloaded files to the `pkg` folder in your local [omnibus-conjur](https://github.com/conjurinc/omnibus-conjur) project.
10. In the `omnibus-conjur` project, upload each file to S3 with `./publish pkg/<filename>`.
11. Update the links on the [CLI page](https://github.com/conjurinc/developer-www/blob/master/app/views/pages/cli/index.html.haml) for the devsite.
12. Promote the devsite to production [in Jenkins](https://jenkins.conjur.net/job/developer-www/) [2](#ref2).

Publishing the experimental deb:

1. `./build-deb.sh`
2 `summon -f ci/secrets/publish.yml ./publish.sh <component> <distribution>`

---

<a id="ref1">1</a>:
The packages promotion depends on the new gem version being published.

<a id="ref2">2</a>
After deploy it will take a few minutes for the cache to update.
