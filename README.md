Repeatability instructions KeYmaera X:
1. Rename `wolfram_creds.env.example` to `wolfram_creds.env`
2. Edit `wolfram_creds.env` with your Wolfram Credentials.
3. Run `setup.sh`, this will initialize the Docker container, install Wolfram Engine and Matlab, and build KeYmaera X. It will also run the benchmarks.
4. Run `main.py` this will produce results.csv in the results folder
