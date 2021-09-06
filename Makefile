#!make

.ONESHELL:
SHELL=/bin/bash

SHARED_ROOT=/data/rw/group-maml
DATA_ROOT_DIR=$(SHARED_ROOT)/bergamot
CUDA_DIR=/usr/local/cuda-11.2

CONDA_ACTIVATE=source $(SHARED_ROOT)/mambaforge/etc/profile.d/conda.sh ; conda activate ; conda activate
LOCAL_GPUS=8

all: install-conda, install-snakemake, activate, dry-run

install-conda:
	wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$$(uname)-$$(uname -m).sh
	bash Mambaforge-$$(uname)-$$(uname -m).sh -p $(SHARED_ROOT)/mambaforge

install-snakemake:
	git submodule update --init --recursive
	$(CONDA_ACTIVATE) base
	mamba create -c conda-forge -c bioconda -n snakemake snakemake
	conda install -c bioconda snakefmt
	pip install shyaml

activate:
	$(CONDA_ACTIVATE) snakemake

dry-run:
	snakemake \
	  --use-conda \
	  --cores all \
	  -n

report_dir: activate
 	SRC=cat config.yml | shyaml get-value experiment.src
 	TRG=cat config.yml | shyaml get-value experiment.trg
 	EXPERIMENT=cat config.yml | shyaml get-value experiment.name
 	REPORT_DIR=$(DATA_ROOT_DIR)/reports/$SRC-$TRG/$EXPERIMENT

run-local: report_dir
	snakemake \
	  --use-conda --reason \
	  --cores all \
	  --resources gpu=$(LOCAL_GPUS) \
	  --report $REPORT_DIR/report.html

run-cluster: activate
	chmod +x profiles/snakepit/*
	snakemake \
	  --use-conda \
	  --cores all \
	  --profile=profiles/snakepit

dag:
	snakemake --dag | dot -Tpdf > DAG.pdf

lint:
	snakemake --lint

format:
	snakefmt --line-length 120 Snakefile

install-monitor:
	conda create --name panoptes
	conda install -c panoptes-organization panoptes-ui

run-monitor:
	$(CONDA_ACTIVATE) panoptes
	panoptes

run-with-monitor:
	snakemake \
	  --use-conda \
	  --cores all \
	  --wms-monitor http://127.0.0.1:5000

run-file-server: activate
	python -m  http.server --directory $(DATA_ROOT_DIR)/reports 8000

install-snakepit-scheduler:
	mkdir -p $(SHARED_ROOT)/snakepit
	cd $(SHARED_ROOT)/snakepit

	curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
	sudo apt install nodejs

	if [ ! -e snakepit-client ]; then
	  git clone https://github.com/mozilla/snakepit-client.git
	fi
	cd snakepit-client
	npm install
	sudo npm link

	echo "http://10.2.224.243" > /root/.pitconnect.txt

	pit status