## Horizontal scaling of App-Galery:

<div style="text-align: center;">
  <img src="images/proof-1.png" style="width: 75%;">
  <img src="images/proof-2.png" style="width: 75%;">
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
GET      /                                                                                220   66(30.00%) |   6978       9   30049    610 |    0.37        0.11
GET      / [gallery default]                                                              206   58(28.16%) |   5842      15   30053    230 |    0.34        0.10
GET      / [id refresh]                                                                   371   45(12.13%) |   5294       4   30051   1200 |    0.62        0.08
GET      / [pre-view gallery]                                                              81     5(6.17%) |   6555      20   30041    550 |    0.14        0.01
GET      / [sort date desc]                                                               198   35(17.68%) |   5256       9   30043    850 |    0.33        0.06
GET      / [sort title asc]                                                               205   63(30.73%) |   6115       8   30122    280 |    0.34        0.11
POST     /delete/<id>/ [POST]                                                              79     4(5.06%) |  11115      23   57320   2100 |    0.13        0.01
GET      /new-post/                                                                       196   26(13.27%) |   8083      14   52531   3100 |    0.33        0.04
POST     /new-post/ [POST upload]                                                         190   26(13.68%) |   7003      12   42184   1300 |    0.32        0.04
GET      /users/login/                                                                    219   58(26.48%) |   4013       7   30024    200 |    0.37        0.10
POST     /users/login/ [POST]                                                             206  112(54.37%) |  22059      17   59832  27000 |    0.34        0.19
POST     /users/logout/ [POST final]                                                      179   24(13.41%) |  12908      17   52463   5300 |    0.30        0.04
POST     /users/logout/ [POST]                                                            219   65(29.68%) |   8314       8   55107    590 |    0.37        0.11
GET      /users/register/                                                                 226    12(5.31%) |  10967      14   30126   5200 |    0.38        0.02
POST     /users/register/ [POST]                                                          222   76(34.23%) |  11234      14   53230   2600 |    0.37        0.13
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
         Aggregated                                                                      3017  675(22.37%) |   8567       4   59832   1300 |    5.03        1.13

Response time percentiles (approximated)
Type     Name                                                                                  50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
GET      /                                                                                     610   5200  13000  18000  25000  30000  30000  30000  30000  30000  30000    220
GET      / [gallery default]                                                                   230   2200   6000  13000  24000  29000  30000  30000  30000  30000  30000    206
GET      / [id refresh]                                                                       1200   1900   5000  11000  20000  30000  30000  30000  30000  30000  30000    371
GET      / [pre-view gallery]                                                                  550   2500  11000  19000  25000  30000  30000  30000  30000  30000  30000     81
GET      / [sort date desc]                                                                    850   2500   5500   7800  22000  26000  30000  30000  30000  30000  30000    198
GET      / [sort title asc]                                                                    280   3200   6400  13000  26000  30000  30000  30000  30000  30000  30000    205
POST     /delete/<id>/ [POST]                                                                 2100  16000  21000  22000  31000  42000  56000  57000  57000  57000  57000     79
GET      /new-post/                                                                           3100   7100  12000  17000  24000  30000  44000  50000  53000  53000  53000    196
POST     /new-post/ [POST upload]                                                             1300   4000  12000  18000  23000  30000  34000  36000  42000  42000  42000    190
GET      /users/login/                                                                         200    690   2100   5100  18000  27000  29000  29000  30000  30000  30000    219
POST     /users/login/ [POST]                                                                27000  30000  30000  30000  40000  53000  57000  58000  60000  60000  60000    206
POST     /users/logout/ [POST final]                                                          5300  16000  22000  30000  36000  42000  49000  52000  52000  52000  52000    179
POST     /users/logout/ [POST]                                                                 590   6000  13000  18000  30000  35000  50000  54000  55000  55000  55000    219
GET      /users/register/                                                                     5400  15000  21000  26000  29000  30000  30000  30000  30000  30000  30000    226
POST     /users/register/ [POST]                                                              2700  17000  26000  30000  30000  30000  30000  30000  53000  53000  53000    222
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                                                                           1300   6800  16000  21000  30000  30000  36000  49000  57000  60000  60000   3017

