## Horizontal scaling of App-Galery:

<div style="text-align: center;">
  <img src="images/proof-1.png" style="width: 75%;">
  <img src="images/proof-2.png" style="width: 75%;">
  <img src="images/proof-3.png" style="width: 75%;">
  <img src="images/proof-4.png" style="width: 75%;">
  <img src="images/proof-5.png" style="width: 75%;">
  <img src="images/proof-6.png" style="width: 75%;">
  <img src="images/proof-7.png" style="width: 75%;">
  <img src="images/proof-8.png" style="width: 75%;">
  <img src="images/proof-9.png" style="width: 75%;">
</div>

```bash
Every 1.0s: oc get hpa my-app-hpa && echo "---" && oc get pods -l deployment=my-app                                                                                                                                                                                                     MacBook.local: Wed Mar 25 17:43:59 2026
                                                                                                                                                                                                                                                                                                                  in 0.387s (0)
NAME         REFERENCE           TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
my-app-hpa   Deployment/my-app   cpu: 69%/50%   1         5         4          8h
---
NAME                    READY   STATUS              RESTARTS   AGE
my-app-7955c4df-297sj   0/1     ContainerCreating   0          58s
my-app-7955c4df-7pflj   0/1     ContainerCreating   0          58s
my-app-7955c4df-kht8g   1/1     Running             0          58s
my-app-7955c4df-rgclg   1/1     Running             0          58s
```

## Final results of Locust stress test:

```bash
Type     Name                                                                          # reqs      # fails |    Avg     Min     Max    Med |   req/s  failures/s
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
GET      /                                                                                566     2(0.35%) |   2876       4   30007    650 |    0.94        0.00
GET      / [gallery default]                                                              550     0(0.00%) |   2677      10   25618    490 |    0.92        0.00
GET      / [id refresh]                                                                   544     0(0.00%) |    373       5    9383    150 |    0.91        0.00
GET      / [pre-view gallery]                                                             533     0(0.00%) |   1179       9   11720    230 |    0.89        0.00
GET      / [sort date desc]                                                               543     0(0.00%) |   1257       8   19635    220 |    0.91        0.00
GET      / [sort title asc]                                                               546     1(0.18%) |   1775       6   19229    270 |    0.91        0.00
POST     /delete/<id>/ [POST]                                                             531     0(0.00%) |   1716      15   13813    380 |    0.89        0.00
GET      /new-post/                                                                       540     0(0.00%) |   1364       7   19629    190 |    0.90        0.00
POST     /new-post/ [POST upload]                                                         540     0(0.00%) |    900      12   10703    500 |    0.90        0.00
GET      /users/login/                                                                    566     0(0.00%) |    556       6   19404    190 |    0.94        0.00
POST     /users/login/ [POST]                                                             553     2(0.36%) |  13208    1705   45500  11000 |    0.92        0.00
POST     /users/logout/ [POST final]                                                      526     0(0.00%) |   1822      14   15668    510 |    0.88        0.00
POST     /users/logout/ [POST]                                                            566     0(0.00%) |   1071       7   16610    600 |    0.94        0.00
GET      /users/register/                                                                 574     0(0.00%) |   1930       8   14518    490 |    0.96        0.00
POST     /users/register/ [POST]                                                          574    12(2.09%) |   3179      10   42316    470 |    0.96        0.02
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
         Aggregated                                                                      8252    17(0.21%) |   2403       4   45500    400 |   13.77        0.03

Response time percentiles (approximated)
Type     Name                                                                                  50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
GET      /                                                                                     660   2500   3800   4500   8600  10000  21000  26000  30000  30000  30000    566
GET      / [gallery default]                                                                   540   2400   3800   4900   8200  10000  19000  21000  26000  26000  26000    550
GET      / [id refresh]                                                                        150    210    310    400    610   1200   3200   6900   9400   9400   9400    544
GET      / [pre-view gallery]                                                                  230    770   1400   2000   3800   5600   7800   8600  12000  12000  12000    533
GET      / [sort date desc]                                                                    220    680   1700   2500   4000   5500   8600   9500  20000  20000  20000    543
GET      / [sort title asc]                                                                    270   1300   2700   3400   5600   7700  10000  13000  19000  19000  19000    546
POST     /delete/<id>/ [POST]                                                                  380   1400   2800   3500   5000   6600   9800  11000  14000  14000  14000    531
GET      /new-post/                                                                            190    720   2000   2600   4400   6200   8800  10000  20000  20000  20000    540
POST     /new-post/ [POST upload]                                                              500    870   1100   1300   1800   3400   5500   6500  11000  11000  11000    540
GET      /users/login/                                                                         190    290    350    410    760   1800   6000   9600  19000  19000  19000    566
POST     /users/login/ [POST]                                                                11000  13000  15000  17000  22000  28000  29000  36000  46000  46000  46000    553
POST     /users/logout/ [POST final]                                                           510   2000   3100   3500   5100   6500   9500  11000  16000  16000  16000    526
POST     /users/logout/ [POST]                                                                 600    990   1200   1300   1900   4200   7400   7900  17000  17000  17000    566
GET      /users/register/                                                                      500   2000   3100   3800   5700   7700   9100  10000  15000  15000  15000    574
POST     /users/register/ [POST]                                                               490    800    970   1000   6600  30000  36000  38000  42000  42000  42000    574
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                                                                            400   1100   2500   3500   7800  11000  19000  26000  37000  46000  46000   8252

Error report
# occurrences      Error
------------------|---------------------------------------------------------------------------------------------------------------------------------------------
12                 POST /users/register/ [POST]: Register failed: 504
2                  GET /: HTTPError('504 Server Error: Gateway Time-out for url: /')
2                  POST /users/login/ [POST]: Login failed: 504
1                  GET / [sort title asc]: RemoteDisconnected('Remote end closed connection without response')
------------------|---------------------------------------------------------------------------------------------------------------------------------------------

Copying results...
error: unable to upgrade connection: container not found ("locust")
Done! Results saved to ./locust-results/
Clean up
job.batch "locust-load-test" deleted from endre-cloud-based-distributed-systems-laboratory namespace
configmap "locust-config" deleted from endre-cloud-based-distributed-systems-laboratory namespace
```

