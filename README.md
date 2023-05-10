# intEL4CoRo Juypterbook
**Generate Jupyter Book website for IntEL4CoRo textbook.**

Overall process (latex => markdown => html): 
1. Convert Latex (.tex) files to markdown files with the converter [Pandoc](https://pandoc.org/). 
2. The python notebook `docker/tex2md.ipynb` customizes the generated MD files (e.g.,split chapter into subchapters).
3. Build the Juptyer Book html from markdown files.

## Getting started with Docker
### Prerequisites
* Install [Docker](https://www.docker.com/)

### Step by Step
1. Update intEL4CoRo SVN repo with `svn update`.
1. Copy the textbook content folder (content/intel4coroTextbook/) here.
1. Run script `./run.sh` in terminal (Probably need to add execution permission with 'chmod +x ./run.sh').

        ./run.sh

1. Open file `jupyterbook/_build/html/index.html` in web browser.


## Development
1. Run script:

        ./run.sh --develop

1. Open jupyterlab http://127.0.0.1:8888/lab

1. Execute python notebook http://127.0.0.1:8888/lab/tree/docker/tex2md.ipynb
