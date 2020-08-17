# volume-tester

Deploy into your OCP cluster, set the environment variable `VOLUME_TEST_FILE`, and curl the app.  It will try to write then read the file specified, and will tell you the results of the attempt.

## To test your PVC

### 1. Deploy app to the cluster with a PVC

Setting up your storage is outside the scope of this.  You should either have dynamic provisioning set up, or statically create the PVs required to satisfy the PVC claims.

#### Create the PVC

If you have dynamic provisioning set up via a StorageClass, creating the PVC should be enough to get the PV created (Note that some CSI providers don't provision the PV until it's actually needed).

Example PVC:

```yaml
- apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: pvc-test-volume-claim
  spec:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 1Gi
    # This storageClassName must be correct for your cluster storage solution
    storageClassName: gp2
```

#### Create the Deployment, Service, and Route:

```yaml
apiVersion: v1
kind: List
metadata: {}
items:
- apiVersion: v1
  kind: Service
  metadata:
    labels:
      app: pvc-volume-test
    name: pvc-volume-test
  spec:
    ports:
    - name: 8080-tcp
      port: 8080
      protocol: TCP
      targetPort: 8080
    selector:
      app: pvc-volume-test
- apiVersion: route.openshift.io/v1
  kind: Route
  metadata:
    labels:
      app: pvc-volume-test
    name: pvc-volume-test
  spec:
    port:
      targetPort: 8080-tcp
    to:
      kind: Service
      name: pvc-volume-test
      weight: 100
    wildcardPolicy: None
- apiVersion: apps/v1
  kind: Deployment
  metadata:
    labels:
      app: pvc-volume-test
    name: pvc-volume-test
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: pvc-volume-test
    template:
      metadata:
        labels:
          app: pvc-volume-test
      spec:
        containers:
        - image: quay.io/freedomben/volume-tester:latest
          name: metals
          imagePullPolicy: Always
          ports:
          - containerPort: 8080
            protocol: TCP
          env:
          - name: VOLUME_TEST_FILE
            value: '/mnt/some/directory/volume-test-file.txt'
          volumeMounts:
          - mountPath: "/mnt/some/directory"
            name: pvc-test-volume
        # Change this Volumes section to match a  PVC you created for your storage backend
        volumes:
        - name: pvc-test-volume
          persistentVolumeClaim:
            claimName: pvc-test-volume-claim
```

### 2.  Test basic reading/writing to the volume

1.  To test basic reading/writing:  `curl http://<app-route>/readwrite`

### 3.  Test Persistence

1.  First make sure the read test fails:  `curl http://<app-route>/read`
1.  Now write the test string to a file:  `curl http://<app-route>/write`
1.  Delete and recreate the Pod (so that the volume gets detached and reattached by your storage solution
1.  Read the file and verify contents persisted:  `curl http://<app-route>/read`
1.  You can clear the test file contents for repeated testing:  `curl http://<app-route>/clear`

## Endpoints (RPC-style):

* `/readwrite`:  Writes and then reads a string to the file.  This can determine if there are any permission issues in place.
* `/write`:  Writes a static test string to the file which can be checked with `/read`
* `/read`:  Checks that the test file has the static test string as it's contents
* `/clear`:  Writes an empty string to the test file
