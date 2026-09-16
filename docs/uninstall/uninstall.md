### Uninstall ###

To uninstall an Ascender deployment instance, you basically need to remove the Ascender object related to that instance. For example, to delete an Ascender instance named ascender-demo, you would do:

```
$ kubectl delete ascender ascender-demo
ascender.ascender.ansible.com "ascender-demo" deleted
```

Deleting an Ascender instance will remove all related deployments and statefulsets, however, persistent volumes and secrets will remain. To enforce secrets also getting removed, you can use `garbage_collect_secrets: true`.

**Note**: If you ever intend to recover an Ascender from an existing database you will need a copy of the secrets in order to perform a successful recovery.
