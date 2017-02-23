docker-boilerplate
==================

Boilerplate that I end up throwing in containers constantly.

Rather fresh, so docs are fairly lacking. Sorry bruh.

Check out `image/bin`, `image/sbin` and the `Dockerfile`. 
Everything here is dead simple shell scripts for the most part.


What is this?
-------------

A batteries included but not required approach to reusable tiny components to assist you with your container builds.

As a bonus, your `Dockerfile`s will go from a `4` that thinks it's a `9` to maybe actually being a humble `7`.

Comes with unlimited lifetime money back guarantee.

* A docker image `trevorj/boilerplate` you can use as a base (I certainly do!)
    * Includes tiny third party utilities (from apt or compiled as part of the `Makefile`):
        * `dumb-init`: The `entrypoint` uses this to deal with reaping.
        * `gosu`: for swapping privileges if you must. Helps local dev and delevation of privileges at runtime.
        * `dockerize`: for templating files at runtime and providing convenient facilities such as an a log tailer
          for those nasy apps that don't provide decent stdout/stderr (Hi `nginx`).

* A repository full of niceities you can also just copy into your own where using this base image is not applicable. At
  least your Dockerfiles will be prettier and less error prone.
    * `image/lib.sh`: Tiny reusable shell library handling the common cases of logging, matching, and other utilities.
    * Easily traceable and debuggable via `DEBUG`, `TRACE`, and `QUIET` env vars that also happen to apply to anything
    using the simple logging facilities in `image/lib.sh` that are easier than echo.


Batteries?
----------

* Well thought out layout that doesn't interfere with existing images and allows for easy local development.
    * Doesn't pit local development and securing your images (ie not running as root) against each other.
    * Smoothes local development as your application doesn't stomp over your image facilities when
        volume(s) are mounted over them.
    * Image root is `/image`. App root is `/app`, which I've found intuitively makes sense for everyone, myself
    included, while also being less to type. win/win.
        *These should never be hard coded, but are set as env vars in the `Dockerfile` here to be configurable.*

* `entrypoint`: A simple bash-only hookable entrypoint that makes it easy to make an image that isn't painful to use.
    * Hookable by adding hook-named executables (and/or sourceable shell scripts to modify functionality)
    to any directory in `ENTRYPOINT_PATH`, such as `/image/entrypoint.d/` and `/app/entrypoint.d/`.
    * All apps run in `/app` and (optionally but preferably) as the `app` user.
    No more guesswork; consistency is important, damnit.
    * `PATH` is chosen wisely, and includes `/app/image/bin`, `/image/bin`; read through it, it's tiny!
    Stop putting binaries all over the filesystem. You're only hurting your own iteration speed and later self.
    * Utilizes `dumb-init` to run your `CMD` unless you tell it not to.

* `lazy-apt`: Does an `apt-get` install but also cleans up after itself as well as updating repository lists lazily.
* `lazy-apt-with`: Runs `lazy-apt` with a list of packages required temporarily to run a command, such as
    development headers and a compiler. After that, it runs a specified command (such as `pip install`),
    before removing the packages and cleaning up after itself.
    * The key is it makes this *easy*, which means it will actually be done instead of leaving unneeded bload in your images.
* `lazy-apt-repo`: Cleanly add your APT package repositories.

* `install-reqs`: Let's stop putting requirements in Dockerfiles, it helps no one. Currently supports `pip` and
    `apt`.
    * For `apt` at least, it checks for package state beforehand and shortcuts if all are already there.

* `build-parts`: Like run-parts, but meant for build steps in your images as it cleans up after itself.

* `at-runtime`: Register commands to be executed at image runtime from your build steps in one go.

* `wait-for-linked-services`: As the name suggests. https://github.com/akatrevorjay/wait-for-linked-services

* `image-cleanup`: No idea. Judging by the name it's a virus.

* `image-save-requires`: This generates current package states for both APT and pip (more welcome), and even
    delivers diffs so you can easily see what's been changed from the image. Very useful in dealing with ad-hoc
    cowboy moments (hopefully in local dev) *yeehaw*.

* Others not worthy of being put here.

