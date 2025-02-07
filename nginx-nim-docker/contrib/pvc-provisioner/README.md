# Sample persistent volume dynamic provisioner

`dynamic-nfs-storage.yaml` can be used to spin up a dynamic persistent volumes provisioner relying on a NFS server. To deploy it:

1. Edit the Deployment in `dynamic-nfs-storage.yaml` setting the IP address and base path of an available NFS server:

```
[...]
          env:
            [...]

            ### CONFIGURE HERE NFS SERVER IP ADDRESS AND BASE PATH
            - name: NFS_SERVER
              value: <NFS_SERVER_IP_ADDRESS_GOES_HERE>
            - name: NFS_PATH
              value: <NFS_SERVER_BASE_PATH>
            ###
      volumes:
        - name: nfs-client-root
          nfs:
            ### CONFIGURE HERE NFS SERVER IP ADDRESS AND BASE PATH
            server: <NFS_SERVER_IP_ADDRESS_GOES_HERE>
            path: <NFS_SERVER_BASE_PATH>
            ###
```

2. Deploy it:

```
kubectl apply -f dynamic-nfs-storage.yaml
```

3. Two storage classes are created for persistent and disposable PVCs:

```
$ kubectl get storageclass
NAME                                   PROVISIONER                                   RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
managed-nfs-storage-delete             k8s-sigs.io/nfs-subdir-external-provisioner   Delete          Immediate           false                  82d
managed-nfs-storage-retain (default)   k8s-sigs.io/nfs-subdir-external-provisioner   Delete          Immediate           false                  82d
```

4. `test-retain.yaml` and `test-delete.yaml` can be used for testing purposes
