# intEL4CoRo Juypterbook

**Generate Jupyter Book website for IntEL4CoRo textbook.**

Overall process (latex => markdown => html):

1. Convert Latex (.tex) files to markdown files with the converter [Pandoc](https://pandoc.org/).
2. Modify the generated MD file (e.g.,split chapter into subchapters).
3. Extra process like copy images, reference.bib.
4. Build the Juptyer Book html from markdown files.

## Getting started with BinderHub

### Step by Step

1. Open link [https://binder.intel4coro.de/v2/gh/yxzhan/docker-stacks.git/textbook?labpath=tex2jb.ipynb](https://binder.intel4coro.de/v2/gh/yxzhan/docker-stacks.git/textbook?labpath=tex2jb.ipynb)
1. Upload the Latex project (e.g., `content/intel4coroTextbook/`) and name the folder to `intel4coroTextbook`.
1. Execute notebook `tex2jb.ipynb`
1. The exported files are under folder `html`
