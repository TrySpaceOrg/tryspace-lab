# TrySpace Lab

Entrypoint for orchestrating full TrySpace simulation environments.

## Quick Start

Assuming you're running Linux, Mac, or Windows Subsystem for Linux you'll also need to install the following prerequisites:
* Docker Engine and Compose
* Make
* Git

Once you have those installed you can:
* Clone
  * `git clone https://github.com/TrySpaceOrg/tryspace-lab.git`
  * `cd tryspace-lab`
  * `git submodule update --init --recursive`
* Build
  * `make`
* Run
  * `make start`
* Use
  * Attach to containers
    * `docker attach tryspace-server`
  * Open GSW
    * `firefox localhost:8090`
* Stop
  * CTRL+C
  * Inspect volumes and logs as desired
  * `make stop`

## Documentation and Support

The full documentation for TrySpace Lab is available at [TrySpace Atlas](https://tryspaceorg.github.io/).

If you have questions, ideas, or need help, feel free to start a [GitHub Discussion](https://github.com/TrySpaceOrg/tryspace-lab/discussions).
Discussions are a great place to engage with the community and maintainers.

For bug reports or feature requests, please open a [GitHub Issue](https://github.com/TrySpaceOrg/tryspace-lab/issues).

## Licensing, Contributing, and Release Notes

This project is licensed under the [GNU Affero General Public License v3 (AGPLv3)](https://www.gnu.org/licenses/agpl-3.0.html).
By contributing, you agree that your contributions will also be licensed under the AGPLv3 or any other license explicitly noted in the repository.

We welcome contributions from everyone.
Please review our [Contributing Guidelines](CONTRIBUTING.md) for details on how to get started.

GitHub maintains the full set of [release notes](https://github.com/TrySpaceOrg/tryspace-lab/releases).
Here is the short history for quick reference:
* 0.0.0 - August 18th, 2025
  * Initial proof of concept
