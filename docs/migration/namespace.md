# Moving a deployment to the ascender namespace

A fresh install lands in the `ascender` namespace. An install made before that
lands in `awx`, and it keeps working there indefinitely.

## Nothing happens to an existing install

The operator is namespace scoped: `WATCH_NAMESPACE` is its own namespace, so the
operator running in `awx` manages the deployment in `awx` and nothing else. That has
one consequence worth being plain about.

Applying the new manifests over an install that lives in `awx` **does not move it**.
It stands a second operator up in a new `ascender` namespace, watching nothing, while
the old operator carries on managing the deployment exactly as before. Nothing breaks,
and nothing is upgraded either. If that is what happened, delete the objects in the
`ascender` namespace and carry on: the deployment was never touched.

## Why there is no in-place move

A Kubernetes object cannot change namespace. Neither can a PersistentVolumeClaim, so
the database cannot simply follow. Moving a deployment across is a backup taken in one
namespace and restored in another, which means downtime and a verified backup, not an
upgrade.

## The shape of the move

1. Take a backup in the old namespace with an `AscenderBackup`, and wait for it to
   report a `backupDirectory` in its status.
2. Copy the backup out of its PersistentVolumeClaim to somewhere outside the cluster.
   The installer repositories' backup roles do this with `k8s_cp`.
3. Create the new namespace and install the operator into it.
4. Put the backup where the new namespace can reach it, in a claim of its own.
5. Create an `AscenderRestore` in the new namespace pointing at that claim and the
   backup directory, with the secrets the backup recorded.
6. Check the restored deployment before deleting anything, then remove the old
   namespace once you are satisfied.

Steps 1, 2, 5 and 6 are the ordinary backup and restore procedure, which the backup and
restore role documentation covers in full. Nothing here is specific to the rename except
the reason for doing it.

## Whether it is worth doing

The namespace is a name, and the deployment works the same in either. The reasons to
move are consistency with a fleet of newer installs, and not having a namespace called
`awx` in a product called Ascender. Neither is urgent, and the move costs a maintenance
window, so an install that is happy where it is can stay there.
