# Development Workspace
This repository is a workspace that utilizes Docker to create a isolated and reproducible development environment for git projects.

## How to install
Fork this repository so you can create your own `configuration.json` file and merge changes from later versions of this repository successfully.

## Workspace Configuration
The `configuration.json` file contains all the configurations passed on to docker.

### Example Configuration File
```JSON
{
	"packages":
	[
		"locales",
		"make",
		"g++",
		"vim"
	],
	
	"repositories":
	[
		{
			"URL": "https://github.com/akashington/vim-dotfiles",
			"directory": "/home/development/vim-dotfiles"
		},
		{
			"URL": "https://github.com/akashington/workspace",
			"directory": "/home/development/workspace"
		},
		{
			"URL": "https://github.com/akashington/development-workspace",
			"directory": "/home/development/development-workspace"
		},
		{
			"URL": "https://github.com/akashington/velkro",
			"directory": "/home/development/velkro"
		}
	],

	"post-build-commands":
	[
		"ln -sf /home/development/vim-dotfiles/.vimrc /home/development/.vimrc",
		"ln -sf /home/development/vim-dotfiles/.vim /home/development/.vim",
		"sudo locale-gen en_US.UTF-8",
		"sudo update-locale LANG=en_US.UTF-8"
	],

	"startup-command": "env LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 bash -c 'vim; exec bash'"
}
```

## Installation
Building the docker image and running it is extremely simple, you only need to run:
```bash
docker build -t [name]
docker run [name]
```

## License
```
MIT License

Copyright (c) 2025 akashington

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

happy coding! ☺