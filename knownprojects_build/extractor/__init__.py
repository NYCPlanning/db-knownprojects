import os
from pathlib import Path
cwd = os.getcwd()

msg = "You are executing in the wrong directory, make sure you are in knownprojects_build"
assert Path(cwd).name == 'knownprojects_build', msg