# Contributing

For general contribution and community guidelines, please see the [community repo](https://github.com/cyberark/community).

## Contributing

1. [Fork the project](https://help.github.com/en/github/getting-started-with-github/fork-a-repo)
2. [Clone your fork](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/cloning-a-repository)
3. Make local changes to your fork by editing files
3. [Commit your changes](https://help.github.com/en/github/managing-files-in-a-repository/adding-a-file-to-a-repository-using-the-command-line)
4. [Push your local changes to the remote server](https://help.github.com/en/github/using-git/pushing-commits-to-a-remote-repository)
5. [Create new Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork)

From here your pull request will be reviewed and once you've responded to all
feedback it will be merged into the project. Congratulations, you're a
contributor!

## Development

Create a sandbox environment in Docker using the `./dev` folder:

```sh-session
$ cd dev
dev $ ./start.sh
```

This will drop you into a bash shell in a container called `cli`.

The sandbox also includes a Postgres container and Conjur server container. The
environment is already setup to connect the CLI to the server:

* **CONJUR_APPLIANCE_URL** `http://conjur`
* **CONJUR_ACCOUNT** `cucumber`

To login to conjur, type the following and you'll be prompted for a password:

```sh-session
root@2b5f618dfdcb:/# conjur authn login admin
Please enter admin's password (it will not be echoed):
```

The required password is the API key at the end of the output from the
`start.sh` script.  It looks like this:

```
=============== LOGIN WITH THESE CREDENTIALS ===============

username: admin
api key : 9j113d35wag023rq7tnv201rsym1jg4pev1t1nb4419767ms1cnq00n

============================================================
```

At this point, you can use any CLI command you like.

## Running Cucumber

To install dev packages, run `bundle` from within the container:

```sh-session
root@2b5f618dfdcb:/# cd /usr/src/cli-ruby/
root@2b5f618dfdcb:/usr/src/cli-ruby# bundle
```

Then you can run the cucumber tests:

```sh-session
root@2b5f618dfdcb:/usr/src/cli-ruby# cucumber
...
```
