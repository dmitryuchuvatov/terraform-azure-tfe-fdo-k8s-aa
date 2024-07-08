# tfe_fdo_aks_in_active_active_mode.py

from diagrams import Cluster, Diagram

from diagrams.onprem.client import Client
from diagrams.aws.network import Route53
from diagrams.azure.compute import KubernetesServices
from diagrams.azure.database import DatabaseForPostgresqlServers
from diagrams.azure.storage import BlobStorage
from diagrams.azure.database import CacheForRedis
from diagrams.azure.network import LoadBalancers

with Diagram("TFE FDO AKS in Active-Active mode", show=False, direction="TB"):
    
    Client = Client("Client")

    with Cluster("AWS"):
        DNS = Route53("DNS")

    with Cluster("Azure"):
        with Cluster("VNet"):
            with Cluster("Public Subnet"):
                LB = LoadBalancers("Load Balancer")
                AKS_Cluster = KubernetesServices("TFE cluster")
            
            with Cluster("Private Subnet 1"):
                PostgreSQL = DatabaseForPostgresqlServers("PostgreSQL")

            with Cluster("Private Subnet 2"):    
                Redis = CacheForRedis("Redis cache")

        BlobStorage = BlobStorage("Blob storage")


    Client >> DNS
    DNS >> LB
    LB >> AKS_Cluster
    AKS_Cluster >> PostgreSQL
    AKS_Cluster >> Redis
    AKS_Cluster >> BlobStorage