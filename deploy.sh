#!/bin/bash

#set -x
function downLoad() {
    curl -LJO https://raw.githubusercontent.com/ravinayag/lacchain-eks/master/.env
    curl -LJO https://raw.githubusercontent.com/ravinayag/lacchain-eks/master/deploy.sh
    curl -LJO https://raw.githubusercontent.com/ravinayag/lacchain-eks/master/LN-lac-besu.yaml
    chmod +x deploy.sh
    sleep 3
    
}


function replaceVal() {
    tr -d '\r' < .env > .env-updated
    cp .env-updated .env
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

function CreateBesuNode() {
  kubectl apply -f LN-lac-besu.yaml
}

function Storageadd() {
    . .env
    aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text
    text="https://oidc.eks.us-west-1.amazonaws.com/id/2AD02F9C9428E9681934A3A01C5F48C8"
    OIDC="${text##*/}"
    
    AWSID=$(aws sts get-caller-identity |  jq '.Account')
}

downLoad
replaceVal
k8sAccess
CreateBesuNode

# eksctl create iamserviceaccount \
#     --name ebs-csi-controller-sa \
#     --namespace kube-system \
#     --cluster my-cluster \
#     --role-name AmazonEKS_EBS_CSI_DriverRole \
#     --role-only \
#     --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
#     --approve
# eksctl create addon --name aws-ebs-csi-driver --cluster my-cluster --service-account-role-arn arn:aws:iam::111122223333:role/AmazonEKS_EBS_CSI_DriverRole --force
# #   sudo yum install gettext -y