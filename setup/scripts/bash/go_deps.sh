#!/bin/bash
function download_go_deps(){
if [[ -f "go.mod" ]]; then
	go get -u
	go mod tidy
	go get -v golang.org/x/tools/gopls@latest
	go get -v golang.org/x/tools/cmd/goimports
	go get -v github.com/rogpeppe/godef
	go get -v golang.org/x/tools/gopls
fi
}

download_go_deps
