oc delete deployment my-app postgresql --ignore-not-found
oc delete service my-app postgresql --ignore-not-found
oc delete route my-app --ignore-not-found
oc delete buildconfig my-app --ignore-not-found
oc delete imagestream my-app --ignore-not-found
oc delete networkpolicy allow-all-ingress --ignore-not-found
oc delete pvc my-app-media postgresql-data --ignore-not-found
oc delete secret my-app-db --ignore-not-found
oc delete builds --all --ignore-not-found