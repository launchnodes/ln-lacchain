#!/bin/bash
. .env

cmd="kubectl exec -it pod/besu-node-writer-0"
url="http://localhost:4545"

function getPodRestart() {
    kubectl delete -n $NAME_SPACE pod/besu-node-writer-0
    sleep 5
    kubectl get pods -n $NAME_SPACE
}


function getEnodeId() {
    $cmd -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"net_enode","params":[],"id":1}' $url
}

function getNodeAddress() {
 
    $cmd -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"eth_coinbase","params":[],"id":1}' $url

}

function getConnectionStatus() {
    $cmd -n $NAME_SPACE  -c writer-nginx -- curl -X POST --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' $url

}

function getbesuLogs() {
    echo ""
    echo " #####   Press Ctrl+c  to exit   ##### "
    echo ""

    kubectl logs  -n $NAME_SPACE  pod/besu-node-writer-0 -c writer-besu --tail 10 -f 

}


echo -e "You can run any of these commands:  \n getPodRestart \n getEnodeId \n getNodeAddress \n getConnectionStatus \n getbesuLogs"
