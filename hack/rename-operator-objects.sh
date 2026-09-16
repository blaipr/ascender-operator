#!/bin/bash

# Remove the operator's old awx-operator-* objects after it has been renamed.
#
# The operator's own objects are named by a kustomize namePrefix, which moved
# from awx-operator- to ascender-operator-. Kubernetes has no rename, and
# kubectl apply only creates or updates the names in the manifest it is given,
# so an upgrade leaves the eleven old objects in place beside the eleven new
# ones, including a second operator Deployment.
#
# That overlap is not dangerous while both pass --leader-election-id=awx-operator:
# they contend for one lease and only one of them is ever active. The old set is
# still worth removing, and this removes it.
#
# The one thing it will not do is delete a CustomResourceDefinition. Reaching
# for `kubectl delete -k config/default` instead of this script would do exactly
# that, because config/default includes ../crd, and deleting those CRDs cascades
# to every AWX and Ascender in the cluster, which is every deployment.
#
# This is not the script that moves a deployment across. That is
# migrate-awx-to-ascender.sh, and README.md says which you want.
#
# Usage:
#   ./hack/rename-operator-objects.sh -n <namespace>            # shows what it would delete
#   ./hack/rename-operator-objects.sh -n <namespace> --apply    # deletes it

set -euo pipefail

NAMESPACE=""
APPLY=false
OLD_PREFIX="awx-operator-"
NEW_PREFIX="ascender-operator-"

log()  { printf '%s\n' "$*"; }
step() { printf '\n== %s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        -n|--namespace) NAMESPACE="$2"; shift 2 ;;
        --apply)        APPLY=true; shift ;;
        --old-prefix)   OLD_PREFIX="$2"; shift 2 ;;
        --new-prefix)   NEW_PREFIX="$2"; shift 2 ;;
        -h|--help)      sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *)              die "unknown argument $1" ;;
    esac
done

[ -n "$NAMESPACE" ] || die "a namespace is required, pass -n"
command -v kubectl >/dev/null || die "kubectl is not on PATH"

KC="kubectl -n $NAMESPACE"

# Namespaced first, then the two that are not. No CRD appears here, and none
# ever should: see the note at the top.
NAMESPACED="deployment serviceaccount service role rolebinding configmap"
CLUSTER="clusterrole clusterrolebinding"


step "Looking for the new objects first"

# Deleting the old set before the new one exists would leave no operator at all.
if ! $KC get "deployment/${NEW_PREFIX}controller-manager" >/dev/null 2>&1; then
    die "there is no ${NEW_PREFIX}controller-manager in $NAMESPACE. Apply the new manifests first: this only removes what they replace."
fi
log "  ${NEW_PREFIX}controller-manager is there"


step "Old objects still present"

FOUND=""
for kind in $NAMESPACED; do
    while read -r name; do
        [ -n "$name" ] || continue
        case "$name" in
            "${OLD_PREFIX}"*) FOUND="${FOUND}${kind}/${name}"$'\n' ;;
        esac
    done < <($KC get "$kind" -o custom-columns=:metadata.name --no-headers 2>/dev/null || true)
done
for kind in $CLUSTER; do
    while read -r name; do
        [ -n "$name" ] || continue
        case "$name" in
            "${OLD_PREFIX}"*) FOUND="${FOUND}${kind}/${name}"$'\n' ;;
        esac
    done < <(kubectl get "$kind" -o custom-columns=:metadata.name --no-headers 2>/dev/null || true)
done

FOUND=$(printf '%s' "$FOUND" | sed '/^$/d')

if [ -z "$FOUND" ]; then
    log "  none, nothing to do"
    exit 0
fi

printf '%s\n' "$FOUND" | sed 's/^/    /'

if ! $APPLY; then
    step "Plan"
    log "  delete each of the above, and nothing else."
    log "  No CustomResourceDefinition is touched, so no deployment is affected."
    log "  Re-run with --apply."
    exit 0
fi


step "Deleting"

while read -r ref; do
    [ -n "$ref" ] || continue
    case "$ref" in
        *customresourcedefinition*|*crd*)
            die "refusing to delete $ref: deleting a CRD cascades to every deployment in the cluster" ;;
    esac
    case "${ref#*/}" in
        "${OLD_PREFIX}"*) ;;
        *) die "refusing to delete $ref: it does not start with $OLD_PREFIX" ;;
    esac
    case "$ref" in
        clusterrole/*|clusterrolebinding/*) kubectl delete "$ref" --wait=true >/dev/null ;;
        *)                                  $KC delete "$ref" --wait=true >/dev/null ;;
    esac
    log "  deleted $ref"
done <<< "$FOUND"


step "Done"
log "  the old $OLD_PREFIX objects are gone, and ${NEW_PREFIX}controller-manager is the only operator left."
