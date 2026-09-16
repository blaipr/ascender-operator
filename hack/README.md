# hack

Four scripts. Two of them exist because the operator is moving from the AWX name
to the Ascender one, and which you need depends on what you are moving.

## Moving to Ascender

The two are separate on purpose. They act on different things, take different
arguments, and one of them is far more disruptive than the other.

**`rename-operator-objects.sh`** acts on the operator's own install. The operator's
objects are named by a kustomize prefix, which moved from `awx-operator-` to
`ascender-operator-`. Kubernetes has no rename and `kubectl apply` only touches the
names it is given, so an upgrade leaves eleven old objects beside eleven new ones,
including a second operator Deployment. This deletes the old set.

- Once per cluster, after upgrading the operator.
- Takes a namespace and nothing else.
- Touches no deployment and no database. Nothing stops serving.

**`migrate-awx-to-ascender.sh`** acts on one deployment. It moves it from the `AWX`
kind to the `Ascender` kind, which means renaming its database, swapping the custom
resource and rebuilding the workloads whose selectors cannot be changed.

- Once per deployment, when an administrator chooses to.
- Takes a namespace and the deployment's name.
- Has a window of downtime, and a `--rollback` and `--resume` for when it does not
  go to plan.

Neither needs the other. A cluster can rename its operator and leave every
deployment on the AWX kind, or move a deployment across and leave the operator
named as it is. If you are doing both, rename the operator first: the migration
needs a working operator to rebuild what it removes, and the rename never stops
one running.

Both print a plan and change nothing until given `--apply`.

## The other two

**`render-ascender-crds.py`** writes the `ascender.ansible.com` CRDs, samples and CSV
entries from the `awx.ansible.com` ones. `make crds` runs it, and CI fails if the
result differs from what is committed. Edit the AWX side; this moves the rest.

**`publish-to-operator-hub.sh`** opens the pull requests that publish a release to
community-operators and community-operators-prod.

## One rule worth repeating

Neither rename script will delete a CustomResourceDefinition, and neither should you.
`config/default` includes `../crd`, so reaching for `kubectl delete -k config/default`
takes the CRDs with it, and deleting those cascades to every AWX and Ascender in the
cluster, which is every deployment.
