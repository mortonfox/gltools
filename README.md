# Gitlab Tools

gltools is a set of scripts to do simple things with Gitlab. Currently, there
is only ``backup_repos.rb``, which downloads all of a user's repositories and
produces a git bundle and a zip file for each repository.

## Installation

Run ``bundle install`` to install the required gems.

You'll need to obtain an access token for the Gitlab API.

1. After logging in on Gitlab, go to [Personal Access Tokens](https://gitlab.com/profile/personal_access_tokens)
1. Enter ``gltools`` in the Name field.
1. Under Scopes, select 'api'.
1. Click on 'Create personal access token'.
1. Copy the access token from 'Your New Personal Access Token'.
1. Create a file named ``.gltools.token`` in your home directory.
1. Edit this file and add the token string only to the first line of the file.

## Usage

Run the following to back up your repos:

```sh
bundle exec ruby backup_repos.rb
```
