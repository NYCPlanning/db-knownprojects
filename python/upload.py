from github import Github
from datetime import datetime as dt
import os
import glob
import sys

# Initialize github and repo
g = Github(os.environ.get("ARD_PAT"), timeout=60, retry=10)
repo = g.get_repo("NYCPlanning/db-knownprojects-data")


def create_new_branch(target_branch: str, source_branch: str = "main"):
    """
    This function will create a new branch based on source_branch,
    named after target_branch. source_branch is default to main
    """
    ref_target_branch = f"refs/heads/{target_branch}"
    src = repo.get_branch(source_branch)
    repo.create_git_ref(ref=ref_target_branch, sha=src.commit.sha)
    print(f"created branch: {ref_target_branch}")


def upload_file(path_local: str, path_repo: str, target_branch: str, message: str = ""):
    """
    this function will upload a given file to a given target_branch
    path_local: local file path relative to knownprojects_build
    path_repo: relative file path within in the repo
    target_branch: the branch to commit files to
    message: commit message that goes along with the file upload
    """
    src = repo.get_branch(target_branch)
    with open(path_local, "rb") as f:
        content = f.read()
    repo.create_file(path_repo, message, content, branch=target_branch, sha=src.commit.sha)
    print(f"uploaded: {path_repo}")


def create_pull_request(title: str, body: str, head: str, base: str = "main"):
    pr = repo.create_pull(title=title, body=body, head=head, base=base)
    print(pr.number)
    os.system(f'echo "::set-output name=issue_number::{pr.number}"')

if __name__ == "__main__":
    # List all files under output
    SENDER = sys.argv[1]
    basepath = os.getcwd()
    file_list = glob.glob(basepath + "/output/**", recursive=True)
    file_list = [f for f in file_list if os.path.isfile(f)]

    # Create a new target branch
    timestamp = dt.now()
    title = timestamp.strftime("%Y-%m-%d %H:%M")
    target_branch = timestamp.strftime("output-%Y%m%d-%H%M")
    create_new_branch(target_branch)

    # Upload files one by one
    for _file in file_list:
        _file_repo = _file.replace(basepath + "/", "")
        message = f"🚀 {target_branch} -> {_file_repo}..."
        upload_file(_file, _file_repo, target_branch, message)

    # Create a PR after upload
    md_file_list = "\n".join([f" - `{f.replace(basepath+'/', '')}`" for f in file_list])
    body = f"## Files Commited:\n{md_file_list}\n"

    pr = create_pull_request(
        title=f'output: {timestamp.strftime("%Y-%m-%d %H:%M")}, created by: {SENDER}',
        body=body,
        head=target_branch,
    )
