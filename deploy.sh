#!/bin/bash

#set -x
source .env

function downLoad() {
    echo "You have Uploaded the .env file with relevent information filled, If not Please do and re run this Script again"
    echo "Ctrl+C to kill script now and rerun it, Pausing for 30 Seconds.."
    sleep 30
    curl -LJO https://raw.githubusercontent.com/ravinayag/lacchain-eks/master/deploy.sh
    curl -LJO https://raw.githubusercontent.com/ravinayag/lacchain-eks/master/LN-lac-besu.yaml
    chmod +x deploy.sh
    sleep 3
    
}


function replaceVal() {
    tr -d '\r' < .env > .env-updated
    mv .env-updated .env
    . .env

    sed -i -e "s/NAME_SPACE/$NAME_SPACE/g" LN-lac-besu.yaml
    sed -i -e "s/STORAGE_SPACE/$STORAGE_SPACE/g" LN-lac-besu.yaml
    sed -i -e "s/PUBLIC_IP/$PUBLIC_IP/g" LN-lac-besu.yaml
    sed -i -e "s/NODE_NAME/$NODE_NAME/g" LN-lac-besu.yaml
    sed -i -e "s/EMAIL_ID/$EMAIL_ID/g" LN-lac-besu.yaml

    tr -d '\r' < LN-lac-besu.yaml > LN-lac-besu-updated.yaml
    mv LN-lac-besu-updated.yaml LN-lac-besu.yaml   
}

function k8sAccess() {
  . .env
  aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
}


function oidcProviderAccess() {
  sudo yum install openssl -y
  OIDC_url=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text)
  THUMBPRT=$(openssl s_client -showcerts -connect oidc.eks.$REGION.amazonaws.com:443  </dev/null 2>/dev/null | openssl x509 -outform PEM | openssl x509 -noout -fingerprint | awk -F'=' '{ print $2 }' | sed 's/://g')
  aws iam create-open-id-connect-provider --url $OIDC_url --thumbprint-list $THUMBPRT --client-id-list sts.amazonaws.com --region $REGION
  sleep 60
}

function CreateBesuNode() {

  kubectl apply -f LN-lac-besu.yaml
  echo "sleeping for 60 sec"
  sleep 60
  kubectl get pods -n $NAME_SPACE
  #kubectl logs -n $NAME_SPACE pod/besu-node-writer-0 -c writer-besu | grep "Node address"
  kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"net_enode","params":[],"id":1}' http://localhost:4545
  echo ""
  echo "Share the ENODE address to LACChain Network team via email 'tech.support@lacnet.com' \n
        You have to restart the services after Access granted by LACChain Team"
  echo ""
}

function PodRestart() {
    kubectl rollout restart -n $NAME_SPACE besu-node-writer


}

downLoad
replaceVal
k8sAccess
oidcProviderAccess
CreateBesuNode