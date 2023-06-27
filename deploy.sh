
#!/bin/bash

file=".env" 
function set_global_variable() {
    declare -g mainnet="LAC-K8s-mainnet-1.0.yaml"
    declare -g testnet="LAC-K8s-pro-testnet-1.0.yaml"    
    if [[ -f $file  ]] 
    then 
        echo "You have Uploaded the .env file with relevent information filled, If not Please do and re run this Script again"
        echo "Ctrl+C to kill script now and rerun it, Pausing for 20 Seconds.."
        sleep 20
    else 
      echo "The '.env' file not available, Please update and upload to the CloudShell." 
    fi
    tr -d '\r' < .env > .env-updated
    mv .env-updated .env    
}



function downLoad() {
    curl -LJO https://raw.githubusercontent.com/launchnodes/ln-lacchain/master/deploy.sh
    curl -LJO https://raw.githubusercontent.com/launchnodes/ln-lacchain/master/ops.sh
    curl -LJO https://raw.githubusercontent.com/launchnodes/ln-lacchain/master/$deploy_net
    chmod +x deploy.sh ops.sh
    sleep 3

}

function replaceVal() {
    . .env
    sed -i -e "s/NAME_SPACE/$NAME_SPACE/g" $deploy_net
    sed -i -e "s/STORAGE_SPACE/$STORAGE_SPACE/g" $deploy_net
    sed -i -e "s/PUBLIC_IP/$PUBLIC_IP/g" $deploy_net
    sed -i -e "s/NODE_NAME/$NODE_NAME/g" $deploy_net
    sed -i -e "s/EMAIL_ID/$EMAIL_ID/g" $deploy_net

    tr -d '\r' < $deploy_net > $deploy_net-updated.yaml
    mv $deploy_net-updated.yaml $deploy_net
}


#This function deprecated due to AWS shell is not supporting.
# function oidcProviderAccess() {
#   sudo yum install openssl -y
#   OIDC_url=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text)
#   THUMBPRT=$(openssl s_client -showcerts -connect oidc.eks.$REGION.amazonaws.com:443  </dev/null 2>/dev/null | openssl x509 -outform PEM | openssl x509 -noout -fingerprint | awk -F'=' '{ print $2 }' | sed 's/://g')
#   echo $THUMBPRT
#   aws iam create-open-id-connect-provider --url $OIDC_url --thumbprint-list $THUMBPRT --client-id-list sts.amazonaws.com --region $REGION
#   sleep 60
# }

function CreateBesuNode() {
  source .env
  kubectl apply -f $deploy_net
  echo "sleeping for 60 sec"
  sleep 60
  kubectl get pods -n $NAME_SPACE
  kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"net_enode","params":[],"id":1}' http://localhost:4545
  echo ""
  echo -e "Share the ENODE address to LACChain Network team via email 'tech.support@lacnet.com' \n
        You have to restart the services after Access granted by LACChain Team"
  echo ""
}

function k8sAccess() {
  . .env
  aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
}


function selectNetwork() {
    if [ "$1" == "mainnet" ]; then
      deploy_net=$mainnet
      echo $deploy_net
      downLoad
      k8sAccess
      replaceVal
      CreateBesuNode
    elif [ "$1" == "testnet" ]; then
      deploy_net=$testnet
      echo $deploy_net
      downLoad
      k8sAccess
      replaceVal
      CreateBesuNode
    else
      echo -e "Invalid Network $deploy_net selected / Not a valid network provided \n 
                #### Select only from 'mainnet' or 'testnet' ####"
    fi

}

set_global_variable
selectNetwork $1