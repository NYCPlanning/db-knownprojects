import os
from datetime import datetime
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine

# Today's date
DATE = datetime.today().strftime("%Y-%m-%d")

# Load environmental variables
load_dotenv()
BUILD_ENGINE = os.environ["BUILD_ENGINE"]
engine = create_engine(BUILD_ENGINE)

# Create temporary output directories
current_dir = os.getcwd()
output_dir = f"{current_dir}/.output"

msg = (
    "You are executing in the wrong directory, make sure you are in knownprojects_build"
)
assert Path(current_dir).name == "knownprojects_build", msg

if not os.path.isdir(output_dir):
    os.makedirs(output_dir, exist_ok=True)
    # create .gitignore so that files in this directory aren't tracked
    with open(f"{output_dir}/.gitignore", "w") as f:
        f.write("*")
