# Avalon
Avalon 6.0.x vagrant box

## Requirements

* [Vagrant](https://www.vagrantup.com/)
* [VirtualBox](https://www.virtualbox.org/)

## Usage

1. `git clone https://github.com/seanlw/avalon-vagrant.git`
2. `cd avalon-vagrant`
3. `vagrant up`
4. Visit [http://localhost:8888](http://localhost:8888)

Click the "Sign in" button and setup a new identity with `archivist1@example.com`.
This is the default identity with administration privileges.

Audio/Video files can be added to the `dropbox` folder in `avalon-vagrant`.

You can shell into the machine with `vagrant ssh` or `ssh -p 2222 vagrant@localhost`

Shutdown Avalon with `vagrant halt`

## Manual Install

Read the [Manual Install](Manual%20Install.md) document if you want to install these systems
on other boxes.

## Environment

* Ubuntu 14.04 64-bit machine with:
  * [MySQL](https://www.mysql.com/)
    * username = "root", password = "root"
    * Avalon db = "rails", username = "rails", password = "rails"
  * [Tomcat 7](http://tomcat.apache.org) at [http://localhost:8089](http://localhost:8089)
    * Manager username = "admin", password = "admin"
  * [Fedora 4.x](http://fedora.info/about) at [http://localhost:8984/fedora4/rest](http://localhost:8984/fedora4/rest)
    * No authentication configured
  * [Solr 6.4.2](http://lucene.apache.org/solr/) at [http://localhost:8983/solr/](http://localhost:8983/solr/), for indexing & searching your content.
  * [Matterhorn 1.4](http://www.opencast.org/matterhorn) at [http://localhost:8080]
    * username = "admin", password = "opencast"
  * [Red5 Media Server](http://red5.org/)
  * [Avalon 6.x](https://github.com/avalonmediasystem/avalon) at [http://localhost:8888](http://localhost:8888)

## Windows Troubleshooting

If you receive errors involving `\r` (end of line):

Edit the global `.gitconfig` file, find the line:
```
autocrlf = true
```
and change it to
```
autocrlf = false
```
Remove and clone again. This will prevent windows git clients from automatically replacing unix line endings LF with windows line endings CRLF.

## Maintainers

Current maintainers:

* [Sean Watkins](https://github.com/seanlw)

## Thanks

This VM setup was heavily influenced from [Islandora 2.x VM](https://github.com/Islandora-Labs/islandora_vagrant).
