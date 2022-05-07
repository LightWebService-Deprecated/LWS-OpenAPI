package lws_openapi

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	client: {
		filesystem: {
			"./":read: {
				contents: dagger.#FS
				exclude: [".idea"]
			}
			"./output": write: contents: actions.build.contents.output
		}
	},
	
	actions: {
		dependencies: docker.#Build & {
			steps: [
				docker.#Pull & {
					source: "node:slim"
				},
				
				bash.#Run & {
					workdir: "/"
					script: contents: #"""
						npm install -g @apidevtools/swagger-cli
					"""#
				},
				
				docker.#Copy & {
					contents: client.filesystem."./".read.contents
					dest: "/src"
				}
			]
		}

		build: {
			run: bash.#Run & {
				input: dependencies.output
				workdir: "/src"
				script: contents: #"""
					mkdir -p /out
					swagger-cli bundle auth/auth_swagger.yaml -o /output/auth.yaml -t yaml
				"""#
			}

			contents: core.#Subdir & {
				input: run.output.rootfs
				path: "/output"
			}
		}
	}
}