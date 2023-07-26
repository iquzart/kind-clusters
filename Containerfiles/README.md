Sure, here's the README.md file for the provided Containerfile.OrgCa:

# Corporate TLS Certificate Container Image

This Containerfile.OrgCa creates a Container image based on `kindest/node` Kubernetes Node image and adds a Corporate TLS Certificate to the system's CA certificates. This image is useful for scenarios where you need to include a custom CA certificate to fix image pull issues in Corporate Networks.

## Build Arguments

The Containerfile.OrgCa uses a build argument `K8S_VERSION` to specify the version of the `kindest/node` image. You can customize this version by passing a different value for the `K8S_VERSION` argument during the build process. For example:

```bash
docker build --build-arg K8S_VERSION=1.26.3 -t corporate_tls_image .
```

## How to Use the Image

1. **Place Your Corporate TLS Certificate**

   Before building the image, ensure you have the Corporate TLS Certificate file (`Org-CA-Cert.crt`) in the same directory as the Containerfile.OrgCa. Make sure the certificate is appropriately named and in the correct format.

2. **Build the Container Image**

   To build the Container image, use the `docker build` command with the `K8S_VERSION` argument:

   ```bash
   docker build --build-arg K8S_VERSION=1.26.3 -t corporate_tls_image .
   ```

   or 
   
   ```
   make build K8S_VERSION=1.26.3
   ```

3. **Run a Container**

   Once the image is built, you can run a container from it. In most Kubernetes environments, this image will be used as part of a Pod, and the certificate will be automatically added to the cluster's trusted CA certificates.

4. **Confirm the Corporate TLS Certificate**

   To verify that the Corporate TLS Certificate has been successfully added to the system's CA certificates inside the container, you can check the certificate's presence using the `update-ca-certificates` command. Note that this command is already executed during the image build process.

## Customization

If you have different versions of the Kubernetes `kindest/node` image and need to use a specific version, you can modify the `K8S_VERSION` build argument during the build step.

## License

This Containerfile.OrgCa is provided under the [MIT License](LICENSE). Feel free to modify and use it according to your needs.
