#!/bin/bash

#	Backs up files and database of a retrospectiva instalation.
#	@Author: Matheus Elias Muller
#	@Email: hello at memuller dot com
#	@Copyright: Fundação João Paulo II - Brazil.
#	@Version: auto-generated, see git repository.

error(){
	echo "!! ERRO: ${1}"
	cd $OLD_DIRECTORY
	exit 1
}

info(){
	echo "* ${1}"
}

OLD_DIRECTORY= "$(pwd)"
REMOTE_SVR="projetoscn.memuller.com"
REMOTE_SVR_ADDR="projetoscn.memuller.com"
REMOTE_USR="cn_git"
REMOTE_REPO_PATH="~/repos/bare"
REMOTE_REPO_CURRENT="~/repos/current"

echo "======= GIT REPOSITORY SETUP ======="
info "Este configurará o repositório atual para utilizar o servidor Git como origem."

info "Insira o caminho para o repositório do aplicativo (ou pressione enter para usar o diretório atual)"
read DIRECTORY

info "Insira o nome para este projeto no servidor (sem espaços, maiúsculas ou acentuação); ou presione enter para utilizar o diretório atual."
info "ex.: iptv, intranet, cadastro_paroquias_capelas"
read NAME

#checks if the server alias is properly set, sets it otherwise
#if [[ "$(grep $REMOTE_SVR /etc/hosts)" == "" ]]; then
#	info "Será pedida agora a sua senha de root, para registro do endereço do servidor:"
#	sudo echo "$REMOTE_SVR_ADDR      $REMOTE_SVR" >> /etc/hosts
#fi

#cd's to the working directory, if needed
if [[ "$DIRECTORY" != "" ]]; then
	cd $DIRECTORY
fi

#sets NAME to the current dir, if it was not specified
if [[ "$NAME" == "" ]]; then
	NAME="$(basename `pwd`)"
fi

#checks if the directory is a git repo
if [[ $(git status >> /dev/null) -ne "0" ]]; then
	error "Diretório não é um repositório git, ou git não está instalado."
fi

#check if there's a repo with this name on the remote
ssh $REMOTE_USR@$REMOTE_SVR cd $REMOTE_REPO_PATH/$NAME >> /dev/null
if [[ ! "$?" == "0" ]]; then
	error "Repositório não foi encontrado no servidor. Certifique-se que grafou o nome corretamente, e que o mesmo já foi criado por um administrador."
fi

#sets the remote repo as origin
git checkout master
if [[ "$?" -ne "0" ]]; then
	error "Erro ao trocar branches. É preciso estar no branch master antes de realizar o upload."
fi
git remote add origin -m master -t master $REMOTE_USR@$REMOTE_SVR:$REMOTE_REPO_PATH/$NAME
info "Repositório remoto adicionado."

#pulls from the server
info "Tentando um pull..."
git pull origin master

#ends
cd $OLD_DIRECTORY
exit 0







