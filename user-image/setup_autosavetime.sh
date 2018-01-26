# Install nb extensions
pip install jupyter_contrib_nbextensions
# We install, ignoring running servers
jupyter contrib nbextensions install --sys-prefix --skip-running-check
# Enable autosavetime which will by default disable autosave
jupyter nbextension enable autosavetime/main
