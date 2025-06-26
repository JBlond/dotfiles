# Git Create Empty Branch

To create a new empty branch in Git, we can use the `--orphan` command line option

```bash
git checkout --orphan <newemptybranchname>
```

The command above creates the new empty branch and switches into it.
Once the empty branch s created, we can can delete files from the working directory, so they are not committed in to the new branch

```bash
git rm -rf .
```

Now you are in the empty branch without any inherited files or commits.
If you want to push your empty branch to a remote repository, do the following

```bash
git commit --alow-empty -m "Init"
git push origin <newemptybranchname>
```

Note, that if you try to merge another branch into the empty one, you will receive the error: `fatal: refusing to merge unrelated histories`

Use the `--allow-unrelated-history<` option to force the merge into the empty branch.

```bash
git merge --allow-unrelated-history <branchname>
```
