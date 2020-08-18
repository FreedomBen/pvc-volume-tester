# volume-tester

This volume tester is a simple web app will help you verify persistent storage is working correctly in your OpenShift or Kubernetes cluster.  It just reads/writes to a file on the volume and tells you whether it is reading/writing and persisting properly.

There are a few endpoints you can use to control it (made to be easy with curl).  It can read/write to a file on the volume and thus determine whether your storage is persisting across pods and has working permissions.

The only configuration required for the app is to tell it where the test file will be.  For security reasons this must be an environment variable rather than specified as a post or query param to the app.  Set the env var `VOLUME_TEST_FILE` to point at the file that should be used for testing.

## Quick/High-level Usage

More detailed steps are [available below](#1-deploy-app-to-the-cluster-with-a-pvc):

1.  Create a PVC to claim a volume from your storage solution.
1.  Deploy this project's image with a Deployment, Service, and Route:  `quay.io/freedomben/volume-tester:latest`
1.  Get the route for the image, and replace `<app-route>` below with it:  `oc get route`
1.  Test basic reading/writing:  `curl http://<app-route>/readwrite`
1.  Write the test string to a file:  `curl http://<app-route>/write`
1.  Delete the Pod (the Deployment will recreate it and attach the PVC which should contain the persisted file)
1.  Read the file and verify the contents persisted:  `curl http://<app-route>/read`


## To test your PVC

### 1. Create a PVC and Deploy this Image to the cluster

Setting up your storage backend and StorageClass is outside the scope of this tool.  Please see the vendor documentation for your solution of choice.  You should either have dynamic provisioning set up, or statically create the PVs required to satisfy the PVC claims.

#### A. Create the PVC

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

#### B. Create the Deployment, Service, and Route:

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
1.  Delete and recreate the Pod (so that the volume gets detached and reattached by your storage solution).  Don't delete the PVC otherwise your storage backend may delete the corresponding volume, throwing away the persistence we are testing.
1.  Read the file and verify contents persisted:  `curl http://<app-route>/read`
1.  You can clear the test file contents for repeated testing:  `curl http://<app-route>/clear`

## Endpoints (RPC-style):

* `/readwrite`:  Writes and then reads a string to the file.  This can determine if there are any permission issues in place.
* `/write`:  Writes a static test string to the file which can be checked with `/read`
* `/read`:  Checks that the test file has the static test string as it's contents
* `/clear`:  Writes an empty string to the test file