Error report
# occurrences      Error
------------------|---------------------------------------------------------------------------------------------------------------------------------------------
30                 POST /users/register/ [POST]: Register failed: 503
53                 GET /: HTTPError('503 Server Error: Service Unavailable for url: /')
55                 POST /users/logout/ [POST]: HTTPError('503 Server Error: Service Unavailable for url: /users/logout/ [POST]')
56                 GET /users/login/: HTTPError('503 Server Error: Service Unavailable for url: /users/login/')
58                 POST /users/login/ [POST]: Login failed: 503
49                 GET / [gallery default]: HTTPError('503 Server Error: Service Unavailable for url: / [gallery default]')
45                 POST /users/register/ [POST]: Register failed: 504
48                 GET / [sort title asc]: HTTPError('503 Server Error: Service Unavailable for url: / [sort title asc]')
31                 GET / [sort date desc]: HTTPError('503 Server Error: Service Unavailable for url: / [sort date desc]')
11                 GET /users/register/: HTTPError('504 Server Error: Gateway Time-out for url: /users/register/')
18                 GET /new-post/: HTTPError('503 Server Error: Service Unavailable for url: /new-post/')
21                 POST /new-post/ [POST upload]: Upload failed: 503
24                 GET / [id refresh]: HTTPError('503 Server Error: Service Unavailable for url: / [id refresh]')
4                  POST /users/logout/ [POST final]: HTTPError('503 Server Error: Service Unavailable for url: /users/logout/ [POST final]')
1                  GET /users/register/: HTTPError('503 Server Error: Service Unavailable for url: /users/register/')
1                  POST /users/logout/ [POST final]: HTTPError('403 Client Error: Forbidden for url: /users/logout/ [POST final]')
54                 POST /users/login/ [POST]: Login failed: 504
21                 GET / [id refresh]: HTTPError('504 Server Error: Gateway Time-out for url: / [id refresh]')
8                  GET /new-post/: HTTPError('504 Server Error: Gateway Time-out for url: /new-post/')
19                 POST /users/logout/ [POST final]: HTTPError('504 Server Error: Gateway Time-out for url: /users/logout/ [POST final]')
3                  POST /delete/<id>/ [POST]: HTTPError('504 Server Error: Gateway Time-out for url: /delete/<id>/ [POST]')
5                  POST /new-post/ [POST upload]: Upload failed: 504
15                 GET / [sort title asc]: HTTPError('504 Server Error: Gateway Time-out for url: / [sort title asc]')
13                 GET /: HTTPError('504 Server Error: Gateway Time-out for url: /')
1                  POST /users/register/ [POST]: Register failed: 500
9                  GET / [gallery default]: HTTPError('504 Server Error: Gateway Time-out for url: / [gallery default]')
3                  GET / [pre-view gallery]: HTTPError('504 Server Error: Gateway Time-out for url: / [pre-view gallery]')
10                 POST /users/logout/ [POST]: HTTPError('504 Server Error: Gateway Time-out for url: /users/logout/ [POST]')
4                  GET / [sort date desc]: HTTPError('504 Server Error: Gateway Time-out for url: / [sort date desc]')
2                  GET /users/login/: HTTPError('504 Server Error: Gateway Time-out for url: /users/login/')
1                  GET / [pre-view gallery]: HTTPError('503 Server Error: Service Unavailable for url: / [pre-view gallery]')
1                  POST /delete/<id>/ [POST]: HTTPError('503 Server Error: Service Unavailable for url: /delete/<id>/ [POST]')
1                  GET / [pre-view gallery]: RemoteDisconnected('Remote end closed connection without response')
------------------|---------------------------------------------------------------------------------------------------------------------------------------------

Copying results...
error: unable to upgrade connection: container not found ("locust")
Done! Results saved to ./locust-results/
```