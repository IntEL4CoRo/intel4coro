# To run jupyterlab with commonlisp kernel on Jupyterhub 

1. Login: https://jupyter.zmml.uni-bremen.de/ (only accesible for users who have access rights)
2. Select Intel4coro:Cram

# To run jupyterlab with commonlisp kernel locally

1. Clone this repo
2. Uncomment (remove # from line 110)
3. Go to folder of dockerfile. Build the image `docker build -t <image_name> .`
4. RUN:- `docker run -p 8888:8888 <image_name>`



