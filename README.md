# volume-tester

Deploy into your OCP cluster, set the environment variable `VOLUME_TEST_FILE`, and curl the app.  It will try to write then read the file specified, and will tell you the results of the attempt.

## To test your PVC

### 1. Deploy app to the cluster with a PVC

Setting up your storage is outside the scope of this.  You should either have dynamic provisioning set up, or statically create the PVs required to satisfy the PVC claims.

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
