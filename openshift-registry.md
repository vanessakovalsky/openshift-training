# Utiliser le registre de conteneurs OpenShift

exercice original : https://www.katacoda.com/courses/openshift/subsystems/container-internals-lab-2-0-part-3

This lab is focused on understanding what container registries are for and how they work.

By the end of this lab you should be able to:

* Evaluate the quality of a container registry
* Evaluate the quality of a container repository
* Share your images using public and private registries
* Outline
* Understanding the basics of trust - quality & provenance
* Evaluating four different public registries
* Evaluating container repositories - trusted base images
* Sharing your container images

# Understanding the Basics of Trust - Quality & Provenance
The goal of this exercise is to understand the basics of trust when it comes to Registry Servers and Repositories. 
This requires quality and provenance - this is just a fancy way of saying that:

You must download a trusted thing
You must download from a trusted source
Each of these is necesary, but neither alone is sufficient. This has been true since the days of downloading ISO images for Linux distros. 
Whether evaluating open source libraries or code, prebuilt packages (RPMs or Debs), or Container Images, we must:

determine if we trust the image by evaluating the quality of the code, people, and organizations involved in the project. If it has enough history, 
investment, and actually works for us, we start to trust it.

determine if we trust the registry, by understanding the quality of its relationship with the trusted project - if we download something from 
the offical GitHub repo, we trust it more than from a fork by user Haxor5579. This is true with ISOs from mirror sites and with image repositories 
built by people who aren't affiliated with the underlying code or packages.

There are plenty of examples where people ignore one of the above and get hacked. In a previous lab, we learned how to break the URL down into 
registry server, namespace and repository.

## Trusted Thing
From a security perspective, it's much better to remotely inspect and determine if we trust an image before we download it, expand it, and 
cache it in the local storage of our container engine. Everytime we download an image, and expose it to the graph driver in the container engine, 
we expose ourselves to potential attack. First, let's do a remote inspect with Skopeo (can't do that with docker because of the client/server nature):

skopeo inspect docker://registry.fedoraproject.org/fedora

Examine the JSON. There's really nothing in there that helps us determine if we trust this repository. It "says" it was created by 
the Fedora project ("vendor": "Fedora Project") but we have no idea if that is true. We have to move on to verifying that we trust the source,
then we can determin if we trust the thing.

## Trusted Source
There's a lot of talk about image signing, but the reality is, most people are not verifying container images with signatures. 
What they are actually doing is relying on SSL to determine that they trust the source, then inferring that they trust the container image. 
Lets use this knowledge to do a quick evaluation of the official Fedora registry:

curl -I https://registry.fedoraproject.org

Notice that the SSL certificate fails to pass muster. That's because the DigiCert root CA certificate is not in /etc/pki on this CentOS lab box. 
On RHEL and Fedora this certficate is distributed by default and the SSL certificate for registry.fedoraproject.org passes muster. 
So, for this lab, you have to trust me, I tested it :-) If you were on a Fedora or Red Hat Enterprise Linux box with the right keys, 
the output would have looked like this:

HTTP/2 200 
date: Thu, 25 Apr 2019 17:50:25 GMT
server: Apache/2.4.39 (Fedora)
strict-transport-security: max-age=31536000; includeSubDomains; preload
x-frame-options: SAMEORIGIN
x-xss-protection: 1; mode=block
x-content-type-options: nosniff
referrer-policy: same-origin
last-modified: Thu, 25 Apr 2019 17:25:08 GMT
etag: "1d6ab-5875e1988dd3e"
accept-ranges: bytes
content-length: 120491
apptime: D=280
x-fedora-proxyserver: proxy10.phx2.fedoraproject.org
x-fedora-requestid: XMHzYeZ1J0RNEOvnRANX3QAAAAE
content-type: text/html

Even without the root CA certificate installed, we can discern that the certicate is valid and managed by Red Hat, which helps a bit:

curl 2>&1 -kvv https://registry.fedoraproject.org | grep subject

