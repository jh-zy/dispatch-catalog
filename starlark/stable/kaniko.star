# vi:syntax=python

load("/starlark/stable/pipeline", "image_resource", "git_checkout_dir")

__doc__ = """
# Kaniko

Provides methods for building Docker containers using Kaniko.

To import, add the following to your Dispatchfile:

```
load("github.com/mesosphere/dispatch-catalog/starlark/stable/kaniko@0.0.5", "kaniko")
```

"""

def kaniko(task_name, git_name, image_repo, tag="$(context.build.name)", context=".", dockerfile="Dockerfile", build_args={}, inputs=[], outputs=[], steps=[], **kwargs):
    """
    Build a Docker image using Kaniko.
    """

    image_name = image_resource(
        "image-{}".format(task_name),
        url="{}:{}".format(image_repo, tag)
    )

    inputs = inputs + [git_name]
    outputs = outputs + [image_name]

    args = [
        "--destination=$(resources.inputs.{}.url)".format(image_name),
        "--context={}".format(context),
        "--oci-layout-path=$(resources.outputs.{}.path)".format(image_name),
        "--dockerfile={}".format(dockerfile)
    ]

    for k, v in build_args.items():
        args.append("--build-arg={}={}".format(k, v))

    steps = steps + [
        k8s.corev1.Container(
            name="build",
            image="gcr.io/kaniko-project/executor:latest",
            args=args,
            workingDir=git_checkout_dir(git_name)
        )
    ]

    return image_name
