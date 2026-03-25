# Load Test Report

## Tool: Locust

| Parameter | Value |
|---|---|
| Execution environment | BME Fured - OKD pod
| Number of users | 50 |
| Spawn rate | 5 users/s |
| Run time | 10 minutes |
| Target host | https://my-app-endre-cloud-based-distributed-systems-laboratory.apps.okd.fured.cloud.bme.hu |

## Configuration File

The full `locustfile.py` is available in the repository: [`locust/locustfile.py`](/../../locust/locustfile.py)

**Tested endpoints summary:**

| Order | Endpoint | Method | Description |
|---|---|---|---|
| 1 | `/users/register/` | POST | User registration |
| 2 | `/users/logout/` | POST | Logout (to set up login test) |
| 3 | `/users/login/` | POST | Login |
| 4 | `/` | GET | Browse gallery (default sort) |
| 5 | `/?sort_by=title&order=asc` | GET | Sort by title ascending |
| 6 | `/?sort_by=date&order=desc` | GET | Sort by date descending |
| 7 | `/new-post/` | POST | Upload image |
| 8 | `/<slug>` | GET | View image detail |
| 9 | `/delete/<id>/` | POST | Delete image |
| 10 | `/users/logout/` | POST | Logout |

---

## Test scenario:

1. Create user a randomized user account
2. Log in with the newly created user account
3. Upload a generated image for the website
4. Go through the available sorting options
    - Sort by alphabet
    - Sort by date
5. Go through the available endpoint
6. Delete the uploaded image
7. Logout

---

## Locust pod deployment in OKD

Locust was deployed as a one-off **Kubernetes Job** on the OKD cluster using a helper shell script. The script automates the full lifecycle of the load test: uploading the test file, running the job, collecting results, and cleaning up.

### Custom Locust Docker image

The base `locustio/locust` image does not include the `Pillow` library, which is required by the `locustfile.py` to generate random images for upload testing. A minimal custom image was created to add this dependency:
```dockerfile
FROM locustio/locust:latest

USER root
RUN pip install pillow
USER locust
```

The image is hosted on the GitHub Container Registry at `ghcr.io/endreglocker/locust-pillow:latest` and is automatically rebuilt and pushed on every push to `main` that modifies the `locust/Dockerfile`, via the following GitHub Actions workflow:

1. Checks out the repository
2. Logs in to `ghcr.io` using the built-in `GITHUB_TOKEN` (no manual secret setup required)
3. Builds the image from `locust/Dockerfile` and pushes it with the tag `ghcr.io/endreglocker/locust-pillow:latest`

### Script parameters

| Variable | Value |
|---|---|
| `APP_HOST` | Target application URL |
| `USERS` | 50 |
| `SPAWN_RATE` | 5 users/s |
| `RUN_TIME` | 10 minutes |
| `LOCUST_FILE` | `locust/locustfile.py` |
| `LOCUST_IMAGE` | `ghcr.io/endreglocker/locust-pillow:latest` |

### Steps performed by the script

1. **ConfigMap** — The `locustfile.py` is uploaded to the cluster as a ConfigMap (`locust-config`). This allows the test script to be injected into the pod at runtime as a mounted volume, without baking it into the Docker image. This way the image stays generic and reusable, while the test logic can be updated independently.

2. **Job cleanup** — Any previously existing `locust-load-test` Job is deleted before a new one is created, ensuring a clean run.

3. **Job creation** — A `batch/v1` Job is applied to the cluster. The pod runs the custom Locust image (`ghcr.io/endreglocker/locust-pillow:latest`) in **headless mode** with the following arguments:

   | Argument | Value |
   |---|---|
   | `-f` | `/mnt/locust/locustfile.py` (mounted from ConfigMap) |
   | `--host` | Target application URL |
   | `-u` | 50 users |
   | `-r` | 5 users/s spawn rate |
   | `--run-time` | 10 minutes |
   | `--csv` | `/results/locust` |
   | `--html` | `/results/report.html` |

4. **Log streaming** — The script waits for the pod to become ready, then streams its logs via `oc logs -f`.

5. **Result collection** — Once the run completes, results are copied from the pod to the local `./locust-results/` directory using `oc cp`.

6. **Cleanup** — The Job and ConfigMap are deleted from the cluster after the results are retrieved.

---

## Load Test Results

- The results and the proof of scalings are located in the [results.md](./results.md) file


## Lessons Learned

> For the first try I wanted to test the scaling in a short period of time; e.g.: 3 mins
> However this seemed an unreasanably short period of time, because the horizontal scaler needed time to set up new pods to balance the load; which resulted a high error rate in a short period of time
> For my second try I set the timer for a greater time-period, e.g: 10 mins; in this scenario the horizontal scaler had enough time to adapt to the load; which yielded better results