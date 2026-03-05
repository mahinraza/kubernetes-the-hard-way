Subject Alternative Names (SANs) are a critical component of modern TLS certificates. They solve a fundamental limitation of the older Common Name (CN) field and are essential for how clients, like `kubectl` or a web browser, verify they are connecting to the correct, trusted server.

Let's break down where they are used and how they work.

### 🗺️ Where SANs Are Used

In a nutshell, SANs are used everywhere a client needs to securely verify the identity of a server. The core purpose is to list all the valid hostnames and IP addresses that a single certificate can secure .

- **Websites and Browsers**: This is the most familiar use case. When you visit `https://www.example.com`, the website presents its certificate. Your browser checks if `www.example.com` is listed in the certificate's SAN field. This is what allows a single certificate to secure `example.com`, `www.example.com`, `shop.example.com`, and even a completely different domain like `example.net` .

- **Kubernetes API Servers**: In your specific context, the Kubernetes API server presents a certificate to clients like `kubectl`, `kubelet`s, and other control plane components. These clients will connect to the API server using various names and IP addresses (e.g., `controlplane01`, `192.168.56.41`, a load balancer DNS name). All of these must be included as SANs in the API server's certificate. If a client connects to `192.168.56.41` but that IP isn't in the SAN list, the connection will fail due to a hostname mismatch error .

- **Email and Communication Servers**: Applications like Microsoft Exchange Server require certificates that can handle multiple service names, such as `mail.example.com`, `autodiscover.example.com`, and internal server names, all of which are managed through SANs .

- **Microservices and Internal Infrastructure**: In complex environments like those using microservices, services communicate with each other over TLS. A central service might need to be reached via `api.internal.service`, `service-name.namespace.svc.cluster.local`, or a specific IP. These internal names must be SANs in the service's certificate for mutual TLS (mTLS) to work correctly .

### ⚙️ How SANs Work: The Verification Process

The process of SAN verification is a fundamental part of the TLS handshake. Modern clients rely exclusively on the SAN field, ignoring the older Common Name (CN) field for identity checks .

![](/images/san.png)

1.  **Initiating the Connection**: A client (browser, `kubectl`, another server) attempts to connect to a server using a specific hostname or IP address (e.g., `https://api.mycluster.local` or `192.168.56.41`) .
2.  **Presenting the Certificate**: As part of the TLS handshake, the server sends its X.509 digital certificate to the client. This certificate contains the SAN extension .
3.  **Extracting the SAN List**: The client reads the certificate and looks specifically at the `subjectAltName` field. This field contains a list of approved identities, such as `DNS:api.mycluster.local`, `DNS:kubernetes`, `IP:192.168.56.41`, and `IP:10.96.0.1` .
4.  **Performing the Match**: The client then compares the hostname or IP address it used to connect against every entry in the SAN list. This check ensures that the server is presenting a certificate that is explicitly authorized for that specific address. The match can be exact (`www.example.com`) or, in some cases, a wildcard match (`*.example.com`) .
5.  **Accepting or Rejecting the Connection**:
    -   **Success**: If the client finds a match, the server's identity is verified, and the secure, encrypted connection proceeds without issue .
    -   **Failure**: If no match is found in the SAN list, the client aborts the connection and displays a security warning to the user, such as "Your connection is not private" or "NET::ERR_CERT_COMMON_NAME_INVALID" .

I hope this detailed explanation clarifies the role and function of SANs, especially within your Kubernetes project. The step you mentioned earlier—querying IPs from `/etc/hosts`—is the perfect way to gather all the addresses you need to include to ensure seamless, secure communication between all your cluster components.