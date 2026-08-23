### Helm Install on existing cluster

For those that wish to use [Helm](https://helm.sh/) to install the ascender-operator to an existing K8s cluster:

The helm chart is generated from the `helm-chart` Makefile section using the starter files in `.helm/starter`. Consult [the documentation](https://github.com/ctrliq/ascender-operator/blob/devel/.helm/starter/README.md) on how to customize the AWX resource with your own values.

```bash
$ helm repo add ascender-operator https://ctrliq.github.io/ascender-operator/
"ascender-operator" has been added to your repositories

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "ascender-operator" chart repository
Update Complete. ⎈Happy Helming!⎈

$ helm search repo ascender-operator
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
ascender-operator/ascender-operator     25.5.1          25.5.1          A Helm chart for the Ascender Operator

$ helm install -n ascender --create-namespace my-ascender-operator ascender-operator/ascender-operator
NAME: my-ascender-operator
LAST DEPLOYED: Thu Feb 17 22:09:05 2022
NAMESPACE: ascender
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Helm Chart 25.5.1
```

Each release publishes the chart as an asset on its GitHub release, and the chart index served from the `gh-pages` branch of this repository points at those assets. A release made before the chart was published is not in the index, so `helm search repo` only lists the versions that carry one.