Think carefully about what we just did. Even visually validating the certificate gives us some minimal level of trust in this registry server. 
In a real world scenario, rememeber that it's the container engine's job to check these certificates. That means that Systems Administrators need 
to distribute the appropriate CA certificates in production. Now that we have inspected the certificate, we can safely pull the trusted repository 
(because we trust the Fedora project built it right) from the trusted registry server (because we know it is managed by Fedora/Red Hat):

podman pull registry.fedoraproject.org/fedora

Now, lets move on to evaluate some trickier repositories and registry servers...

# Evaluating Trust - Images and Registry Servers
The goal of this exercise is to learn how to evaluate Container Images and Registry Servers.

## Evaluating Images
First, lets start what we already know, there is often a full functioning Linux distro inside a container image. That's because it's useful 
to leverage existing packages and the dependency tree already created for it. This is true whether running on bare metal, in a virtual machine, 
or in a container image. It's also important to consider the quality, frequency, and ease of consuming updates in the container image.

To analyze the quality, we are going to leverage existing tools - which is another advantage of consuming a container images based on a Linux distro. 
To demonstrate, let's examine images from four different Linux distros - CentOS, Fedora, Ubuntu, and Red Hat Enterprise Linux. Each will provide 
differing levels of information:

## CentOS
podman run -it docker.io/centos:7.0.1406 yum updateinfo

CentOS does not provide Errata for package updates, so this command will not show any information. This makes it difficult to map CVEs to RPM packages. 
This, in turn, makes it difficult to update the packages which are affected by a CVE. Finally, this lack of information makes it difficult to score a 
container image for quality. A basic workaround is to just update everything, but even then, you are not 100% sure which CVEs you patched.

## Fedora
podman run -it registry.fedoraproject.org/fedora dnf updateinfo

Fedora provides decent meta data about package updates, but does not map them to CVEs either. Results will vary on any given day, but the output 
will often look something like this:

Last metadata expiration check: 0:00:07 ago on Mon Oct  8 16:22:46 2018.
Updates Information Summary: available
    5 Security notice(s)
        1 Moderate Security notice(s)
        2 Low Security notice(s)
    5 Bugfix notice(s)
    2 Enhancement notice(s)
## Ubuntu
podman run -it docker.io/ubuntu:trusty-20170330 /bin/bash -c "apt-get update && apt list --upgradable"

Ubuntu provides information at a similar quality to Fedora, but again does not map updates to CVEs easily. 
The results for this specific image should always be the same because we are purposefully pulling an old tag for demonstration purposes.

## Red Hat Enterprise Linux
podman run -it registry.access.redhat.com/ubi7/ubi:7.6-73 yum updateinfo security

Regretfully, we do not have the active Red Hat subscriptions necessary to analyze the Red Hat Universal Base Image (UBI) on the command line, 
but the output should look like the following if ran on RHEL or in OpenShift:

RHSA-2019:0679 Important/Sec. libssh2-1.4.3-12.el7_6.2.x86_64
RHSA-2019:0710 Important/Sec. python-2.7.5-77.el7_6.x86_64
RHSA-2019:0710 Important/Sec. python-libs-2.7.5-77.el7_6.x86_64
Notice the RHSA-: column - this indicates the Errata and it's level of importnace. This errata can be used to map the update to a particular CVE, 
giving you and your security team confidence that a container image is patched for any particular CVE. Even without a Red Hat subscription, 
we can analyze the quality of a Red Hat image by looking at the Red Hat Container Cataog and using the Contianer Health Index:

Click: Red Hat Enterprise Universal Base Image 7


## Evaluating Registries
Now, that we have taken a look at several container images, we are going to start to look at where they came from and how they were built - 
we are going to evaluate four registry servers - Fedora, podmanHub, Bitnami and the Red Hat Container Catalog:

## Fedora Registry
Click: registry.fedoraproject.org
The Fedora registry provides a very basic experience. You know that it is operated by the Fedora project, so the security should be pretty 
similar to the ISOs you download. That said, there are no older versions of images, and there is really no stated policy about how often the 
images are patched, updated, or released.

