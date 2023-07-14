
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


function CreateBesuNode() {
  source .env
  kubectl apply -f $deploy_net
  echo "It may take 2 to 3 mins for the Pods Availability,  sleeping for 150 sec"
  while [ "$(kubectl get pods -n $NAME_SPACE -l=app='besu-node-writer' -o jsonpath='{.items[*].status.containerStatuses[0].started}')" != "true" ]; do    sleep 10;  echo "Waiting for pod to be ready."; done
  echo -e "Get Pods Status...\n"
  kubectl get pods -n $NAME_SPACE
  sleep 20;
  echo -e "Your Enode Address...\n"
  kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"net_enode","params":[],"id":1}' http://localhost:4545
  echo ""
  sleep 1;
  echo -e "Your Wallet Address...\n"
  kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":53}' http://127.0.0.1:4545
}

function k8sAccess() {
  . .env
  aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
}

function registerNetwork() {
    
    ENODE=$(kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"net_enode","params":[],"id":1}' http://localhost:4545 | grep enode)

    sleep 1;

    ADDRESS=$(kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":53}' http://127.0.0.1:4545 | grep result)

    #create file info

    kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-besu -- touch /data/besu/permission.txt

    kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-besu -- sh -c  "echo $ENODE>>/data/besu/permission.txt"

    kubectl exec -it pod/besu-node-writer-0 -n $NAME_SPACE  -c writer-besu -- sh -c  "echo $ADDRESS>>/data/besu/permission.txt"
    
    arrIN=(${ADDRESS//'"result" :'/ }) 
    declare -g ADDRESS2=${arrIN[0]}
    arrIN=(${ENODE//'"result" :'/ }) 
    declare -g ENODE2=${arrIN[0]}
    

    echo ""
    echo -e "Share the ENODE address to LACChain Network team via email 'tech.support@lacnet.com'
    \n You have to restart the services after Access granted by LACChain Team"
    echo ""
}


function selectNetwork() {
    if [ "$1" == "mainnet" ]; then
      deploy_net=$mainnet
      echo $deploy_net
      downLoad
      k8sAccess
      replaceVal
      CreateBesuNode
      registerNetwork
      echo "Registering Node..."
      echo "Contact our premeier launchnode support team for mainnet registration"
    elif [ "$1" == "testnet" ]; then
      deploy_net=$testnet
      echo $deploy_net
      downLoad
      k8sAccess
      replaceVal
      CreateBesuNode
      registerNetwork
      echo -e "Registering Node...\n"
      curl --location --request POST 'https://api.backoffice.lac-net.net/market' --header 'Content-Type: application/json' --data-raw '{ "market":"AWS", "network":"Open Protestnet", "membership":"Premium", "address":'$ADDRESS2', "enode":'$ENODE2'}' --insecure
    else

      echo -e "Invalid Network $deploy_net selected / Not a valid network provided \n
                \n #### Select only from 'mainnet' or 'testnet' ####"
    fi

}


set_global_variable
selectNetwork $1