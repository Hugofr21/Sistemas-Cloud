### Referências 
[Configuring Google Cloud CDN with Terraform](https://medium.com/cognite/configuring-google-cloud-cdn-with-terraform-ab65bb0456a9)

[CDN](https://cloud.google.com/cdn/docs/overview?hl=pt-br)

[Terraform CDN](https://cloud.google.com/cdn/docs/cdn-terraform-examples?hl=pt-BR)

[Load Balancing]()

[Ceph]()



### Docker Configuration
RUN chmod +x ./gradlew
docker build -t cdn .
docker run -p 8077:8077 cdn