## podmanHub
Click: https://hub.podman.com/_/centos/
podmanHub provides "official" images for a lot of different pieces of software including things like CentOS, Ubuntu, Wordpress, and PHP. That said, there really isn't standard definition for what "official" means. Each repository appears to have their own processes, rules, time lines, lifecycles, and testing. There really is no shared understanding what official images provide an end user. Users must evaluate each repository for themselves and determine whether they trust that it's connected to the upstream project in any meaningful way.

## Bitnami
Click: https://bitnami.com/containers
Similar to podmanHub, there is not a lot of information linking these repostories to the upstream projects in any meaningful way. There is not even a clear understanding of what tags are available, or should be used. Again, not policy information and users are pretty much left to sift through GitHub repositories to have any understanding of how they are built of if there is any lifecycle guarantees about versions. You are pretty much left to just trusting that Bitnami builds containers the way you want them...

## Red Hat Container Catalog
Click: https://access.redhat.com/containers
The Red Hat Container catalog is setup in a completely different way than almost every other registry server. There is a tremendous amount of information about each respository. Poke around and notice how this particular image has a warning associated. For the point of this exercise, we are purposefully looking at an older image with known vulnerabilities. That's because container images age like cheese, not like wine. Trust is termporal and older container images age just like servers which are rarely or never patched.

Now take a look at the Container Health Index scoring for each tag that is available. Notice, that the newer the tag, the better the letter grade. The Red Hat Container Catalog and Container Health Index clearly show you that the newer images have a less vulnerabiliites and hence have a better letter grade. To fully understand the scoring criteria, check out Knowledge Base Article. This is a compeltely unique capability provided by the Red Hat Container Catalog because container image Errata are produced tying container images to CVEs.

## Summary
Knowing what you know now:

* How would you analyze these container repositories to determine if you trust them?
* How would you rate your trust in these registries?
* Is brand enough? Tooling? Lifecycle? Quality?
* How would you analyze repositories and registries to meet the needs of your company?
These questions seem easy, but their really not. It really makes you revisit what it means to "trust" a container registry and repository...

# Analyzing Storage and Graph Drivers
In this lab, we are going to focus on how Container Enginers cache Repositories on the container host. There is a little known or understood fact - 
whenever you pull a container image, each layer is cached locally, mapped into a shared filesystem - typically overlay2 or devicemapper. This has a 
few implications. First, this means that caching a container image locally has historically been a root operation. Second, if you pull an image, or 
commit a new layer with a password in it, anybody on the system can see it, even if you never push it to a registry server.

Let's start with a quick look at Docker and Podman, to show the difference in storage:

docker info 2>&1 | grep -E 'Storage | Root'

Notice what driver it's using and that it's storing container images in /var/lib/docker:

tree /var/lib/docker/

Now, let's take a look at a different container engine called podman. It pulls the same OCI compliant, docker compatible images, but uses a 
different drivers and storage on the system:

podman info | grep -A3 Graph

First, you might be asking yourself, what the heck is d_type?. Long story short, it's filesystem option that must be supported for overlay2 to 
work properly as a backing store for container images and running containers. Now, take a look at the actuall storage being used by Podman:

tree /var/lib/containers/storage

Now, pull an image and verify that the files are just mapped right into the filesystem:

podman pull registry.access.redhat.com/ubi7/ubi
cat $(find /var/lib/containers/storage | grep redhat-release | tail -n 1)

With both Docker and Podman, as well as most other container engines on the planet, image layers are mapped one for one to some kind of storage, 
be it thinp snapshots with devicemapper, or directories with overlay2.

This has implications on how you move container images from one registry to another. First, you have to pull it and cache it locally. 
Then you have to tag it with the URL, Namespace, Repository and Tag that you want in the new regsitry. Finally, you have to push it. 
This is a convoluted mess, and in a later lab, we will investigate a tool called Skopeo that makes this much easier.

For now, you understand enough about registry servers, repositories, and how images are cached locally. Let's move on.