```bash
[2026-03-30 12:54:15,332] locust-load-test-7nhht/INFO/locust.main: writing html report to file: /results/report.html
[2026-03-30 12:54:15,335] locust-load-test-7nhht/INFO/locust.main: Shutting down (exit code 1)
Type     Name                                                                          # reqs      # fails |    Avg     Min     Max    Med |   req/s  failures/s
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
GET      /                                                                               3316    78(2.35%) |   6296       4   30128   4900 |    1.84        0.04
GET      / [gallery default]                                                             3245   107(3.30%) |   6703       7   30541   5400 |    1.80        0.06
GET      / [id refresh]                                                                  3644     6(0.16%) |   3083       4   30084    900 |    2.02        0.00
GET      / [pre-view gallery]                                                            2950     8(0.27%) |   5494      13   30042   4400 |    1.64        0.00
GET      / [sort date desc]                                                              3226    34(1.05%) |   5222       4   30083   3200 |    1.79        0.02
GET      / [sort title asc]                                                              3234    47(1.45%) |   5439       5   30188   3600 |    1.80        0.03
POST     /delete/<id>/ [POST]                                                            2939     7(0.24%) |   6889      18   45834   6000 |    1.63        0.00
GET      /new-post/                                                                      3210    29(0.90%) |   5373      11   32750   3200 |    1.78        0.02
POST     /new-post/ [POST upload]                                                        3193    20(0.63%) |   4997      11   51820   2300 |    1.77        0.01
GET      /users/login/                                                                   3301    24(0.73%) |   1946       6   30165    630 |    1.83        0.01
POST     /users/login/ [POST]                                                            3253   140(4.30%) |  16290     153   58179  14000 |    1.81        0.08
POST     /users/logout/ [POST final]                                                     3143     5(0.16%) |   7711      11   45491   7000 |    1.75        0.00
POST     /users/logout/ [POST]                                                           3305   159(4.81%) |   5332       5   51055   2200 |    1.84        0.09
GET      /users/register/                                                                3335   166(4.98%) |   6945      10   30156   5400 |    1.85        0.09
POST     /users/register/ [POST]                                                         3331   218(6.54%) |   4442      10   59403   1300 |    1.85        0.12
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
         Aggregated                                                                     48625  1048(2.16%) |   6112       4   59403   3400 |   27.01        0.58

Response time percentiles (approximated)
Type     Name                                                                                  50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
GET      /                                                                                    4900   7400   8600   9500  15000  20000  30000  30000  30000  30000  30000   3316
GET      / [gallery default]                                                                  5400   7900   9000  10000  16000  21000  30000  30000  30000  31000  31000   3245
GET      / [id refresh]                                                                        900   2000   3500   5300   9300  14000  19000  22000  30000  30000  30000   3644
GET      / [pre-view gallery]                                                                 4400   6800   8100   8900  12000  16000  21000  25000  30000  30000  30000   2950
GET      / [sort date desc]                                                                   3200   6300   8000   8700  12000  16000  25000  30000  30000  30000  30000   3226
GET      / [sort title asc]                                                                   3600   6600   8300   9100  13000  17000  23000  30000  30000  30000  30000   3234
POST     /delete/<id>/ [POST]                                                                 6000   8400   9700  11000  15000  19000  25000  30000  45000  46000  46000   2939
GET      /new-post/                                                                           3200   6200   8100   9000  13000  19000  24000  30000  30000  33000  33000   3210
POST     /new-post/ [POST upload]                                                             2300   4400   7400   9200  13000  17000  25000  30000  36000  52000  52000   3193
GET      /users/login/                                                                         630   1300   2000   2500   5000   8800  13000  19000  30000  30000  30000   3301
POST     /users/login/ [POST]                                                                14000  18000  21000  23000  29000  31000  37000  40000  55000  58000  58000   3253
POST     /users/logout/ [POST final]                                                          7000   9100  10000  12000  17000  21000  27000  30000  43000  45000  45000   3143
POST     /users/logout/ [POST]                                                                2200   4700   8000   9500  14000  21000  30000  32000  44000  51000  51000   3305
GET      /users/register/                                                                     5400   7800   8900  10000  16000  30000  30000  30000  30000  30000  30000   3335
POST     /users/register/ [POST]                                                              1300   2000   3200   4900  12000  30000  30000  38000  51000  59000  59000   3331
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                                                                           3400   7100   8900  10000  15000  21000  30000  30000  44000  55000  59000  48625

Error report
# occurrences      Error
------------------|---------------------------------------------------------------------------------------------------------------------------------------------
142                POST /users/register/ [POST]: Register failed: 504
166                GET /users/register/: HTTPError('504 Server Error: Gateway Time-out for url: /users/register/')
77                 GET /: HTTPError('504 Server Error: Gateway Time-out for url: /')
74                 POST /users/register/ [POST]: Register failed: 403
135                POST /users/logout/ [POST]: HTTPError('403 Client Error: Forbidden for url: /users/logout/ [POST]')
22                 POST /users/logout/ [POST]: HTTPError('504 Server Error: Gateway Time-out for url: /users/logout/ [POST]')
2                  POST /users/logout/ [POST]: RemoteDisconnected('Remote end closed connection without response')
132                POST /users/login/ [POST]: Login failed: 504
20                 GET /users/login/: HTTPError('504 Server Error: Gateway Time-out for url: /users/login/')
34                 GET / [sort date desc]: HTTPError('504 Server Error: Gateway Time-out for url: / [sort date desc]')
107                GET / [gallery default]: HTTPError('504 Server Error: Gateway Time-out for url: / [gallery default]')
47                 GET / [sort title asc]: HTTPError('504 Server Error: Gateway Time-out for url: / [sort title asc]')
29                 GET /new-post/: HTTPError('504 Server Error: Gateway Time-out for url: /new-post/')
19                 POST /new-post/ [POST upload]: Upload failed: 504
1                  POST /users/register/ [POST]: Register failed: 500
4                  POST /users/login/ [POST]: Login failed: 403
6                  GET / [id refresh]: HTTPError('504 Server Error: Gateway Time-out for url: / [id refresh]')
8                  GET / [pre-view gallery]: HTTPError('504 Server Error: Gateway Time-out for url: / [pre-view gallery]')
7                  POST /delete/<id>/ [POST]: HTTPError('504 Server Error: Gateway Time-out for url: /delete/<id>/ [POST]')
4                  POST /users/logout/ [POST final]: HTTPError('504 Server Error: Gateway Time-out for url: /users/logout/ [POST final]')
1                  POST /users/register/ [POST]: Register failed: 0
1                  GET /: RemoteDisconnected('Remote end closed connection without response')
4                  POST /users/login/ [POST]: Login failed: 0
4                  GET /users/login/: RemoteDisconnected('Remote end closed connection without response')
1                  POST /new-post/ [POST upload]: Upload failed: 0
1                  POST /users/logout/ [POST final]: RemoteDisconnected('Remote end closed connection without response')
------------------|---------------------------------------------------------------------------------------------------------------------------------------------

Copying results...
error: unable to upgrade connection: container not found ("locust")
Done! Results saved to ./locust-results/
Clean up
job.batch "locust-load-test" deleted from endre-cloud-based-distributed-systems-laboratory namespace
configmap "locust-config" deleted from endre-cloud-based-distributed-systems-laboratory namespace
```