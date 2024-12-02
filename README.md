# tf-aws-infra
A repository for implementing Infrasutructure as code with Terraform

To Run use the steps below

APPLY
```
terraform apply
```

FORMAT
```
terraform fmt
```

PLAN
```
terraform plan 
```


If you want to import certificate, use the following command

```
aws acm import-certificate --certificate file://demo_sampurna_xyz.ctr --certificate-chain file://demo_sampurna_xyz.ca-bundle --private-key file://private.key.base64
```
