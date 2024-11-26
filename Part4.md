# Sommaire

- [POC - Partie 4](#poc---partie-4)
  - [Tp 5](#tp-5)
    - [Création du service EFS](#création-du-service-efs)
    - [Vpc](#vpc)
    - [Security Group](#security-group)
    - [Ec2](#ec2)

# POC - Partie 4

## Tp 5 

Le but du POC est de montré que l'on peut faire un service efs qui garde les datas, 
et que l'on peut les retrouver en faisant re pop un autre instance ec2 dans une autre zone d'availabilité.

### Création du service EFS

[efs.tf](./tp5/efs.tf)

### Vpc 

[vpc.tf](./tp5/vpc.tf)

### Security Group

[security_group.tf](./tp5/secu.tf)

### Ec2

[ec2.tf](./tp5/ec2.tf)

Dans le fichier ec2.tf il y a un valeur qu'on viendras modifié apres le premier lancement de terraform.
Cette valeur correspond a la ZA de l'instance ec2, donc pour voir si notre POC fonctionne on pourras la laissé a 0 au premier lancement.
Puis la mettre a 1/2 pour voir si notre POC fonctionne relancant terraform avec un terraform apply.
