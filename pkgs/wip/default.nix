{ lib, stdenv, fetchFromGitLab, fetchFromGitHub, fetchgit }:

stdenv.mkDerivation {
  name = "hithere";

  # RESULTING ERROR:
  # git@github.com: Permission denied (publickey).
  # fatal: Could not read from remote repository.

  # Please make sure you have the correct access rights
  # and the repository exists.
  # error: program 'git' failed with exit code 128
  src = builtins.fetchGit {
    url = "git@github.com:TimekillerTK/fix-show-name.git";
    ref = "main";
    rev = "65242d532f3cab5588ef07fa51be2facdec8a9d2";
    shallow = true;
  };

  # RESULTING ERROR:
  # > Initialized empty Git repository in /nix/store/cqm76gjzjbrhy8yfz3ax445362f2z3k5-fix-show-name-65242d5/.git/
  #      > error: cannot run ssh: No such file or directory
  #      > fatal: unable to fork
  #      > error: cannot run ssh: No such file or directory
  #      > fatal: unable to fork
  #      > error: cannot run ssh: No such file or directory
  #      > fatal: unable to fork
  # src = fetchgit {
  #   url = "git@github.com:TimekillerTK/fix-show-name.git";
  #   rev = "65242d532f3cab5588ef07fa51be2facdec8a9d2";
  # };

}
