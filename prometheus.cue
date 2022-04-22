package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

let _extraContainerPackages = [
	"curl",
	"build-essential",
	"nodejs"
]

dagger.#Plan & {
	client: {
		env: {
			PROMETHEUS_VERSION: string | *"main"
			GOLANG_VERSION: string | *"1.17"
		},

		filesystem: {
			"prometheus": {
				read: {
					contents: dagger.#FS
				}
			},
			"./bin/": {
				write: {
					contents: {
						actions.build.output.rootfs
					}
				}
			}
		}
	}

	actions: {
		_container: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: "golang:\(client.env.GOLANG_VERSION)"
				},
				docker.#Run & {
					command: {
						name: "apt-get"
						args: ["update"]
					}
				},
				docker.#Run & {
					command: {
						name: "bash"
						args: ["-c", "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -"]
					}
				},
				for pkg in _extraContainerPackages {
					docker.#Run & {
						command: {
							name: "apt-get"
							args: ["install", pkg],
							flags: {
								"-y": true
							}
						}
					}
				},
				docker.#Copy & {
					contents: client.filesystem."prometheus".read.contents,
					dest: "/src"
				}
			]
		}

		// Build Prometheus
		build: bash.#Run & {
			input: _container.output
			workdir: "/src"
			script: {
				contents: "make GO_ONLY=1"
			}

			export: {
				files: {
					"/src/prometheus": string
					"/src/promtool": string
				}
			}

			_copy: docker.#Copy & {
				input: rootfs: dagger.#Scratch
				contents: build.export.rootfs
				source: "/src/"
				include: ["/src/prometheus", "/src/promtool"]
			}
		}
	}
}