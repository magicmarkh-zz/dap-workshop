#delete lab3 and dap namespace
kubectl delete namespace lab3
kubectl delete namespace dap

#delete deployment in lab4
kubectl delete deployments --all -n lab4

#delete extra secrets in jenkins
#delete lab2 pipeline in jenkins