# Mkghrepo
Quick and dirty tool to mass create repositories on Github.

To install: `gem install mkghrepo`

Help:

```
Usage: mkghrepo [options] [<filename>]

Repository options:
    -p, --private      make the repository private
    -t, --create-team  creates a team called "<foo>-write", default is false
    --token            sets github token, defaults from GITHUB_TOKEN

Other options:
    -h, --help         print this help
    -v, --version      print the version
```

`mkghrepo` accepts one repository per line as input, either stored in a file or passed through STDIN, the formats supported are:

`<org>/<repo> [<user1> <user2> ... <userN>]`

or

`<repo>`

If users are listed and the `-t` flag has been specified in the run, a team called `<repo>-write` will be created and those users added to it. The users must already be part of the organization or they will be skipped (a warning will be displayed).

## Troubleshooting
By default, debug events are not logged, to see them, set `MKGHREPO_LOG` to `DEBUG` in your shell environment.
